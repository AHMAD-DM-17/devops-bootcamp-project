resource "aws_iam_role" "ssm_instance_role" {
  name = "${local.prefix}-ssm-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "${local.prefix}-ssm-instance-profile"
  role = aws_iam_role.ssm_instance_role.name
}

# Core SSM permissions so instances show as "Managed Instances" and SSM Session Manager works.
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ssm_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ECR pull permissions so the web server can 'docker login' + 'docker pull' during Ansible deploy.
resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.ssm_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
