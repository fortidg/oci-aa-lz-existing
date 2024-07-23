Content-Type: multipart/mixed; boundary="==OCI=="
MIME-Version: 1.0

--==OCI==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config"



config system global
  set hostname ${fgt_vm_name}
end

config system probe-response
  set mode http-probe
end

config system interface
  edit port1
    set vdom root
    set alias management
    set mode static
    set ip ${port1_ip}/${port1_mask}
    set allowaccess https ssh http
    set type physical
    set mtu-override enable
    set mtu 9000
  next
end
config system interface
  edit port2
    set vdom root
    set alias untrusted
    set mode static
    set ip ${port2_ip}/${port2_mask}
    set allowaccess probe-response
    set type physical
    set mtu-override enable
    set mtu 9000
  next
end
config system interface
  edit port3
    set vdom root
    set alias trusted
    set mode static
    set ip ${port3_ip}/${port3_mask}
    set allowaccess ping probe-response
    set type physical
    set mtu-override enable
    set mtu 9000
  next
end

config router static
  edit 0
    set device port1
    set gateway ${management_gateway_ip}
  next
end
config router static
  edit 0
    set device port3
    set dst ${vcn_cidr}
    set gateway ${trusted_gateway_ip}
  next
end

config router policy
    edit 1
        set input-device port2
        set src 0.0.0.0/0.0.0.0
        set dst 0.0.0.0/0.0.0.0
        set output-device port3
        set gateway ${trusted_gateway_ip}
    next
    edit 2
        set input-device port3
        set src 0.0.0.0/0.0.0.0
        set dst 0.0.0.0/0.0.0.0
        set output-device port2
        set gateway ${untrusted_gateway_ip}
    next
end

%{ if fgt_license_flexvm != "" }
--==OCI==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="license"

LICENSE-TOKEN:${fgt_license_flexvm}

%{ endif }

%{ if fgt_license_file != "" }
--==OCI==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="license"

${fgt_license_file}

%{ endif }
--==OCI==--
