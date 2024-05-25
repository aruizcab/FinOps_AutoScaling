import json
import sys

def main():
    # Read config.json
    with open("./python/config.json", "r") as config_json:
        config = json.load(config_json)

    # Calculates new number of vms
    config["n_vms"] = obtain_new_config(config)

    # Generates new content of compute.tf
    compute_tf_content = generate_compute_file(config["n_vms"], config["sku"])

    # Saves changes in config.json
    with open("./python/config.json", "w") as config_json:
        json.dump(config, config_json)

    # Saves changes in compute.tf
    with open("./terraform/compute.tf", "w") as compute_tf:
        compute_tf.write(compute_tf_content)

def obtain_new_config(config):
    # Calculates new number of vms
    if (config["n_vms"] > config["n_vms_min"]) and (config["n_vms"] < config["n_vms_max"]):
        if (sys.argv[0] == "increment_vm"):
            n_vms_new = config["n_vms"] + 1
        elif (sys.argv[0] == "reduce_vm"):
            n_vms_new = config["n_vms"] - 1
        else:
            return config["n_vms"]
        return n_vms_new
    else:
        return config["n_vms"]
    
def generate_compute_file(n_vms_new, sku_new):
    # Generates new content of compute.tf
    compute_file_1 = '''
resource "azurerm_orchestrated_virtual_machine_scale_set" "vmss_terraform_tfm" {
  name                        = "vmss-terraform"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
'''
    compute_file_2 =f'''
  sku_name                    = {sku_new}
  instances                   = {n_vms_new}
'''
    compute_file_3 = '''
  platform_fault_domain_count = 1     # For zonal deployments, this must be set to 1
  zones                       = ["1"] # Zones required to lookup zone in the startup script

  user_data_base64 = base64encode(file("user-data.sh"))
  os_profile {
    linux_configuration {
      disable_password_authentication = true
      admin_username                  = "azureuser"
      admin_ssh_key {
        username   = "azureuser"
        public_key = var.PUB_KEY
      }
    }
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-LTS-gen2"
    version   = "latest"
  }
  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                          = "nic"
    primary                       = true
    enable_accelerated_networking = false

    ip_configuration {
      name                                   = "ipconfig"
      primary                                = true
      subnet_id                              = azurerm_subnet.subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bepool.id]
    }
  }

  boot_diagnostics {
    storage_account_uri = ""
  }

  # Ignore changes to the instances property, so that the VMSS is not recreated when the number of instances is changed
  lifecycle {
    ignore_changes = [
      instances
    ]
  }
}
'''
    return compute_file_1 + compute_file_2 + compute_file_3

# Update compute.tf
if __name__=="__main__":
    main()