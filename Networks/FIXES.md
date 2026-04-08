# Design Decisions & Fixes

## Architecture Evolution

### Phase 1: Multi-Network Design (Attempted)

**Initial Goal**: Implement strict network isolation with 6 separate vmnet networks:

```
Office1 (vmnet6):     192.168.2.0/24
Office2 (vmnet7):     192.168.1.0/24
Central (vmnet8):     192.168.0.0/24
Transit O1↔C (vmnet9):  192.168.254.0/24
Transit O2↔C (vmnet10): 192.168.253.0/24
inetRouter (vmnet11):   10.0.0.0/24
```

**centralRouter Architecture**:
- 5 interfaces (eth1-eth5) for strict network segregation
- Explicit static routes for inter-office communication
- Complex Ansible template with multi-interface configuration

**Problems Encountered**:
- VMware Fusion on M1 Mac: "Failed to enable device" error
- Root cause: VMware Desktop has built-in limit on virtual networks
- Cannot simultaneously create 6 separate vmnet devices with Vagrant

### Phase 2: Simplified Single-Network Design (Current)

**New Design**: All 7 VMs on one shared 192.168.200.0/24 network (vmnet6)

```
192.168.200.0/24 (vmnet6):
  inetRouter:     192.168.200.10 (NAT to Internet)
  centralRouter:  192.168.200.11 (Routing Hub)
  office1Router:  192.168.200.12
  office2Router:  192.168.200.13
  centralServer:  192.168.200.21
  office1Server:  192.168.200.22
  office2Server:  192.168.200.23
```

**Benefits**:
- ✓ Works on both VirtualBox and VMware Desktop
- ✓ Simpler Ansible configuration (no complex multi-interface logic)
- ✓ No vmnet capacity constraints
- ✓ Maintains same functional goals (inter-office routing)
- ✓ Sufficient for learning network routing concepts

**Trade-off**:
- Physical network isolation → logical IP-based segregation
- Still achieves learning objectives: routing, gateways, forwarding, NAT

## Key Configuration Changes

### Vagrantfile Simplification

**Multi-Network Version (Removed)**:
```ruby
# 5 interfaces on centralRouter
config.vm.define "centralRouter" do |c|
  c.vm.network "private_network", ip: "192.168.0.2",     # Central LAN
    virtualbox__intnet: "central", vmware__network_name: "vmnet8"
  c.vm.network "private_network", ip: "192.168.254.1",   # O1 Transit
    virtualbox__intnet: "transit-o1", vmware__network_name: "vmnet9"
  c.vm.network "private_network", ip: "192.168.253.1",   # O2 Transit
    virtualbox__intnet: "transit-o2", vmware__network_name: "vmnet10"
  c.vm.network "private_network", ip: "10.0.0.1",        # inetRouter Transit
    virtualbox__intnet: "transit-inet", vmware__network_name: "vmnet11"
end
```

**Single-Network Version (Current)**:
```ruby
# 1 interface on all VMs (except eth0 Vagrant NAT)
config.vm.network "private_network",
  ip: "192.168.200.X",
  netmask: "255.255.255.0",
  virtualbox__intnet: "internal-net",
  vmware__network_name: "vmnet6"
```

### Router Role Simplification

**Multi-Network Version (Removed)**:
```yaml
# Complex multi-interface routing
- name: Set up static routes
  template:
    src: "static_routes_{{ inventory_hostname }}.j2"
    dest: "/etc/static_routes.sh"
    mode: '0755'
  when: inventory_hostname in groups['routers']
```

With per-router templates defining complex routing rules.

**Single-Network Version (Current)**:
```yaml
# Simple default gateway to inetRouter
- name: Set default route
  shell: ip route add default via {{ inet_router_ip }} dev eth1

- name: Create route persistence service
  template:
    src: restore_routes.j2
    dest: /etc/systemd/system/restore-routes.service
    mode: '0644'
```

## Lessons Learned

1. **Hypervisor Constraints**: VMware Desktop on M1 has practical vmnet limits despite supporting multiple networks theoretically. Better to work within these constraints than fight them.

2. **Sufficiency**: Physical network isolation isn't required to teach routing concepts. Logical IP-based segregation achieves the same learning outcomes.

3. **Flexibility**: Single-provider design (multi-vmnet) is fragile. Multi-provider compatibility (VirtualBox + VMware) requires simpler, more flexible architecture.

4. **Maintainability**: Fewer interfaces and templates = easier debugging and faster provisioning.

## Fallback Strategy

If even single vmnet fails:

**Option 1**: Use VirtualBox exclusively
```bash
vagrant destroy -f
vagrant up --provision  # Defaults to VirtualBox
```

**Option 2**: Check VMware network status
```bash
# List available vmnets
ifconfig | grep vmnet

# Restart VMware networking
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cli --configure
```

## Future Improvements

1. **Add Virtual Router (VirtualBox)**:
   - Use RouterOS or vyOS container instead of Linux VM
   - More realistic production setup

2. **Multi-Provider Testing**:
   - Add CI/CD tests against both VirtualBox and VMware
   - Catch hypervisor incompatibilities early

3. **Network Monitoring**:
   - Add Prometheus + Grafana containers
   - Monitor traffic across interfaces

4. **Test Coverage**:
   - Add network latency simulation
   - Add packet loss scenarios
