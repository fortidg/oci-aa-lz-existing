# oci-aa-drg

This Terraform deploys Active/Active FortiGate into an existing Oracle Landing Zone, containing 3 subnets.  Generally, these are named as (Management, Indoor and Outdoor).  This document assumes that all VCN and subnet routing is pre-configured, along with Internet Gateways, etc.  You will need to modify the defaults in variables.tf to match your existing address space.

You may run into an issue where cloudinit fails to load the full FortiGate Configuration.  Usually, this happens on the vNICs attached to the instance after initial bootup.  You will need to ssh to the FortiGate and issue the ```exec factoryreset``` command.  This will cause the cloudinit to run again.  When the device comes up, it should be functioning properly:


**Overview**

![overview](Images/lz-diagram.png)

**Policy Routes**
In order to circumvent the need for Virtual Domains, we are using policy routing to enable routing to the internet over two different intefaces (management and outdoor).  Those Routes can be seen below.  This enables North/South inspection, into and out of OCI

```sh
config router policy
    edit 1
        set input-device port2
        set src 0.0.0.0/0.0.0.0
        set dst 0.0.0.0/0.0.0.0
        set output-device port3
    next
    edit 2
        set input-device port3
        set src 0.0.0.0/0.0.0.0
        set dst 0.0.0.0/0.0.0.0
        set output-device port2
    next
end
```

In order to allow east/west processing on this device, we will need to other policies to match on inter VCN traffic and stop policy routing. The action of "deny" in a policy route stops policy routing, and causes the traffic in question to fall through to the default system route table.

```sh
config router policy
    edit 2
        set input-device port3
        set src <internal CIDR>
        set dst <internal CIDR>
        set action deny
    next
```
Because policy routes are utilized in the order which they are configured, it is important to place the policy routes in the correct order.  As such, you will place the "deny policy routing" policy above the default outbound policy from port3 to port2.    For Example:

```sh
config router policy
    edit 1
        set input-device "port2"
        set src "0.0.0.0/0.0.0.0"
        set dst "0.0.0.0/0.0.0.0"
        set gateway 192.168.1.1
        set output-device "port3"
    next
    edit 2
        set input-device "port3"
        set src "192.168.0.0/255.255.0.0"
        set dst "192.168.0.0/255.255.0.0"
        set action deny
    next
    edit 3
        set input-device "port3"
        set src "0.0.0.0/0.0.0.0"
        set dst "0.0.0.0/0.0.0.0"
        set gateway 192.168.0.1
        set output-device "port2"
    next
end
```