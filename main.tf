locals {
  envs = { for tuple in regexall("(.*)=(.*)", file("./config/.decrypted/envs")) : tuple[0] => sensitive(tuple[1]) }
}

module "base" {
  source = "./base"

  homeassistant_settings = {
    db_password = local.envs["HOMEASSISTANT_DB_PASSWORD"]
  }

  nextcloud_settings = {
    admin_password = local.envs["NEXTCLOUD_ADMIN_PASSWORD"]
    db_password    = local.envs["NEXTCLOUD_DB_PASSWORD"]
  }

  postgres_settings = {
    admin_password = local.envs["POSTGRES_ADMIN_PASSWORD"]
  }
}