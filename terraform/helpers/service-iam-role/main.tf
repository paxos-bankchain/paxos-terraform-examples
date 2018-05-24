variable "resource_prefix" {}

variable "name" {
  description = "Unqualified service name."
}

# Needed because of https://github.com/hashicorp/terraform/issues/10857
variable "extra_policy_count" {
  default = 0
}

variable "extra_policy_arns" {
  description = "List of extra policies to attach."
  type        = "list"
  default     = []
}

# Permit EC2 instances and SSM to assume the service role.
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ec2.amazonaws.com", "ssm.amazonaws.com"]
      type        = "Service"
    }
  }
}

# Create the role.
resource "aws_iam_role" "role" {
  name               = "${var.resource_prefix}-service-${var.name}"
  assume_role_policy = "${data.aws_iam_policy_document.ec2_assume_role.json}"
}

# Allow the service to manage its own logs bucket.
data "aws_iam_policy_document" "cloudwatch_writer" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]

    resources = ["arn:aws:logs:*:*:${var.resource_prefix}-${var.name}"]
  }
}

resource "aws_iam_policy" "cloudwatch_writer" {
  name   = "${var.resource_prefix}-${var.name}-cloudwatch-writer"
  policy = "${data.aws_iam_policy_document.cloudwatch_writer.json}"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_writer" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "${aws_iam_policy.cloudwatch_writer.arn}"
}

resource "aws_iam_role_policy_attachment" "extra" {
  count      = "${var.extra_policy_count}"
  role       = "${aws_iam_role.role.name}"
  policy_arn = "${var.extra_policy_arns[count.index]}"
}
