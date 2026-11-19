variable "spoke_name" {
  type = string
}

variable "spoke_index" {
  type = number
}

variable "Owner_Email" {
  description = "Email address of the user who created the spoke."
  type        = string
  nullable    = false

  validation {
    condition     = length(var.Owner_Email) <= 256 && length(split("@", var.Owner_Email)[0]) <= 64 && can(regex("^[a-z0-9_+%-]+([.][a-z0-9_+%-]+)*@emeal[.]nttdata[.]com$", lower(var.Owner_Email)))
    error_message = "Owner_Email must be a valid email address at @emeal.nttdata.com."
  }
}

variable "keepAlive" {
  type    = string
}
