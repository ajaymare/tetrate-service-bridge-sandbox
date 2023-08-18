
output "redis_password" {
  value     = random_password.redis.result
  sensitive = true
}

output "namespace" {
  value = var.namespace
}
