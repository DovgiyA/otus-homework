#!/bin/bash
# Test IP forwarding and NAT configuration

echo "=== IP Forwarding and NAT Tests ==="
echo ""

echo "IP Forwarding Status (routers):"
echo "================================"
for vm in inetRouter centralRouter office1Router office2Router; do
    echo -n "[$vm] IP forwarding: "
    vagrant ssh $vm -c "sysctl net.ipv4.ip_forward" 2>/dev/null || echo "FAIL"
done

echo ""
echo "IP Forwarding Status (servers - should be 0 or 1):"
echo "==================================================="
for vm in centralServer office1Server office2Server; do
    echo -n "[$vm] IP forwarding: "
    vagrant ssh $vm -c "sysctl net.ipv4.ip_forward" 2>/dev/null || echo "FAIL"
done

echo ""
echo "NAT Rules on inetRouter:"
echo "========================"
vagrant ssh inetRouter -c "sudo iptables -L -n -t nat | grep -A 5 POSTROUTING" 2>/dev/null || echo "FAIL"

echo ""
echo "Interface IPs:"
echo "=============="
echo "inetRouter:"
vagrant ssh inetRouter -c "ip -4 addr show eth1" 2>/dev/null || echo "FAIL"
echo ""
echo "centralRouter:"
vagrant ssh centralRouter -c "ip -4 addr show eth1" 2>/dev/null || echo "FAIL"
