#!/bin/bash
set -e

DEVICE="${1:-hiphi}"
echo "Starting UEFI build process for device: $DEVICE"

export WORKSPACE="$PWD"
export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-

# Automatically clone missing EDK2 dependencies if they don't exist
if [ ! -d "edk2" ]; then
    echo "Cloning edk2..."
    git clone --depth 1 https://github.com/tianocore/edk2.git
fi

if [ ! -d "edk2-platforms" ]; then
    echo "Cloning edk2-platforms..."
    git clone --depth 1 https://github.com/tianocore/edk2-platforms.git
fi

if [ ! -d "edk2-non-osi" ]; then
    echo "Cloning edk2-non-osi..."
    git clone --depth 1 https://github.com/tianocore/edk2-non-osi.git
fi

export PACKAGES_PATH="$WORKSPACE/edk2:$WORKSPACE/edk2-platforms:$WORKSPACE/edk2-non-osi:$WORKSPACE/device"

# Build EDK2 BaseTools
echo "Building BaseTools..."
make -C edk2/BaseTools

# Source setup environment script
echo "Initializing environment..."
set +e
source edk2/edksetup.sh
set -e

# Build platform configuration matching the device codename
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
