#!/bin/bash
# Verification script for PXE Server setup
# This script checks that all required services are running correctly

set -e

echo "================================"
echo "PXE Server Verification Script"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_service() {
    local service=$1
    echo -n "Checking $service... "
    if systemctl is-active --quiet $service; then
        echo -e "${GREEN}✓ Running${NC}"
        return 0
    else
        echo -e "${RED}✗ Not running${NC}"
        return 1
    fi
}

check_file() {
    local file=$1
    local description=$2
    echo -n "Checking $description... "
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ Exists${NC}"
        return 0
    else
        echo -e "${RED}✗ Missing${NC}"
        return 1
    fi
}

check_directory() {
    local dir=$1
    local description=$2
    echo -n "Checking $description... "
    if [ -d "$dir" ]; then
        local count=$(ls -1 "$dir" 2>/dev/null | wc -l)
        echo -e "${GREEN}✓ Exists ($count files)${NC}"
        return 0
    else
        echo -e "${RED}✗ Missing${NC}"
        return 1
    fi
}

check_http() {
    local url=$1
    local description=$2
    echo -n "Checking $description... "
    if curl -s -f -I "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Accessible${NC}"
        return 0
    else
        echo -e "${RED}✗ Not accessible${NC}"
        return 1
    fi
}

echo "1. Service Status Checks"
echo "------------------------"
check_service "isc-dhcp-server"
check_service "tftpd-hpa"
check_service "nginx"
echo ""

echo "2. TFTP Boot Files"
echo "------------------"
check_file "/var/lib/tftpboot/bootx64.efi" "UEFI Shim bootloader"
check_file "/var/lib/tftpboot/grubx64.efi" "GRUB bootloader"
check_file "/var/lib/tftpboot/grub/grub.cfg" "GRUB configuration"
check_file "/var/lib/tftpboot/linux" "Ubuntu kernel"
check_file "/var/lib/tftpboot/initrd.gz" "Ubuntu initrd"
echo ""

echo "3. HTTP Repository"
echo "------------------"
check_directory "/var/www/html/ubuntu" "Ubuntu repository directory"
check_directory "/var/www/html/autoinstall" "Autoinstall directory"
check_file "/var/www/html/autoinstall/user-data" "Autoinstall user-data"
check_file "/var/www/html/autoinstall/meta-data" "Autoinstall meta-data"
echo ""

echo "4. HTTP Accessibility"
echo "---------------------"
check_http "http://localhost/ubuntu/" "Ubuntu repository HTTP"
check_http "http://localhost/autoinstall/user-data" "Autoinstall user-data HTTP"
echo ""

echo "5. Configuration Files"
echo "----------------------"
check_file "/etc/dhcp/dhcpd.conf" "DHCP configuration"
check_file "/etc/nginx/sites-enabled/pxe" "Nginx PXE site"
echo ""

echo "6. Network Configuration"
echo "------------------------"
echo -n "Checking IP address on eth1... "
ETH1_IP=$(ip -4 addr show eth1 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "")
if [ "$ETH1_IP" = "192.168.50.10" ]; then
    echo -e "${GREEN}✓ $ETH1_IP${NC}"
else
    echo -e "${YELLOW}⚠ $ETH1_IP (expected 192.168.50.10)${NC}"
fi
echo ""

echo "7. Listening Ports"
echo "------------------"
echo -n "DHCP Server (UDP 67)... "
if ss -ulnp | grep -q ":67"; then
    echo -e "${GREEN}✓ Listening${NC}"
else
    echo -e "${RED}✗ Not listening${NC}"
fi

echo -n "TFTP Server (UDP 69)... "
if ss -ulnp | grep -q ":69"; then
    echo -e "${GREEN}✓ Listening${NC}"
else
    echo -e "${RED}✗ Not listening${NC}"
fi

echo -n "HTTP Server (TCP 80)... "
if ss -tlnp | grep -q ":80"; then
    echo -e "${GREEN}✓ Listening${NC}"
else
    echo -e "${RED}✗ Not listening${NC}"
fi
echo ""

echo "================================"
echo "Verification Complete!"
echo "================================"
echo ""
echo "Next steps:"
echo "  1. Boot the PXE client VM"
echo "  2. Watch the VirtualBox console for network boot"
echo "  3. Installation should proceed automatically"
echo ""
