# # Key vault to store github token
# data "azurerm_key_vault_secret" "github_token" {
#   name         = "github-token"
#   key_vault_id = azurerm_key_vault.kv.id
# }

# resource "azurerm_key_vault" "kv" {
#   name                = "github-token-kv"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   sku_name            = "standard"
#   tenant_id           = data.azurerm_client_config.current.tenant_id
# }

# resource "azurerm_key_vault_secret" "github_token" {
#   name         = "github-token"
#   value        = var.GH_TOKEN
#   key_vault_id = azurerm_key_vault.kv.id
# }

# logic app to send api request to github when low cpu usage



# Resources used to monitor cpu-usage and reduce number of vms
resource "azurerm_logic_app_workflow" "reduce_vm" {
  name                = "workflow_reduce_vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_logic_app_trigger_http_request" "reduce_vm" {
  name         = "http-trigger-reduce-vm"
  logic_app_id = azurerm_logic_app_workflow.reduce_vm.id

  schema = <<SCHEMA
 {
    "type": "object",
    "properties": {
        "schemaId": {
            "type": "string"
        },
        "data": {
            "type": "object",
            "properties": {
                "essentials": {
                    "type": "object",
                    "properties": {
                        "alertId": {
                            "type": "string"
                        },
                        "alertRule": {
                            "type": "string"
                        },
                        "severity": {
                            "type": "string"
                        },
                        "signalType": {
                            "type": "string"
                        },
                        "monitorCondition": {
                            "type": "string"
                        },
                        "monitoringService": {
                            "type": "string"
                        },
                        "alertTargetIDs": {
                            "type": "array",
                            "items": {
                                "type": "string"
                            }
                        },
                        "originAlertId": {
                            "type": "string"
                        },
                        "firedDateTime": {
                            "type": "string"
                        },
                        "resolvedDateTime": {
                            "type": "string"
                        },
                        "description": {
                            "type": "string"
                        },
                        "essentialsVersion": {
                            "type": "string"
                        },
                        "alertContextVersion": {
                            "type": "string"
                        }
                    }
                },
                "alertContext": {
                    "type": "object",
                    "properties": {}
                }
            }
        }
    }
}
SCHEMA
}

resource "azurerm_logic_app_action_http" "reduce_vm" {
  name         = "webhook"
  logic_app_id = azurerm_logic_app_workflow.reduce_vm.id
  method       = "POST"
  body = jsonencode({
    event_type = "reduce-n-vms"
  })
  headers = {
    "Content-Type" = "application/json"
    "Accept" : "application/vnd.github+json"
    "Authorization" : "Bearer ${var.GH_TOKEN}"
    "X-GitHub-Api-Version" : "2022-11-28"
  }
  uri = "https://api.github.com/repos/aruizcab/FinOps_AutoScaling/dispatches"
}

# Azure monitor metric alert to detect cpu usage limits
resource "azurerm_monitor_metric_alert" "low_cpu_alert" {
  name                = "vmss-low-cpu-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_orchestrated_virtual_machine_scale_set.vmss_terraform_tfm.id]
  description         = "Alert when VMSS CPU usage is below 10%"
  severity            = 2
  enabled             = true
  frequency           = "PT5M" # Evaluar cada 5 minutos
  window_size         = "PT5M" # Período de 5 minutos para calcular el promedio

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScalesets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 10
  }

  action {
    action_group_id = azurerm_monitor_action_group.reduce_vm.id
  }
}

resource "azurerm_monitor_action_group" "reduce_vm" {
  name                = "vmss-action-group"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "vmss-ag"

  logic_app_receiver {
    name                    = azurerm_logic_app_trigger_http_request.reduce_vm.name
    resource_id             = azurerm_logic_app_trigger_http_request.reduce_vm.id
    callback_url            = azurerm_logic_app_trigger_http_request.reduce_vm.callback_url
    use_common_alert_schema = true
  }
}





# Resources used to monitor cpu-usage and reduce number of vms
resource "azurerm_logic_app_workflow" "increase_vm" {
  name                = "workflow_increase_vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_logic_app_trigger_http_request" "increase_vm" {
  name         = "http-trigger-increase-vm"
  logic_app_id = azurerm_logic_app_workflow.increase_vm.id

  schema = <<SCHEMA
 {
    "type": "object",
    "properties": {
        "schemaId": {
            "type": "string"
        },
        "data": {
            "type": "object",
            "properties": {
                "essentials": {
                    "type": "object",
                    "properties": {
                        "alertId": {
                            "type": "string"
                        },
                        "alertRule": {
                            "type": "string"
                        },
                        "severity": {
                            "type": "string"
                        },
                        "signalType": {
                            "type": "string"
                        },
                        "monitorCondition": {
                            "type": "string"
                        },
                        "monitoringService": {
                            "type": "string"
                        },
                        "alertTargetIDs": {
                            "type": "array",
                            "items": {
                                "type": "string"
                            }
                        },
                        "originAlertId": {
                            "type": "string"
                        },
                        "firedDateTime": {
                            "type": "string"
                        },
                        "resolvedDateTime": {
                            "type": "string"
                        },
                        "description": {
                            "type": "string"
                        },
                        "essentialsVersion": {
                            "type": "string"
                        },
                        "alertContextVersion": {
                            "type": "string"
                        }
                    }
                },
                "alertContext": {
                    "type": "object",
                    "properties": {}
                }
            }
        }
    }
}
SCHEMA
}

resource "azurerm_logic_app_action_http" "increase_vm" {
  name         = "webhook"
  logic_app_id = azurerm_logic_app_workflow.increase_vm.id
  method       = "POST"
  body = jsonencode({
    event_type = "increase-n-vms"
  })
  headers = {
    "Content-Type" = "application/json"
    "Accept" : "application/vnd.github+json"
    "Authorization" : "Bearer ${var.GH_TOKEN}"
    "X-GitHub-Api-Version" : "2022-11-28"
  }
  uri = "https://api.github.com/repos/aruizcab/FinOps_AutoScaling/dispatches"
}

# Azure monitor metric alert to detect cpu usage limits
resource "azurerm_monitor_metric_alert" "high_cpu_alert" {
  name                = "vmss-high-cpu-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_orchestrated_virtual_machine_scale_set.vmss_terraform_tfm.id]
  description         = "Alert when VMSS CPU usage is above 90%"
  severity            = 2
  enabled             = true
  frequency           = "PT5M" # Evaluar cada 5 minutos
  window_size         = "PT5M" # Período de 5 minutos para calcular el promedio

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScalesets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.increase_vm.id
  }
}

resource "azurerm_monitor_action_group" "increase_vm" {
  name                = "vmss-action-group"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "vmss-ag"

  logic_app_receiver {
    name                    = azurerm_logic_app_trigger_http_request.increase_vm.name
    resource_id             = azurerm_logic_app_trigger_http_request.increase_vm.id
    callback_url            = azurerm_logic_app_trigger_http_request.increase_vm.callback_url
    use_common_alert_schema = true
  }
}
