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

data "aws_iam_policy_document" "ec2_self_describe" {
  statement {
    actions = [
      "ec2:DescribeTags"
    ]
    resources = [
      "arn:aws:ec2:*"
    ]
    effect = "Allow"
  }
}

data "template_file" "ec2_assume_role" {
  template = "${file("templates/assume_role_policy.json")}"
  vars {
    aws_service = "ec2.amazonaws.com"
  }
}

resource "aws_iam_role" "self_tags" {
  name = "describe-tags-self"
  assume_role_policy = "${data.template_file.ec2_assume_role.rendered}"
}

resource "aws_iam_role_policy" "self_tags" {
  name = "describe-tags-self"
  role = "${aws_iam_role.self_tags.id}"
  policy = "${data.aws_iam_policy_document.ec2_self_describe.json}"
}

resource "aws_iam_instance_profile" "self_tags" {
  name = "describe-tags-self"
  roles = ["${aws_iam_role.self_tags.name}"]
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
output "describe_tags_self" { value ="${aws_iam_instance_profile.self_tags.id}" }
