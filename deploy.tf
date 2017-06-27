#
# Backend
#

terraform { backend "s3" { } }

#
# Configuration
#

variable "aws_account_id" { default = "012581555088" }
variable "aws_region" { type = "string" }
variable "cloudwatch_log_retention" { default = 7 }
variable "lambda_runtime" { default = "nodejs6.10" }
variable "lambda_memory" { default = {
    low = "128"
    medium = "256"
    high = "512"
}}
variable "lambda_timeout" { default = {
    low = "30"
    medium = "60"
    high = "120"
}}

#
# CloudWatch Logs
#

resource "aws_cloudwatch_log_group" "deals_in_stage" {
    name = "/aws/lambda/deals_in_stage"
    retention_in_days = "${var.cloudwatch_log_retention}"
}

resource "aws_cloudwatch_log_group" "total_in_deals" {
    name = "/aws/lambda/total_in_deals"
    retention_in_days = "${var.cloudwatch_log_retention}"
}

resource "aws_cloudwatch_log_group" "alexa_router" {
    name = "/aws/lambda/alexa_router"
    retention_in_days = "${var.cloudwatch_log_retention}"
}

#
# Roles
#

resource "aws_iam_role" "ken_bot" {
    name = "ken_bot"
    assume_role_policy = "${data.aws_iam_policy_document.ken_bot_lambda_assume_role_policy.json}"
}

data "aws_iam_policy_document" "ken_bot_lambda_assume_role_policy" {
    statement {
        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_policy_attachment" "ken_bot_attachment" {
    name = "ken_bot_attachment"
    roles = [
        "${aws_iam_role.ken_bot.id}"
    ]
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#
# Lambda
#

resource "aws_lambda_function" "deals_in_stage" {
    filename = "./ken_bot.zip"
    function_name = "deals_in_stage"
    role = "${aws_iam_role.ken_bot.arn}"
    handler = "deals_in_stage.handler"
    source_code_hash = "${base64sha256(file("./ken_bot.zip"))}"
    runtime = "${var.lambda_runtime}"
    memory_size = "${var.lambda_memory["low"]}"
    timeout = "${var.lambda_timeout["low"]}"
}

resource "aws_lambda_function" "total_in_deals" {
    filename = "./ken_bot.zip"
    function_name = "total_in_deals"
    role = "${aws_iam_role.ken_bot.arn}"
    handler = "total_in_deals.handler"
    source_code_hash = "${base64sha256(file("./ken_bot.zip"))}"
    runtime = "${var.lambda_runtime}"
    memory_size = "${var.lambda_memory["low"]}"
    timeout = "${var.lambda_timeout["low"]}"
}

resource "aws_lambda_function" "alexa_router" {
    filename = "./ken_bot.zip"
    function_name = "alexa_router"
    role = "${aws_iam_role.ken_bot.arn}"
    handler = "alexa_router.handler"
    source_code_hash = "${base64sha256(file("./ken_bot.zip"))}"
    runtime = "${var.lambda_runtime}"
    memory_size = "${var.lambda_memory["low"]}"
    timeout = "${var.lambda_timeout["low"]}"
}

#
# Permissions
#

# Deals In Stage

resource "aws_lambda_permission" "deals_in_stage_lex" {
    statement_id = "lex-${var.aws_region}-${aws_lambda_function.deals_in_stage.function_name}"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.deals_in_stage.function_name}"
    principal = "lex.amazonaws.com"
    source_arn = "arn:aws:lex:us-east-1:${var.aws_account_id}:intent:${aws_lambda_function.deals_in_stage.function_name}:*"
}

# Total In Deals

resource "aws_lambda_permission" "total_in_deals_lex" {
    statement_id = "lex-${var.aws_region}-${aws_lambda_function.total_in_deals.function_name}"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.total_in_deals.function_name}"
    principal = "lex.amazonaws.com"
    source_arn = "arn:aws:lex:us-east-1:${var.aws_account_id}:intent:${aws_lambda_function.total_in_deals.function_name}:*"
}

# Alexa

resource "aws_lambda_permission" "alexa_router" {
    statement_id = "alexa_router"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.alexa_router.function_name}"
    principal = "alexa-appkit.amazon.com"
}
