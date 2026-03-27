#!/bin/bash
set -e

# Key directory
KEY_DIR="/home/alex/module-signing"

echo "Using keys in $KEY_DIR"
if [ ! -d "$KEY_DIR" ]; then
    echo "Error: Key directory $KEY_DIR does not exist."
    exit 1
fi

echo "Re-signing VirtualBox modules..."

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

echo "Attempting to load vboxdrv module..."
modprobe vboxdrv
echo "SUCCESS: vboxdrv module loaded!"
