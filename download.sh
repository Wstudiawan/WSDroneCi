#!/usr/bin/env bash

echo "Downloading few Dependecies . . ."
# Kernel Sources
git clone --depth=1 https://$GH_USERNAME:$GH_TOKEN@$KERNEL_SOURCE -b $KERNEL_BRANCH $DEVICE_CODENAME
# Toolchain
git clone --depth=1 https://github.com/AnGgIt86/arm64-gcc NFS-Toolchain
git clone --depth=1 https://github.com/AnGgIt86/gcc-arm NFS-Toolchain32
git clone --depth=1 https://github.com/AnGgIt88/Finix-Clang NFS-Clang
