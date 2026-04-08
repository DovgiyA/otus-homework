#!/bin/bash
# Test routing tables on all VMs (simplified topology)

echo "=== Routing Table Tests ==="
echo ""

echo "[inetRouter] Routing table:"
vagrant ssh inetRouter -c "ip route"

echo ""
echo "[centralRouter] Routing table:"
vagrant ssh centralRouter -c "ip route"

echo ""
echo "[office1Router] Routing table:"
vagrant ssh office1Router -c "ip route"

echo ""
echo "[office2Router] Routing table:"
vagrant ssh office2Router -c "ip route"

echo ""
echo "[centralServer] Routing table:"
vagrant ssh centralServer -c "ip route"

echo ""
echo "[office1Server] Routing table:"
vagrant ssh office1Server -c "ip route"

echo ""
echo "[office2Server] Routing table:"
vagrant ssh office2Server -c "ip route"

echo ""
echo "=== Route validation ==="

# Check that all non-inetRouter VMs have default via 192.168.200.10
for vm in centralRouter office1Router office2Router centralServer office1Server office2Server; do
    echo -n "[$vm] Has default via 192.168.200.10: "
    if vagrant ssh $vm -c "ip route" 2>/dev/null | grep -q "default via 192.168.200.10"; then
        echo "OK"
    else
        echo "FAIL"
    fi
done

# Check that no VM has Vagrant NAT route
echo ""
echo "Checking for Vagrant NAT routes (should be absent):"
for vm in centralServer office1Server office2Server; do
    echo -n "[$vm] No 10.0.2.0/24 route: "
    if vagrant ssh $vm -c "ip route" 2>/dev/null | grep -q "10.0.2"; then
        echo "FAIL (has Vagrant NAT)"
    else
        echo "OK"
    fi
done
