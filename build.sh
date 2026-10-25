#!/bin/bash
set -e

DEVICE="${1:-hiphi}"
echo "Starting UEFI build process for device: $DEVICE"

# Initialize workspace paths
export WORKSPACE="$PWD"
export PACKAGES_PATH="$WORKSPACE/edk2:$WORKSPACE/edk2-platforms:$WORKSPACE/edk2-non-osi:$WORKSPACE/device"

# Setup GCC toolchain prefix for ARM64
export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-

# Check if edk2 directory exists, otherwise hint to add submodules
if [ ! -d "edk2" ]; then
    echo "Error: 'edk2' directory missing. Make sure submodules are checked out recursively."
    exit 1
fi

# Build EDK2 BaseTools if needed
echo "Building BaseTools..."
make -C edk2/BaseTools

# Source setup environment script
echo "Initializing environment..."
set +e
source edk2/edksetup.sh
set -e

# Build platform configuration matching the device codename
# (Adjust the DSC path if your platform layout differs)
if [ -f "Platforms/Sm8450Pkg/Sm8450.dsc" ]; then
    build -a AARCH64 -t GCC5 -p Platforms/Sm8450Pkg/Sm8450.dsc
elif [ -f "DeviceTreePkg/DeviceTree.dsc" ]; then
    build -a AARCH64 -t GCC5 -p DeviceTreePkg/DeviceTree.dsc
else
    echo "Looking for available DSC files..."
    DSC_FILE=$(find . -name "*.dsc" | head -n 1)
    if [ -n "$DSC_FILE" ]; then
        echo "Using DSC: $DSC_FILE"
        build -a AARCH64 -t GCC5 -p "$DSC_FILE"
    else
      echo "Error: No EDK2 DSC platform file found."
      exit 1
    fi
fi

echo "Build completed successfully!"
