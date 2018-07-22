resource "aws_cloudwatch_log_group" "default" {
  name = "${data.template_file.instance_name.rendered}"

  tags {
    Workspace = "${terraform.workspace}"
  }
}

resource "aws_cloudwatch_log_metric_filter" "nginx_requests" {
  name           = "${aws_cloudwatch_log_group.default.name}-nginx-requests"
  pattern        = "[host != 127.0.0.1, logName, user, timestamp, request, statusCode, size]"
  log_group_name = "${aws_cloudwatch_log_group.default.name}"

  metric_transformation {
    name      = "${aws_cloudwatch_log_group.default.name}-nginx-request-count"
    namespace = "Caronae"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "nginx_requests_4xx" {
  name           = "${aws_cloudwatch_log_group.default.name}-nginx-requests-4xx"
  pattern        = "[host != 127.0.0.1, logName, user, timestamp, request, statusCode=4*, size]"
  log_group_name = "${aws_cloudwatch_log_group.default.name}"

  metric_transformation {
    name      = "${aws_cloudwatch_log_group.default.name}-nginx-request-4xx-count"
    namespace = "Caronae"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "nginx_requests_5xx" {
  name           = "${aws_cloudwatch_log_group.default.name}-nginx-requests-5xx"
  pattern        = "[host != 127.0.0.1, logName, user, timestamp, request, statusCode=5*, size]"
  log_group_name = "${aws_cloudwatch_log_group.default.name}"

  metric_transformation {
    name      = "${aws_cloudwatch_log_group.default.name}-nginx-request-5xx-count"
    namespace = "Caronae"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "${aws_cloudwatch_log_group.default.name}-error-logs"
  pattern        = "ERROR"
  log_group_name = "${aws_cloudwatch_log_group.default.name}"

  metric_transformation {
    name      = "${aws_cloudwatch_log_group.default.name}-error-count"
    namespace = "Caronae"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "warnings" {
  name           = "${aws_cloudwatch_log_group.default.name}-warning-logs"
  pattern        = "WARNING"
  log_group_name = "${aws_cloudwatch_log_group.default.name}"

  metric_transformation {
    name      = "${aws_cloudwatch_log_group.default.name}-warning-count"
    namespace = "Caronae"
    value     = "1"
  }
}

data "template_file" "dashboard" {
  template = "${file("compute/instance/dashboard.json.tpl")}"

  vars {
    instance_id = "${aws_instance.caronae.id}"
    region      = "${var.region}"
    log_group   = "${aws_cloudwatch_log_group.default.name}"
  }
}

resource "aws_cloudwatch_dashboard" "default" {
  dashboard_name = "${data.template_file.instance_name.rendered}"
  dashboard_body = "${data.template_file.dashboard.rendered}"
}
