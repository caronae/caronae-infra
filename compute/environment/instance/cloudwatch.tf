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

resource "aws_cloudwatch_log_metric_filter" "nginx_response_time" {
  name           = "${aws_cloudwatch_log_group.default.name}-nginx-response-time"
  pattern        = "[host != 127.0.0.1, logName, user, timestamp, request, statusCode, size, a, userAgent, responseTime, responseTimeUpstream]"
  log_group_name = "${aws_cloudwatch_log_group.default.name}"

  metric_transformation {
    name      = "${aws_cloudwatch_log_group.default.name}-nginx-response-time"
    namespace = "Caronae"
    value     = "$responseTime"
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
  template = "${file("compute/environment/instance/dashboard.tpl.json")}"

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

data "aws_sns_topic" "error_alerts" {
  name = "caronae_prod_errors"
}

resource "aws_cloudwatch_metric_alarm" "error_alarm" {
  count               = "${var.environment == "prod" && terraform.workspace == "default" ? 1 : 0}"
  alarm_name          = "${aws_cloudwatch_log_group.default.name}-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${aws_cloudwatch_log_group.default.name}-error-count"
  namespace           = "Caronae"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_actions       = ["${data.aws_sns_topic.error_alerts.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  count               = "${terraform.workspace == "default" ? 1 : 0}"
  alarm_name          = "${aws_cloudwatch_log_group.default.name}-cpu-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_actions       = ["${data.aws_sns_topic.error_alerts.arn}"]

  dimensions {
    InstanceId        = "${aws_instance.caronae.id}"
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  count               = "${terraform.workspace == "default" ? 1 : 0}"
  alarm_name          = "${aws_cloudwatch_log_group.default.name}-memory-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_actions       = ["${data.aws_sns_topic.error_alerts.arn}"]

  dimensions {
    InstanceId        = "${aws_instance.caronae.id}"
  }
}
