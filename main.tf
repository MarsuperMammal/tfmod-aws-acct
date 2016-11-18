variable "cloud_trail_bucket" {}
variable "trailname" { default = "default" }

data "aws_iam_policy_document" "flowlog" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "*"
    ]
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "flowlog-assumerole" {
  statement {
    principals {
      type = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "flowlog" {
  name = "flowlog"
  assume_role_policy = "${data.aws_iam_policy_document.flowlog-assumerole.json}"
}

resource "aws_iam_role_policy" "flowlog" {
  name = "flowlog"
  role = "${aws_iam_role.flowlog.id}"
  policy = "${data.aws_iam_policy_document.flowlog.json}"
}

resource "aws_cloudtrail" "trail" {
  name = "${var.trailname}"
  s3_bucket_name = "${aws_s3_bucket.cloud_trail.id}"
  enable_logging = true
  include_global_service_events = true
}

resource "aws_s3_bucket" "cloud_trail" {
  bucket = "${var.cloud_trail_bucket}"
  acl = "log-delivery-write"
  policy = "${data.aws_iam_policy_document.cloudtrail.json}"
}

data "aws_iam_policy_document" "cloudtrail" {
  statement {
    principals {
      type = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      "arn:aws:s3:::${var.cloud_trail_bucket}"
    ]
  }
  statement {
    principals {
      type = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.cloud_trail_bucket}/*"
    ]
    condition {
      test = "StringEquals"
      variable = "s3:x-amz-acl"
      values = [
        "bucket-owner-full-control"
      ]
    }
  }
}

output "flowlogrole" { value = "${aws_iam_role.flowlog.arn}" }
