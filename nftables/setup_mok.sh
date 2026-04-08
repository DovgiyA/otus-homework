#!/bin/bash
set -e

# Key directory
KEY_DIR="/home/alex/module-signing"

echo "Using keys in $KEY_DIR"
if [ ! -d "$KEY_DIR" ]; then
    echo "Error: Key directory $KEY_DIR does not exist."
    exit 1
fi

echo "Starting VirtualBox module signing..."

# Locate sign-file utility
SIGN_FILE="/usr/src/linux-headers-$(uname -r)/scripts/sign-file"

if [ ! -f "$SIGN_FILE" ]; then
    echo "Error: sign-file not found at $SIGN_FILE"
    exit 1
fi

MOK_PRIV="$KEY_DIR/MOK.priv"
MOK_DER="$KEY_DIR/MOK.der"

# List of modules to sign
MODULES=("vboxdrv" "vboxnetflt" "vboxnetadp" "vboxpci")

for mod in "${MODULES[@]}"; do
    # Find module path
    mod_path=$(modinfo -n "$mod" 2>/dev/null) || true
    
    if [ -n "$mod_path" ] && [ -f "$mod_path" ]; then
        echo "Signing $mod at $mod_path..."
        "$SIGN_FILE" sha256 "$MOK_PRIV" "$MOK_DER" "$mod_path"
    else
        echo "Module $mod not found. Skipping."
    fi
done

echo "Importing MOK to Secure Boot..."
echo "Setting MOK enrollment password to 'password'..."
# Provide password twice for confirmation to mokutil
printf "password\npassword\n" | mokutil --import "$MOK_DER"

echo "========================================================"
echo "SUCCESS! The modules have been signed and key imported."
echo "You must now REBOOT your system."
echo "On the blue 'Shim UEFI key management' screen:"
echo "1. Select 'Enroll MOK'"
echo "2. Select 'Continue'"
echo "3. Select 'Yes'"
echo "4. Enter password: password"
echo "5. Select 'Reboot'"
echo "========================================================"
