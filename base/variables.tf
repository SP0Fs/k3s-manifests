variable "homeassistant_settings" {
  type = object({
    db_password = string
  })
}
variable "nextcloud_settings" {
  type = object({
    admin_password = string
    db_password    = string
  })
}

variable "postgres_settings" {
  type = object({
    admin_password = string
  })
}

variable "registry_settings" {
  type = object({
    username = string
    htpasswd = string
  })
}