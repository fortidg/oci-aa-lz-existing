##############################################################################################################
#
#
# FortiGate Active/Active Load Balanced pair of standalone FortiGate VMs for resilience and scale
# Terraform deployment template for Oracle Cloud
#
##############################################################################################################


# resource "oci_core_security_list" "untrusted_security_list" {
#   compartment_id = var.compartment_ocid
#   vcn_id         = oci_core_virtual_network.vcn.id
#   display_name   = "${var.PREFIX}-untrusted-security-list"

#   // allow outbound tcp traffic on all ports
#   egress_security_rules {
#     destination = "0.0.0.0/0"
#     protocol    = "all"
#   }

#   // allow inbound http (port 80) traffic
#   ingress_security_rules {
#     protocol = "6" // tcp
#     source   = "0.0.0.0/0"

#     tcp_options {
#       min = 80
#       max = 80
#     }
#   }

#   // allow inbound http (port 443) traffic
#   ingress_security_rules {
#     protocol = "6" // tcp
#     source   = "0.0.0.0/0"

#     tcp_options {
#       min = 443
#       max = 443
#     }
#   }

#   // allow inbound http (port 8443) traffic
#   ingress_security_rules {
#     protocol = "6" // tcp
#     source   = "0.0.0.0/0"

#     tcp_options {
#       min = 8443
#       max = 8443
#     }
#   }

#   // allow inbound ssh traffic
#   ingress_security_rules {
#     protocol  = "6" // tcp
#     source    = "0.0.0.0/0"
#     stateless = false

#     tcp_options {
#       min = 22
#       max = 22
#     }
#   }

#   ingress_security_rules {
#     protocol  = "6" // tcp
#     source    = "172.16.140.0/28"
#     stateless = false

#     tcp_options {
#       min = 8008
#       max = 8008
#     }
#   }

#   // allow inbound icmp traffic of a specific type
#   ingress_security_rules {
#     protocol = 11
#     source   = "0.0.0.0/0"
#   }
# }

##############################################################################################################
## TRUSTED NETWORK
##############################################################################################################


# // route table attachment
# resource "oci_core_route_table_attachment" "trust_route_table_attachment" {
#   subnet_id      = oci_core_subnet.trusted_subnet.id
#   route_table_id = oci_core_route_table.trusted_routetable.id
# }

# resource "oci_core_security_list" "trusted_security_list" {
#   compartment_id = var.compartment_ocid
#   vcn_id         = oci_core_virtual_network.vcn.id
#   display_name   = "fgt-internal-security-list"

#   // allow outbound tcp traffic on all ports
#   egress_security_rules {
#     destination = "0.0.0.0/0"
#     protocol    = "all"
#   }

#   // allow inbound all 
#   ingress_security_rules {
#     protocol = "all" // tcp
#     source   = "0.0.0.0/0"
#   }
# }

# resource "oci_core_route_table" "trusted_routetable" {
#   depends_on     = [oci_core_vnic_attachment.vnic_attach_trusted_fgt_a]
#   compartment_id = var.compartment_ocid
#   vcn_id         = oci_core_virtual_network.vcn.id
#   display_name   = "fgt-trusted-routetable"


#   //Route to NLB
#   route_rules {
#     description       = "Default Route to NLB"
#     destination       = "0.0.0.0/0"
#     destination_type  = "CIDR_BLOCK"
#     network_entity_id = data.oci_core_private_ips.nlb_trusted_private_ip.private_ips[0].id
#   }

#   //Route to Other VCNs This is commented out, but you will need to add this in order for this to work
#   route_rules {
#     description       = "Route to other spoke"
#     destination       = var.vcn_cidr_spoke1
#     destination_type  = "CIDR_BLOCK"
#     network_entity_id = oci_core_drg.drg.id
#   }
# }



##############################################################################################################
// VCN route table (add if not present already)
##############################################################################################################

# resource "oci_core_route_table" "vcn_routetable" {
#   depends_on     = [oci_core_vnic_attachment.vnic_attach_trusted_fgt_a]
#   compartment_id = var.compartment_ocid
#   vcn_id         = oci_core_virtual_network.vcn.id
#   display_name   = "fgt-vcn-routetable"


#   //Route to NLB
#   route_rules {
#     description       = "Default Route to FGT int"
#     destination       = "0.0.0.0/0"
#     destination_type  = "CIDR_BLOCK"
#     network_entity_id = data.oci_core_private_ips.nlb_trusted_private_ip.private_ips[0].id
#   }
# }



##############################################################################################################
## FortiGate A
##############################################################################################################
// trust nic attachment
resource "oci_core_vnic_attachment" "vnic_attach_trust_fgt_a" {
  instance_id  = oci_core_instance.vm_fgt_a.id
  display_name = "${var.PREFIX}-fgta-vnic-trusted"

  create_vnic_details {
    subnet_id              = var.trusted_subnet_id
    display_name           = "${var.PREFIX}-fgta-vnic-trusted"
    assign_public_ip       = false
    skip_source_dest_check = true
    private_ip             = var.fgt_ipaddress_a["3"]
  }
}

resource "oci_core_vnic_attachment" "vnic_attach_untrust_fgt_a" {
  instance_id  = oci_core_instance.vm_fgt_a.id
  display_name = "${var.PREFIX}-fgta-vnic-untrust"

  create_vnic_details {
    subnet_id              = var.untrusted_subnet_id
    display_name           = "${var.PREFIX}-fgta-vnic-untrust"
    assign_public_ip       = false
    skip_source_dest_check = true
    private_ip             = var.fgt_ipaddress_a["2"]
  }
}

// create oci instance for active
resource "oci_core_instance" "vm_fgt_a" {
  # depends_on = [oci_core_internet_gateway.igw]

  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "${var.PREFIX}-fgta"
  shape               = var.instance_shape
  shape_config {
    memory_in_gbs = "64"
    ocpus         = "4"
  }

  create_vnic_details {
    subnet_id        = var.management_subnet_id
    display_name     = "${var.PREFIX}-fgta-vnic-mgmt"
    assign_public_ip = true
    hostname_label   = "${var.PREFIX}-fgta-vnic-mgmt"
    private_ip       = var.fgt_ipaddress_a["1"]
  }

  launch_options {
    //    network_type = "PARAVIRTUALIZED"
    network_type = "VFIO"
  }

  source_details {
    source_type = "image"
    source_id   = local.mp_listing_resource_id // marketplace listing
    boot_volume_size_in_gbs = "50"
  }

  // Required for bootstrap
  // Commnet out the following if you use the feature.
  metadata = {
    user_data           = base64encode(data.template_file.custom_data_fgt_a.rendered)
  }

  timeouts {
    create = "60m"
  }
}

resource "oci_core_volume" "volume_fgt_a" {
  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "${var.PREFIX}-fgta-volume"
  size_in_gbs         = var.volume_size
}

// Use paravirtualized attachment for now.
resource "oci_core_volume_attachment" "volume_attach_fgt_a" {
  attachment_type = "paravirtualized"
  //attachment_type = "iscsi"   //  user needs to manually add the iscsi disk on fos after
  instance_id = oci_core_instance.vm_fgt_a.id
  volume_id   = oci_core_volume.volume_fgt_a.id
}

// Use for bootstrapping cloud-init
data "template_file" "custom_data_fgt_a" {
  template = file("${path.module}/customdata.tpl")

  vars = {
    fgt_vm_name          = "${var.PREFIX}-fgta"
    fgt_license_file     = "${var.fgt_byol_license_a == "" ? var.fgt_byol_license_a : (fileexists(var.fgt_byol_license_a) ? file(var.fgt_byol_license_a) : var.fgt_byol_license_a)}"
    fgt_license_flexvm   = var.fgt_byol_flexvm_license_a
    port1_ip             = var.fgt_ipaddress_a["1"]
    port1_mask           = var.subnetmask["1"]
    port2_ip             = var.fgt_ipaddress_a["2"]
    port2_mask           = var.subnetmask["2"]
    port3_ip             = var.fgt_ipaddress_a["3"]
    port3_mask           = var.subnetmask["3"]
    management_gateway_ip = data.oci_core_subnet.mgmt_gateway.virtual_router_ip    
    untrusted_gateway_ip = data.oci_core_subnet.untrust_gateway.virtual_router_ip
    trusted_gateway_ip   = data.oci_core_subnet.trust_gateway.virtual_router_ip
    vcn_cidr             = var.vcn
  }
}

##############################################################################################################
## FortiGate B
##############################################################################################################
resource "oci_core_instance" "vm_fgt_b" {
  # depends_on = [oci_core_internet_gateway.igw]

  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain2 - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "${var.PREFIX}-fgtb"
  shape               = var.instance_shape
  shape_config {
    memory_in_gbs = "64"
    ocpus         = "4"
  }

  create_vnic_details {
    subnet_id        = var.management_subnet_id
    display_name     = "${var.PREFIX}-fgtb-vnic-mgmt"
    assign_public_ip = true
    hostname_label   = "${var.PREFIX}-fgtb-vnic-mgmt"
    private_ip       = var.fgt_ipaddress_b["1"]
  }

  launch_options {
    network_type = "VFIO"
  }

  source_details {
    source_type = "image"
    source_id   = local.mp_listing_resource_id // marketplace listing
      boot_volume_size_in_gbs = "50"
  }

  // Required for bootstrap
  // Commnet out the following if you use the feature.
  metadata = {
    user_data           = "${base64encode(data.template_file.custom_data_fgt_b.rendered)}"
  }

  timeouts {
    create = "60m"
  }
}

// trusted nic attachment
resource "oci_core_vnic_attachment" "vnic_attach_trusted_fgt_b" {
  instance_id  = oci_core_instance.vm_fgt_b.id
  display_name = "${var.PREFIX}-fgtb-vnic-trusted"

  create_vnic_details {
    subnet_id              = var.trusted_subnet_id
    display_name           = "${var.PREFIX}-fgtb-vnic-trusted"
    assign_public_ip       = false
    skip_source_dest_check = true
    private_ip             = var.fgt_ipaddress_b["3"]
  }
}

// untrust nic attachment
resource "oci_core_vnic_attachment" "vnic_attach_untrust_fgt_b" {
  instance_id  = oci_core_instance.vm_fgt_b.id
  display_name = "${var.PREFIX}-fgtb-vnic-untrust"

  create_vnic_details {
    subnet_id              = var.untrusted_subnet_id
    display_name           = "${var.PREFIX}-fgtb-vnic-untrust"
    assign_public_ip       = false
    skip_source_dest_check = true
    private_ip             = var.fgt_ipaddress_b["2"]
  }
}

resource "oci_core_volume" "volume_fgt_b" {
  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain2 - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "${var.PREFIX}-fgtb-volume"
  size_in_gbs         = var.volume_size
}

resource "oci_core_volume_attachment" "volume_attach_fgt_b" {
  attachment_type = "paravirtualized"
  //attachment_type = "iscsi"   //  user needs to manually add the iscsi disk on fos after
  instance_id = oci_core_instance.vm_fgt_b.id
  volume_id   = oci_core_volume.volume_fgt_b.id
}

// Use for bootstrapping cloud-init
data "template_file" "custom_data_fgt_b" {
  template = file("${path.module}/customdata.tpl")

  vars = {
    fgt_vm_name          = "${var.PREFIX}-fgtb"
    fgt_license_file     = "${var.fgt_byol_license_b == "" ? var.fgt_byol_license_b : (fileexists(var.fgt_byol_license_b) ? file(var.fgt_byol_license_b) : var.fgt_byol_license_b)}"
    fgt_license_flexvm   = var.fgt_byol_flexvm_license_b
    port1_ip             = var.fgt_ipaddress_b["1"]
    port1_mask           = var.subnetmask["1"]
    port2_ip             = var.fgt_ipaddress_b["2"]
    port2_mask           = var.subnetmask["2"]
    port3_ip             = var.fgt_ipaddress_b["3"]
    port3_mask           = var.subnetmask["3"]
    management_gateway_ip = data.oci_core_subnet.mgmt_gateway.virtual_router_ip    
    untrusted_gateway_ip = data.oci_core_subnet.untrust_gateway.virtual_router_ip
    trusted_gateway_ip   = data.oci_core_subnet.trust_gateway.virtual_router_ip
    vcn_cidr             = var.vcn
  }
}

##############################################################################################################
## External Network Load Balancer
##############################################################################################################
resource "oci_network_load_balancer_network_load_balancer" "nlb_untrusted" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.PREFIX}-nlb-untrusted"
  subnet_id      = var.untrusted_subnet_id

  is_private                     = false
  is_preserve_source_destination = false
}

resource "oci_network_load_balancer_listener" "nlb_untrusted_listener" {
  default_backend_set_name = oci_network_load_balancer_backend_set.nlb_untrusted_backend_set.name
  name                     = "${var.PREFIX}-nlb-untrusted-listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_untrusted.id
  port                     = 0
  protocol                 = "ANY"
}

resource "oci_network_load_balancer_backend_set" "nlb_untrusted_backend_set" {
  health_checker {
    protocol = "TCP"
    port     = 8008
  }

  name                     = "${var.PREFIX}-untrusted-backend-set"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_untrusted.id
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
}

resource "oci_network_load_balancer_backend" "nlb_untrusted_backend_fgta" {
  backend_set_name         = oci_network_load_balancer_backend_set.nlb_untrusted_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_untrusted.id
  port                     = 0

  ip_address = var.fgt_ipaddress_a["2"]
}

resource "oci_network_load_balancer_backend" "nlb_untrusted_backend_fgtb" {
  backend_set_name         = oci_network_load_balancer_backend_set.nlb_untrusted_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_untrusted.id
  port                     = 0

  ip_address = var.fgt_ipaddress_b["2"]
}

##############################################################################################################
## Internal Network Load Balancer
##############################################################################################################
resource "oci_network_load_balancer_network_load_balancer" "nlb_trusted" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.PREFIX}-nlb-trusted"
  subnet_id      = var.trusted_subnet_id

  is_private                     = true
  is_preserve_source_destination = true
  is_symmetric_hash_enabled      = true
}

resource "oci_network_load_balancer_listener" "nlb_trusted_listener" {
  default_backend_set_name = oci_network_load_balancer_backend_set.nlb_trusted_backend_set.name
  name                     = "${var.PREFIX}-nlb-trusted-listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_trusted.id
  port                     = 0
  protocol                 = "ANY"
}

resource "oci_network_load_balancer_backend_set" "nlb_trusted_backend_set" {
  health_checker {
    protocol = "TCP"
    port     = 8008
  }

  name                     = "${var.PREFIX}-trusted-backend-set"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_trusted.id
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
}

resource "oci_network_load_balancer_backend" "nlb_trusted_backend_fgta" {
  backend_set_name         = oci_network_load_balancer_backend_set.nlb_trusted_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_trusted.id
  port                     = 0

  ip_address = var.fgt_ipaddress_a["3"]
}

resource "oci_network_load_balancer_backend" "nlb_trusted_backend_fgtb" {
  backend_set_name         = oci_network_load_balancer_backend_set.nlb_trusted_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_trusted.id
  port                     = 0

  ip_address = var.fgt_ipaddress_b["3"]
}

