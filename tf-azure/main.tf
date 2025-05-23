# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "North Europe"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                   = "example-psqlflexibleserver-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  version                = "12"
  administrator_login    = "psqladmin"
  administrator_password = "amo-1234567890" // TODO AMO Change to new password
  storage_mb             = 32768
  sku_name               = "GP_Standard_D4s_v3"
}

resource "azurerm_postgresql_flexible_server_database" "example" {
  name      = "exampledb"
  server_id = azurerm_postgresql_flexible_server.example.id
  collation = "en_US.utf8"
  charset   = "UTF8"

  # prevent the possibility of accidental data loss
#   lifecycle {
#     prevent_destroy = true
#   }
}

resource "azurerm_service_plan" "example" {
  name                = "example-service-plan"
  resource_group_name = azurerm_resource_group.example.name
  location           = azurerm_resource_group.example.location
  os_type            = "Linux"
  sku_name           = "B1"
}

resource "azurerm_linux_web_app" "example" {
  name                = "example-node-app-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location           = azurerm_resource_group.example.location
  service_plan_id    = azurerm_service_plan.example.id

  site_config {
    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }
}

resource "azurerm_web_app_deployment_source_control" "example" {
  app_id             = azurerm_linux_web_app.example.id
  repo_url           = "https://github.com/yourusername/your-repo"  # You'll need to update this
  branch             = "main"
  use_manual_integration = true
  use_mercurial      = false
}
