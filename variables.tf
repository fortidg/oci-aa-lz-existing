##############################################################################################################
#
# DRGv2 Hub and Spoke traffic inspection
# FortiGate Active/Active Load Balanced pair of standalone FortiGate VMs for resilience and scale
# Terraform deployment template for Oracle Cloud
#
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "PREFIX" {
  description = "Added name to each deployed resource"
  default = ""
}

variable "region" {
  description = "Oracle Cloud region"
  default = "us-ashburn-1"
}

##############################################################################################################
# Oracle Cloud configuration
##############################################################################################################

variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "user_ocid" {
  default = ""
}
variable "private_key_path" {
  default = ""
}
variable "fingerprint" {
  default = ""
}




##############################################################################################################
# FortiGate instance type
##############################################################################################################
variable "instance_shape" {
  type    = string
  default = "VM.Standard3.Flex"
}

variable "mp_listing_id" {
  default = "ocid1.appcataloglisting.oc1..aaaaaaaam7ewzrjbltqiarxukuk72v2lqkdtpqtwxqpszqqvrm7likfnpt5q" //byol
}

variable "mp_listing_resource_id" {
  default = "ocid1.image.oc1..aaaaaaaatktefn4ur7muxvost7ijpr4w6bxk4vxdpj3fx5ousyuwmfmdsuhq"
}

// Version
variable "mp_listing_resource_version" {
  default = "7.2.8_(_X64_)"
}
// Cert use for SDN Connector setting
variable "cert" {
  type    = string
  default = "Fortinet_Factory"
}

##############################################################################################################
# FortiGate license type
##############################################################################################################

// license file location for fgt a
variable "fgt_byol_license_a" {
  // Change to your own path
  type    = string
  default = ""
}

// license file location for fgt b
variable "fgt_byol_license_b" {
  // Change to your own path
  type    = string
  default = ""
}

// Flex-VM license token for fgt a
variable "fgt_byol_flexvm_license_a" {
  // Change to your own path
  type    = string
  default = ""
}

// Flex-VM license token for fgt b
variable "fgt_byol_flexvm_license_b" {
  // Change to your own path
  type    = string
  default = ""
}

##############################################################################################################
# VCN and SUBNET ADDRESSESS (Default Values need to be changed to match your environment)
##############################################################################################################

variable "management_subnet_id" {
  type    = string
}

variable "outdoor_subnet_id" {
  type    = string
}

variable "indoor_subnet_id" {
  type    = string
}

variable "vcn" {
  default = "172.16.140.0/22"
}

variable "subnet" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.140.0/28"  # Management
    "2" = "172.16.140.32/28" # Untrusted
    "3" = "172.16.140.64/28" # Trusted
  }
}

variable "subnetmask" {
  type        = map(string)
  description = ""

  default = {
    "1" = "28" # Flexible Network Load Balancer
    "2" = "28" # Untrusted
    "3" = "28" # Trusted
  }
}

variable "gateway" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.140.1"  # Management
    "2" = "172.16.140.33" # Untrusted
    "3" = "172.16.140.65" # Trusted
  }
}

variable "fgt_ipaddress_a" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.140.12" #Management
    "2" = "172.16.140.45" # Untrusted
    "3" = "172.16.140.77" # Trusted
  }
}

variable "fgt_ipaddress_b" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.140.13" #Management
    "2" = "172.16.140.46" # Untrusted
    "3" = "172.16.140.78" # Trusted
  }
}

variable "trusted_nlb_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.140.69" # Trusted
  }
}


# Choose an Availability Domain (1,2,3)
variable "availability_domain" {
  type    = string
  default = "1"
}

variable "availability_domain2" {
  type    = string
  default = "2"
}

variable "volume_size" {
  type    = string
  default = "50" //GB; you can modify this, can't less than 50
}

# variable "drg_attachment_network_details_vcn_route_type" {
#   type = string
#   default = "VCN_CIDRS"
# }

