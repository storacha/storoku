
resource "aws_sqs_queue" "queue" {
  name = "${var.environment}-${var.app}-${var.name}${var.fifo ? ".fifo" : ""}"
  fifo_queue = var.fifo
  content_based_deduplication = var.fifo ? true : null
  visibility_timeout_seconds = !var.fifo ? 300 : null
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.queue_deadletter.arn
    maxReceiveCount     = 4
  })
  tags = {
    Name = "${var.environment}-${var.app}-${var.name}${var.fifo ? ".fifo" : ""}"
  }
}

resource "aws_sqs_queue" "queue_deadletter" {
  fifo_queue = var.fifo
  content_based_deduplication = var.fifo ? true : null
  name = "${var.environment}-${var.app}-${var.name}-deadletter${var.fifo ? ".fifo" : ""}"
}

resource "aws_sqs_queue_redrive_allow_policy" "caching" {
  queue_url = aws_sqs_queue.queue_deadletter.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.queue.arn]
  })
}