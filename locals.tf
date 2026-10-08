locals {
  address_space = cidrsubnet(
    "10.1.0.0/16",
    10,
    var.spoke_index
  )
}