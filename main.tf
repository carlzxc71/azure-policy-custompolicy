terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.14.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.environment}-${var.location_short}-custompolicy"
  location = var.location
}

resource "azurerm_policy_definition" "this" {
  name         = "allowed_storage_replication_type"
  policy_type  = "Custom"
  display_name = "Allow only storage accounts of zone or geo redundant replication"
  description  = "This is a custom policy which will combine and allow both zone and geo redundant storage accounts"
  mode         = "Indexed"

  parameters = jsonencode({
    "effect" = {
      "type" = "String",
      "metadata" = {
        "displayName" = "Effect",
        "description" = "This parameter lets you choose the effect of the policy. If you choose Audit (default), the policy will only audit resources for compliance. If you choose Deny, the policy will deny the creation of non-compliant resources. If you choose Disabled, the policy will not enforce compliance (useful, for example, as a second assignment to ignore a subset of non-compliant resources in a single resource group)."
      },
      "allowedValues" = [
        "Audit",
        "Deny",
        "Disabled"
      ],
      "defaultValue" = "Audit"
    }
  })

  policy_rule = jsonencode({
    "if" = {
      "allOf" = [
        {
          "field"  = "type",
          "equals" = "Microsoft.Storage/storageAccounts"
        },
        {
          "not" = {
            "field" = "Microsoft.Storage/storageAccounts/sku.name",
            "in" = [
              "Standard_GRS",
              "Standard_RAGRS",
              "Standard_GZRS",
              "Standard_RAGZRS",
              "Standard_ZRS",
              "Premium_ZRS"
            ]
          }
        }
      ]
    },
    "then" = {
      "effect" = "[parameters('effect')]"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "this" {
  name                 = "allowed_storage_sku"
  display_name         = azurerm_policy_definition.this.display_name
  resource_group_id    = azurerm_resource_group.this.id
  policy_definition_id = azurerm_policy_definition.this.id
  description          = azurerm_policy_definition.this.description

  parameters = jsonencode({
    "effect" = {
      "value" = "Deny"
    }
  })
}

locals {
  storage_account_replication_type = [
    "LRS",
    "GRS",
    "ZRS"
  ]
}

resource "azurerm_storage_account" "this" {
  for_each = toset(local.storage_account_replication_type)

  name                     = lower("st${var.environment}${var.location_short}${each.key}")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = each.key
}


