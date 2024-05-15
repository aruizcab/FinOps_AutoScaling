# Key vault to store github token
data "azurerm_key_vault_secret" "github_token" {
  name         = "github-token"
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault" "kv" {
  name                = "github-token-kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_key_vault_secret" "github_token" {
  name         = "github-token"
  value        = var.GH_TOKEN
  key_vault_id = azurerm_key_vault.kv.id
}

# logic app work to send api request to github
resource "azurerm_logic_app_workflow" "example" {
  name                = "workflow1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
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
    "Authorization" : "Bearer ${data.azurerm_key_vault_secret.github_token.value}"
    "X-GitHub-Api-Version" : "2022-11-28"
  }
  uri = "https://api.github.com/repos/aruizcab/FinOps_AutoScaling/dispatches"
}

data "azapi_resource_action" "callback_url_data" {
  type                   = "Microsoft.Web/sites/hostruntime/webhooks/api/workflows/triggers@2022-03-01"
  action                 = "listCallbackUrl"
  resource_id            = azurerm_logic_app_workflow.example.id
  response_export_values = ["*"]
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
    operator         = "LowerThan"
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
    name                    = azurerm_logic_app_workflow.example.name
    resource_id             = azurerm_logic_app_workflow.example.id
    callback_url            = jsondecode(data.azapi_resource_action.callback_url_data.output).value
    use_common_alert_schema = true
  }
}

# resource "azurerm_logic_app_action_http_request" "github_api_call" {
#   name         = "github-api-call"
#   logic_app_id = azurerm_logic_app_workflow.logic_app.id
#   method       = "POST"
#   uri          = "https://api.github.com/repos/YOUR_REPO/dispatches"
#   body         = jsonencode({
#     event_type = "cpu-high-event"
#     client_payload = {
#       message = "CPU high alert triggered"
#     }
#   })
#   headers = {
#     "Content-Type" = "application/json"
#     "Authorization" = "Bearer ${data.azurerm_key_vault_secret.github_token.value}"
#   }
# }

