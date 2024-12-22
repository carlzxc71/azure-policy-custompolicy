variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "environment" {
  type        = string
  description = "The environment for the deployed resources"
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be deployed"
  default     = "swedencentral"
}

variable "location_short" {
  type        = string
  description = "The location short of the deployed resources resources will be deployed"
  default     = "sc"
}
