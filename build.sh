#!/bin/bash
set -e

DEVICE="${1:-hiphi}"
echo "Starting UEFI build process for device: $DEVICE"

export WORKSPACE="$PWD"
export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-

# Clone edk2 with submodules if missing
if [ ! -d "edk2" ]; then
    echo "Cloning edk2 with submodules..."
    git clone --depth 1 --recursive https://github.com/tianocore/edk2.git
else
    echo "Updating edk2 submodules..."
    cd edk2 && git submodule update --init --recursive && cd ..
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

# Add BaseTools binaries to PATH so the 'build' command works
export PATH="$WORKSPACE/edk2/BaseTools/Bin/Linux-x86_64:$PATH"

# Source setup environment script
echo "Initializing environment..."
set +e
source edk2/edksetup.sh
set -e

# Find the correct Snapdragon / device DSC file (avoiding unrelated platforms like Loongson)
DSC_FILE=""
if [ -f "Platforms/Sm8450Pkg/Sm8450.dsc" ]; then
    DSC_FILE="Platforms/Sm8450Pkg/Sm8450.dsc"
else
    # Search specifically for sm8450, qcom, or hiphi DSC files
    DSC_FILE=$(find edk2-platforms -name "*Sm8450*.dsc" -o -name "*hiphi*.dsc" -o -name "*Qcom*.dsc" | head -n 1)
fi

if [ -n "$DSC_FILE" ]; then
    echo "Using DSC: $DSC_FILE"
    build -a AARCH64 -t GCC5 -p "$DSC_FILE"
else
    echo "Error: Could not find a valid SM8450 / Snapdragon DSC platform file."
    exit 1
fi

echo "Build completed successfully!"
