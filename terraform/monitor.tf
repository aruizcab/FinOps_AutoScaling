# logic app work to send api request to github
resource "azurerm_logic_app_workflow" "example" {
  name                = "workflow1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_logic_app_trigger_http_request" "example" {
  name         = "some-http-trigger"
  logic_app_id = azurerm_logic_app_workflow.example.id

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

resource "azurerm_logic_app_action_http" "example" {
  name         = "webhook"
  logic_app_id = azurerm_logic_app_workflow.example.id
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
resource "azurerm_monitor_metric_alert" "vmss_cpu_alert" {
  name                = "vmss-cpu-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_orchestrated_virtual_machine_scale_set.vmss_terraform_tfm.id]
  description         = "Alert when VMSS CPU usage exceeds 80%"
  severity            = 2
  enabled             = true
  frequency           = "PT1M" # Evaluar cada 5 minutos
  window_size         = "PT5M" # Período de 1 minutos para calcular el promedio

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScalesets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 20
  }

  action {
    action_group_id = azurerm_monitor_action_group.vmss_action_group.id
  }
}

resource "azurerm_monitor_action_group" "vmss_action_group" {
  name                = "vmss-action-group"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "vmss-ag"

  # webhook_receiver {
  #   name        = "github-webhook"
  #   service_uri = "https://api.github.com/repos/aruizcab/FinOps_AutoScaling/dispatches?access_token=${var.GH_TOKEN}"
  #   # Configura los encabezados y la carga útil según tus necesidades
  # }

  logic_app_receiver {
    name                    = azurerm_logic_app_trigger_http_request.example.name
    resource_id             = azurerm_logic_app_trigger_http_request.example.id
    callback_url            = azurerm_logic_app_trigger_http_request.example.callback_url
    use_common_alert_schema = true
  }
}