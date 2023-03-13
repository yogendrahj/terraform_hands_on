data "aws_ecr_repository" "ecr-repository" {
  name = "ecr-repository"
}

resource "aws_ecs_cluster" "ecs-cluster" {
  name = "white-hart"
}

resource "aws_ecs_service" "ecs-service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.ecs-cluster.id
  task_definition = aws_ecs_task_definition.ecs-task-definition.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["${aws_subnet.ecs-prvt-sn-1.id}", "${aws_subnet.ecs-prvt-sn-2.id}"]
    assign_public_ip = false
  }
}

resource "aws_ecs_task_definition" "ecs-task-definition" {
  family = "ecs-task-definition"
  container_definitions = jsonencode([
    {
      name      = "ecs-task-definition"
      image     = "${data.aws_ecr_repository.ecr-repository.repository_url}"
      essential = true
      cpu       = 256
      memory    = 512
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    },
    {
      name      = "second"
      image     = "service-second"
      cpu       = 10
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 443
          hostPort      = 443
        }
      ]
    }
  ])
}

data "aws_iam_policy_document" "ecs-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs-assume-role-policy.json
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
