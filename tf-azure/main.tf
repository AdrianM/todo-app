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

########################################################
### Postgres ############################################
########################################################
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# resource "azurerm_postgresql_flexible_server" "example" {
#   name                   = "example-psqlflexibleserver-${random_string.suffix.result}"
#   resource_group_name    = azurerm_resource_group.example.name
#   location               = azurerm_resource_group.example.location
#   version                = "12"
#   administrator_login    = "psqladmin"
#   administrator_password = "amo-1234567890" // TODO AMO Change to new password
#   storage_mb             = 32768
#   sku_name               = "GP_Standard_D4s_v3"

#   high_availability {
#     mode                      = "ZoneRedundant"
#     standby_availability_zone = 2
#   }
# }

# resource "azurerm_postgresql_flexible_server_database" "example" {
#   name      = "exampledb"
#   server_id = azurerm_postgresql_flexible_server.example.id
#   collation = "en_US.utf8"
#   charset   = "UTF8"

#   # prevent the possibility of accidental data loss
# #   lifecycle {
# #     prevent_destroy = true
# #   }
# }

########################################################
### Web App ############################################
########################################################
resource "azurerm_service_plan" "appserviceplan" {
  name                = "appserviceplan-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location           = azurerm_resource_group.example.location
  os_type            = "Linux"
  sku_name           = "B1"
}

resource "azurerm_linux_web_app" "webapp" {
  name                = "webapp-node-app-3-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location           = azurerm_resource_group.example.location
  service_plan_id    = azurerm_service_plan.appserviceplan.id

  site_config {
    application_stack {
      node_version = "16-lts"
    }

    app_command_line = "ls -l && node --version && npm -version && npm start"
    # app_command_line = "cd tf-azure/app && npm install && npm start"
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "~16"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "WEBSITE_HTTPLOGGING_RETENTION_DAYS" = "7"
    "WEBSITE_LOGGING_ENABLED" = "true"
  }
}

resource "azurerm_app_service_source_control" "sourcecontrol" {
  app_id             = azurerm_linux_web_app.webapp.id
  repo_url           = "https://github.com/AdrianM/todo-app-web.git"  # You'll need to update this
#   repo_url           = "https://github.com/Azure-Samples/nodejs-docs-hello-world"
  branch             = "main"
  use_manual_integration = true
  use_mercurial      = false
}
