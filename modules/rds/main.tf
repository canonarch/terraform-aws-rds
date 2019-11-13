terraform {
  required_version = ">= 0.12"
}

resource "aws_iam_role" "enhanced_monitoring" {
  name               = "rds-monitoring-role-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.enhanced_monitoring.json
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  role       = aws_iam_role.enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "enhanced_monitoring" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_db_subnet_group" "rds" {
  name        = var.name
  description = "DB Subnet Group ${var.name}"
  subnet_ids  = var.subnet_ids
}

resource "aws_db_instance" "primary" {
  identifier = var.name

  engine         = var.engine
  engine_version = var.engine_version

  instance_class = var.instance_class

  # Amazon RDS provides three storage types: General Purpose SSD (also known as gp2), Provisioned IOPS SSD (also known as io1), and magnetic
  # 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD).
  # default     = "standard"
  # prod => gp2
  storage_type      = var.storage_type
  allocated_storage = var.allocated_storage

  # storage_type of 'io1'. Set to 0 to disable.
  iops = var.iops

  multi_az = var.multi_az

  # master database user
  username = var.master_username
  password = var.master_password

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.publicly_accessible

  name = var.db_name
  port = var.port

  storage_encrypted = true
  kms_key_id        = var.kms_cmk_arn

  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  final_snapshot_identifier = "${var.name}-final-snapshot"

  maintenance_window         = var.maintenance_window
  auto_minor_version_upgrade = true

  # upgrade is not automatic even when this flag is set to true. It just means than it is permitted to manually upgrade the major version.
  allow_major_version_upgrade = true

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = aws_iam_role.enhanced_monitoring.arn

  # TODO uncomment this when using the supported Terraform version (>= 0.12 !?)  
  # performance_insights_enabled = true
  # performance_insights_kms_key_id = "${var.kms_cmk_arn}"
  # performance_insights_retention_period = 7

  deletion_protection = var.deletion_protection
}

resource "aws_db_instance" "read_replica" {
  count = var.number_of_read_replicas

  identifier          = "${var.name}-replica-${count.index}"
  replicate_source_db = aws_db_instance.primary.id

  instance_class = var.instance_class
  storage_type   = var.storage_type
  iops           = var.iops

  # if primary/source instance is multi-AZ, it probably makes sense to have the read replica also deployed in a multi-AZ configuration.
  multi_az = var.read_replica_multi_az

  publicly_accessible = var.publicly_accessible

  port = var.port

  # to avoid terraform to unencrypt RDS replica after 2nd pass https://github.com/terraform-providers/terraform-provider-aws/issues/3470 
  storage_encrypted = true

  # RDS does not support final snapshot for read replica (error happened when trying deleting the read replica)
  skip_final_snapshot = true

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = aws_iam_role.enhanced_monitoring.arn

  deletion_protection = var.deletion_protection
}

resource "aws_security_group" "rds" {
  name        = "rds-${var.name}"
  description = "Security Group for RDS DB instance ${var.name}"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_inbound_cidr_blocks" {
  security_group_id = aws_security_group.rds.id

  type      = "ingress"
  from_port = var.port
  to_port   = var.port
  protocol  = "tcp"

  cidr_blocks = var.allowed_inbound_cidr_blocks
}

resource "aws_security_group_rule" "allow_inbound_security_groups" {
  count = length(var.allowed_inbound_security_group_ids)

  security_group_id = aws_security_group.rds.id

  type      = "ingress"
  from_port = var.port
  to_port   = var.port
  protocol  = "tcp"

  source_security_group_id = element(var.allowed_inbound_security_group_ids, count.index)
}

