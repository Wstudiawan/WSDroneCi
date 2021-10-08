#!/usr/bin/env bash

export KERNEL_NAME=Finix-Kernel-GCC

# Main Declaration
KERNEL_ROOTDIR=$(pwd)/$DEVICE_CODENAME # IMPORTANT ! Fill with your kernel source root directory.
DEVICE_DEFCONFIG=$DEVICE_DEFCONFIG # IMPORTANT ! Declare your kernel source defconfig file here.
GCC_ROOTDIR=$(pwd)/NFS-Toolchain # IMPORTANT! Put your GCC directory here.
GCC_ROOTDIR32=$(pwd)/NFS-Toolchain32 # IMPORTANT! Put your GCC directory here.
export KBUILD_BUILD_USER=$BUILD_USER # Change with your own name or else.
export KBUILD_BUILD_HOST=$BUILD_HOST # Change with your own hostname.

# Main Declaration
GCC_VER="$("$GCC_ROOTDIR"/bin/aarch64-elf-gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
GCC_VER32="$("$GCC_ROOTDIR32"/bin/arm-eabi-gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
LLD_VER="$("$GCC_ROOTDIR"/bin/ld.lld --version | head -n 1)"
export KBUILD_COMPILER_STRING="$GCC_VER"
export KBUILD_COMPILER_STRING32="$GCC_VER32  with $LLD_VER"
IMAGE=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/Image.gz-dtb
DATE=$(date +"%F-%S")
START=$(date +"%s")

# Checking environtment
# Warning !! Dont Change anything there without known reason.
function check() {
echo ================================================
echo NFS-KernelCompiler
echo "              _  __  ____  ____               "
echo "             / |/ / / __/ / __/               "
echo "      __    /    / / _/  _\ \    __           "
echo "     /_/   /_/|_/ /_/   /___/   /_/           "
echo "    ___  ___  ____     _________________      "
echo "   / _ \/ _ \/ __ \__ / / __/ ___/_  __/      "
echo "  / ___/ , _/ /_/ / // / _// /__  / /         "
echo " /_/  /_/|_|\____/\___/___/\___/ /_/          "
echo ================================================
echo BUILDER NAME = ${KBUILD_BUILD_USER}
echo BUILDER HOSTNAME = ${KBUILD_BUILD_HOST}
echo DEVICE_DEFCONFIG = ${DEVICE_DEFCONFIG}
echo TOOLCHAIN_VERSION = ${KBUILD_COMPILER_STRING}
echo GCC_ROOTDIR = ${GCC_ROOTDIR}
echo KERNEL_ROOTDIR = ${KERNEL_ROOTDIR}
echo ================================================
}

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"

}

# Post Main Information
tg_post_msg "<b>$KERNEL_NAME-(rosy)</b>%0ABuilder Name : <code>${KBUILD_BUILD_USER}</code>%0ABuilder Host : <code>${KBUILD_BUILD_HOST}</code>%0ADevice Defconfig: <code>${DEVICE_DEFCONFIG}</code>%0AGCC Version : <code>${KBUILD_COMPILER_STRING}</code>%0AGCC Version32 : <code>${KBUILD_COMPILER_STRING32}</code>%0AGCC Rootdir : <code>${GCC_ROOTDIR}</code>%0AKernel Rootdir : <code>${KERNEL_ROOTDIR}</code>"

# Compile
compile(){
cd ${KERNEL_ROOTDIR}
make -j$(nproc) O=out ARCH=arm64 SUBARCH=arm64 ${DEVICE_DEFCONFIG}
make -j$(nproc) ARCH=arm64 SUBARCH=arm64 O=out \
    AR=${GCC_ROOTDIR}/bin/llvm-ar \
    NM=${GCC_ROOTDIR}/bin/llvm-nm \
    OBJCOPY=${GCC_ROOTDIR}/bin/llvm-objcopy \
    OBJDUMP=${GCC_ROOTDIR}/bin/llvm-objdump \
    STRIP=${GCC_ROOTDIR}/bin/llvm-strip \
    CROSS_COMPILE=${GCC_ROOTDIR}/bin/aarch64-elf- \
    CROSS_COMPILE_ARM32=${GCC_ROOTDIR32}/bin/arm-eabi-

   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi

	git clone --depth=1 $ANYKERNEL AnyKernel
	cp $IMAGE AnyKernel
}

# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>$DEVICE_CODENAME</b> | <b>${KBUILD_COMPILER_STRING}</b> | <b>${KBUILD_COMPILER_STRING32}</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}

# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 $KERNEL_NAME-$DEVICE_CODENAME-${DATE}.zip *
    cd ..
}
check
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
