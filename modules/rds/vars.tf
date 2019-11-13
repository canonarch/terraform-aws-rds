variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
}

variable "allowed_inbound_cidr_blocks" {
  type = list(string)
}

variable "name" {
}

variable "engine" {
}

variable "engine_version" {
}

variable "instance_class" {
  description = "Note: encryption is not supported for some instances (cf https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.Encryption.html#Overview.Encryption.Availability)"
}

variable "storage_type" {
}

variable "allocated_storage" {
}

variable "iops" {
}

variable "multi_az" {
  description = "Provision a synchronous standby replica of the master DB in a different Availability Zone for failover cases. If a read replica exists (number_of_read_replicas > 0), it probably makes sense to also set read_replica_multi_az = true."
}

variable "master_username" {
}

variable "master_password" {
}

variable "publicly_accessible" {
}

variable "db_name" {
}

variable "port" {
}

variable "kms_cmk_arn" {
}

variable "backup_retention_period" {
}

variable "backup_window" {
}

variable "maintenance_window" {
}

variable "monitoring_interval" {
}

variable "deletion_protection" {
}

variable "number_of_read_replicas" {
  description = "Provision asynchronous read-only replicas for read scalability cases."
  default     = 0
}

variable "read_replica_multi_az" {
  description = "Provision standby replicas of the read replicas for failover cases."
  default     = false
}

variable "allowed_inbound_security_group_ids" {
  type        = list(string)
  default     = []
}

