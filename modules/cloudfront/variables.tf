variable "domain" {
  description = "Domain information"
  type = object({
    zone_id = string
    name = string
  })
}
