output "primary_endpoint" {
  value = aws_db_instance.primary.endpoint
}

output "read_replica_endpoints" {
  value = aws_db_instance.read_replica.*.endpoint
}

