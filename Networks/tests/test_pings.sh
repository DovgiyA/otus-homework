#!/bin/bash
# Test connectivity between all VMs (simplified topology)

echo "=== Connectivity Tests ==="
echo ""

PASS=0
FAIL=0

echo "Test 1: Check all VMs can ping inetRouter (192.168.200.10)"
echo "=========================================================="
for vm in centralServer office1Server office2Server centralRouter office1Router office2Router; do
    echo -n "[$vm] -> inetRouter: "
    if vagrant ssh $vm -c "ping -c 1 192.168.200.10" 2>/dev/null | grep -q "1 received"; then
        echo "OK"
        ((PASS++))
    else
        echo "FAIL"
        ((FAIL++))
    fi
done

echo ""
echo "Test 2: Check servers can reach internet"
echo "========================================="
for vm in centralServer office1Server office2Server; do
    echo -n "[$vm] -> 8.8.8.8: "
    if vagrant ssh $vm -c "ping -c 1 8.8.8.8" 2>/dev/null | grep -q "1 received"; then
        echo "OK"
        ((PASS++))
    else
        echo "FAIL"
        ((FAIL++))
    fi
done

echo ""
echo "Test 3: Check cross-VM connectivity"
echo "===================================="
declare -A ips
ips[centralServer]="192.168.200.21"
ips[office1Server]="192.168.200.22"
ips[office2Server]="192.168.200.23"

for vm in centralServer office1Server office2Server; do
    for target in centralServer office1Server office2Server; do
        if [ "$vm" != "$target" ]; then
            target_ip="${ips[$target]}"
            echo -n "[$vm] -> $target ($target_ip): "
            if vagrant ssh $vm -c "ping -c 1 $target_ip" 2>/dev/null | grep -q "1 received"; then
                echo "OK"
                ((PASS++))
            else
                echo "FAIL"
                ((FAIL++))
            fi
        fi
    done
done

echo ""
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ $FAIL -eq 0 ]; then
    echo "ALL TESTS PASSED"
    exit 0
else
    echo "SOME TESTS FAILED"
    exit 1
fi
