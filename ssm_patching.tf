resource "aws_iam_role" "ssm_maintenance_window_role" {
  name        = "portfolio-ssm-maintenance-window-role"
  description = "Allows SSM Maintenance Windows to run patch tasks on EC2 instances"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "portfolio-ssm-maintenance-window-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_maintenance_window_policy" {
  role       = aws_iam_role.ssm_maintenance_window_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}

resource "aws_ssm_patch_baseline" "portfolio_ubuntu" {
  name             = "portfolio-ubuntu-security-baseline"
  description      = "Security patches only for Ubuntu 24.04 (portfolio-web-server)"
  operating_system = "UBUNTU"

  approval_rule {
    approve_after_days = 7
    compliance_level   = "HIGH"

    patch_filter {
      key    = "PRIORITY"
      values = ["Required", "Important", "Standard"]
    }

    patch_filter {
      key    = "SECTION"
      values = ["Security"]
    }
  }

  tags = {
    Name = "portfolio-ubuntu-security-baseline"
  }
}

resource "aws_ssm_patch_group" "portfolio" {
  baseline_id = aws_ssm_patch_baseline.portfolio_ubuntu.id
  patch_group = "portfolio-production"
}

resource "aws_ssm_maintenance_window" "portfolio_patching" {
  name              = "portfolio-weekly-patching"
  description       = "Weekly security patching for portfolio-web-server"
  schedule          = "cron(0 3 ? * SUN *)"
  schedule_timezone = "UTC"
  duration          = 2
  cutoff            = 1
  enabled           = true

  tags = {
    Name = "portfolio-weekly-patching"
  }
}

resource "aws_ssm_maintenance_window_target" "portfolio_ec2" {
  window_id     = aws_ssm_maintenance_window.portfolio_patching.id
  name          = "portfolio-ec2-target"
  description   = "portfolio-web-server patching target"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:PatchGroup"
    values = ["portfolio-production"]
  }
}

resource "aws_ssm_maintenance_window_task" "portfolio_patch_task" {
  window_id        = aws_ssm_maintenance_window.portfolio_patching.id
  name             = "portfolio-run-patch-baseline"
  description      = "Install security patches on portfolio-web-server"
  task_type        = "RUN_COMMAND"
  task_arn         = "arn:aws:ssm:${var.aws_region}::document/AWS-RunPatchBaseline"
  priority         = 1
  service_role_arn = aws_iam_role.ssm_maintenance_window_role.arn
  max_concurrency  = "1"
  max_errors       = "1"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.portfolio_ec2.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      document_version = "$LATEST"
      timeout_seconds  = 600

      parameter {
        name   = "Operation"
        values = ["Install"]
      }

      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }

      output_s3_bucket     = "lopezberg-portfolio-deploy"
      output_s3_key_prefix = "ssm-logs/"
    }
  }
}