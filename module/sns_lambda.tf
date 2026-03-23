# ------------------------------------------------------------------------------
# SNS topic → Lambda (optional)
# Replace code under lambda/placeholder/ or set lambda_source_dir to your package.
# ------------------------------------------------------------------------------

data "archive_file" "sns_lambda_zip" {
  count = var.enable_sns_lambda ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/sns-lambda-${local.iam_name_suffix}.zip"
  source_dir  = coalesce(var.lambda_source_dir, "${path.module}/lambda/placeholder")
}

resource "aws_iam_role" "sns_lambda" {
  count = var.enable_sns_lambda ? 1 : 0

  name        = "${local.iam_name_prefix}-SnsLambda"
  description = "Execution role for SNS-triggered Lambda (DevOps Agent module)"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "sns_lambda_basic" {
  count = var.enable_sns_lambda ? 1 : 0

  role       = aws_iam_role.sns_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "sns_handler" {
  count = var.enable_sns_lambda ? 1 : 0

  function_name = "${local.iam_name_prefix}-sns-handler"
  description   = "Invoked by SNS (placeholder handler — replace via lambda_source_dir)"
  role          = aws_iam_role.sns_lambda[0].arn
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout

  filename         = data.archive_file.sns_lambda_zip[0].output_path
  source_code_hash = data.archive_file.sns_lambda_zip[0].output_base64sha256

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.sns_lambda_basic]
}

resource "aws_sns_topic" "notifications" {
  count = var.enable_sns_lambda ? 1 : 0

  name         = "${local.iam_name_prefix}-notifications"
  display_name = coalesce(var.sns_topic_display_name, var.agent_space_name)

  tags = var.tags
}

resource "aws_lambda_permission" "sns_invoke" {
  count = var.enable_sns_lambda ? 1 : 0

  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_handler[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.notifications[0].arn
}

resource "aws_sns_topic_subscription" "lambda" {
  count = var.enable_sns_lambda ? 1 : 0

  topic_arn = aws_sns_topic.notifications[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.sns_handler[0].arn

  depends_on = [aws_lambda_permission.sns_invoke]
}
