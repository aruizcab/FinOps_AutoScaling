resource "azurerm_monitor_metric_alert" "vmss_cpu_alert" {
  name                = "vmss-cpu-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_orchestrated_virtual_machine_scale_set.vmss_terraform_tfm.id]
  description         = "Alert when VMSS CPU usage exceeds 80%"
  severity            = 2
  enabled             = true
  frequency           = "PT2M" # Evaluar cada 5 minutos
  window_size         = "PT5M" # Período de 1 minutos para calcular el promedio

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScalesets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.vmss_action_group.id
  }
}

resource "azurerm_monitor_action_group" "vmss_action_group" {
  name                = "vmss-action-group"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "vmss-ag"

  webhook_receiver {
    name        = "github-webhook"
    service_uri = "https://api.github.com/repos/aruizcab/FinOps_AutoScaling/dispatches?access_token=${var.GH_TOKEN}"
    # Configura los encabezados y la carga útil según tus necesidades
  }
}