variable "domain" {
  description = "Domain information"
  type = object({
    zone_id = string
    name = string
  })
}
variable "origin" {
  description = "Location to direct traffic to origin"
  type = string
}
