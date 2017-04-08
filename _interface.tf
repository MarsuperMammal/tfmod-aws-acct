variable "cloud_trail_bucket" {}
variable "trailname" { default = "default" }

output "flowlogrole" { value = "${aws_iam_role.flowlog.arn}" }
output "describe_tags_self" { value ="${aws_iam_instance_profile.self_tags.id}" }
output "self_tags_role" { value = "${aws_iam_instance_profile.self_tags.name}" }