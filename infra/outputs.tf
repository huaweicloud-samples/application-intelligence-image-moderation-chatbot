output "api_gateway_url" {
  description = "API Gateway URL for Slack webhook"
  value       = "https://${huaweicloud_apig_instance.main.ingress_address}/"
}

output "api_id" {
  description = "APIG API ID"
  value       = huaweicloud_apig_api.image_moderator_api.id
}
