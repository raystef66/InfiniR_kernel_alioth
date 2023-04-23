#export PLATFORM_VERSION=12
#export ANDROID_MAJOR_VERSION=s
#!/bin/bash

#
# Copyright (c) 2020, Jebaitedneko.
#

KERNEL_ROOT_DIR=$(pwd)

TARGET_ARCH="arm64"
[[ -f "$KERNEL_ROOT_DIR/arch/$TARGET_ARCH/configs/vendor/alioth_defconfig" ]] && \
KERNEL_CONFIG="alioth_defconfig" \
|| KERNEL_CONFIG="alioth_defconfig"
ZIP_KERNEL_STR="coreLinux"
ZIP_DEVICE_NAME="apollo"
ZIP_PREFIX_STR="SigmaKernel-v1.0"
export KBUILD_BUILD_USER="nob0dy"
export KBUILD_BUILD_HOST="sigmaS0r"
USER_OVERRIDE="root"
IS_WSL_USER="0"
if [[ $USER == "$USER_OVERRIDE" ]]; then
	ENABLE_CCACHE="1"
fi

#############################
TOOLCHAIN="3"               #
# 1) gcc-4.9                #
# 2) eva-gcc-12             #
# 3) proton-clang-13        #
# 4) sdclang-12.1           #
# 5) aosp-clang-r416183c    #
# 6) aospa-gcc-10.2         #
# 7) arter-gcc [9.3 & 11.1] #
#############################

USE_UNCOMPRESSED_KERNEL="1"
DISABLE_LLD="1"
DISABLE_IAS="0"
DISABLE_LLD_IAS="0"
USE_LLVM_TOOLS="0"
BUILD_MODULES="0"
DO_SYSTEMLESS="1"
BUILD_DTBO_IMG="0"
PATCH_PERMISSIVE="0"
PATCH_CLASSPATH="0"
RAMOOPS_MEMRESERVE="0"
DTC_EXT_FOR_DTC="0"

OUT_BOOT_DIR="$KERNEL_ROOT_DIR/out/arch/$TARGET_ARCH/boot"
DTB_DTBO_DIR="$OUT_BOOT_DIR/dts/vendor/qcom"

TOOLCHAIN_DIR="$KERNEL_ROOT_DIR/../../toolchains"

ANYKERNEL_DIR="$TOOLCHAIN_DIR/anykernel3"
ANYKERNEL_SRC="https://github.com/osm0sis/AnyKernel3"

DTBTOOL_DIR="$TOOLCHAIN_DIR/dtbtool"
DTBTOOL_SRC="https://raw.githubusercontent.com/LineageOS/android_system_tools_dtbtool/lineage-18.1/dtbtool.c"
DTBTOOL_ARGS="-v -s 2048 -o $OUT_BOOT_DIR/dt.img"

UFDT_DIR="$TOOLCHAIN_DIR/libufdt"
UFDT_SRC="https://android.googlesource.com/platform/system/libufdt"
UFDT_ARGS="create dtbo.img  $DTB_DTBO_DIR/*.dtbo"

BUILD_MODULES_DIR="$KERNEL_ROOT_DIR/out/modules"

dts_source=arch/arm64/boot/dts/vendor/qcom
# Correct panel dimensions on MIUI builds
function miui_fix_dimens() {
    sed -i 's/<70>/<695>/g' $dts_source/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
    sed -i 's/<70>/<695>/g' $dts_source/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
    sed -i 's/<70>/<695>/g' $dts_source/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
    sed -i 's/<71>/<710>/g' $dts_source/dsi-panel-j1s*
    sed -i 's/<71>/<710>/g' $dts_source/dsi-panel-j2*
    sed -i 's/<155>/<1544>/g' $dts_source/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
    sed -i 's/<155>/<1545>/g' $dts_source/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
    sed -i 's/<155>/<1546>/g' $dts_source/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
    sed -i 's/<154>/<1537>/g' $dts_source/dsi-panel-j1s*
    sed -i 's/<154>/<1537>/g' $dts_source/dsi-panel-j2*
}

# Enable back mi smartfps while disabling qsync min refresh-rate
function miui_fix_fps() {
    sed -i 's/qcom,mdss-dsi-qsync-min-refresh-rate/\/\/qcom,mdss-dsi-qsync-min-refresh-rate/g' $dts_source/dsi-panel*
    sed -i 's/\/\/ mi,mdss-dsi-smart-fps-max_framerate/mi,mdss-dsi-smart-fps-max_framerate/g' $dts_source/dsi-panel*
    sed -i 's/\/\/ mi,mdss-dsi-pan-enable-smart-fps/mi,mdss-dsi-pan-enable-smart-fps/g' $dts_source/dsi-panel*
    sed -i 's/\/\/ qcom,mdss-dsi-pan-enable-smart-fps/qcom,mdss-dsi-pan-enable-smart-fps/g' $dts_source/dsi-panel*
}

# Enable back refresh rates supported on MIUI
function miui_fix_dfps() {
    sed -i 's/120 90 60/120 90 60 50 30/g' $dts_source/dsi-panel-g7a-37-02-0a-dsc-video.dtsi
    sed -i 's/120 90 60/120 90 60 50 30/g' $dts_source/dsi-panel-g7a-37-02-0b-dsc-video.dtsi
    sed -i 's/120 90 60/120 90 60 50 30/g' $dts_source/dsi-panel-g7a-36-02-0c-dsc-video.dtsi
    sed -i 's/144 120 90 60/144 120 90 60 50 48 30/g' $dts_source/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
}

# Enable back brightness control from dtsi
function miui_fix_fod() {
    sed -i 's/\/\/39 01 00 00 01 00 03 51 03 FF/39 01 00 00 01 00 03 51 03 FF/g' $dts_source/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 03 FF/39 01 00 00 00 00 03 51 03 FF/g' $dts_source/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
    sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' $dts_source/dsi-panel-j1s-42-02-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' $dts_source/dsi-panel-j1s-42-02-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' $dts_source/dsi-panel-j1s-42-02-0a-mp-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' $dts_source/dsi-panel-j1s-42-02-0a-mp-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' $dts_source/dsi-panel-j1u-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' $dts_source/dsi-panel-j1u-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 00 00/39 01 00 00 00 00 03 51 00 00/g' $dts_source/dsi-panel-j2-38-0c-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 00 00/39 01 00 00 00 00 03 51 00 00/g' $dts_source/dsi-panel-j2-38-0c-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' $dts_source/dsi-panel-j2-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' $dts_source/dsi-panel-j2-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' $dts_source/dsi-panel-j2-mp-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' $dts_source/dsi-panel-j2-mp-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' $dts_source/dsi-panel-j2-p1-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' $dts_source/dsi-panel-j2-p1-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 00 00 00 00 00 03 51 0D FF/39 00 00 00 00 00 03 51 0D FF/g' $dts_source/dsi-panel-j2-p2-1-38-0c-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 11 00 03 51 03 FF/39 01 00 00 11 00 03 51 03 FF/g' $dts_source/dsi-panel-j2-p2-1-38-0c-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' $dts_source/dsi-panel-j2-p2-1-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' $dts_source/dsi-panel-j2-p2-1-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' $dts_source/dsi-panel-j2s-mp-42-02-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' $dts_source/dsi-panel-j2s-mp-42-02-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 00 00 00 00 00 03 51 03 FF/39 00 00 00 00 00 03 51 03 FF/g' $dts_source/dsi-panel-j9-38-0a-0a-fhd-video.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 03 FF/39 01 00 00 00 00 03 51 03 FF/g' $dts_source/dsi-panel-j9-38-0a-0a-fhd-video.dtsi
}

miui_fix_dimens
miui_fix_fps
miui_fix_dfps
miui_fix_fod

run() {

	echo -e "\n${1}\n"
	sh -c "${1}"

}

git_clone() {

	if [[ $USER == "$USER_OVERRIDE" ]]; then
		if [ ! -d "${3}" ]; then
			mkdir -p "${3}"
			run "git clone \
				--depth=1 \
				--single-branch \
				\"${1}\" \
				-b \"${2}\" \
				\"${3}\" &> /dev/null"
		fi
	else
		folder_fmt="$(echo "${1}" | cut -f5 -d/)-${2}"
		if [ ! -d "${3}/$folder_fmt" ]; then
			(
				mkdir -p "${3}"
				( cd "${3}"/.. && run "wget \"${1}/archive/${2}.zip\" &> /dev/null" )
				run "unzip \"${3}/../${2}.zip*\" -d \"${3}\" &> /dev/null"
			)
		fi
	fi

}

check_updates_from_github() {

	if [[ $USER == "$USER_OVERRIDE" ]]; then
		if [[ $(echo "${1}" | grep github | wc -c) -gt 0 ]]; then

			REMOTE_SHA=$(curl -s "${1}/commits/${2}" | grep "Copy the full SHA" | grep -oE "[0-9a-f]{40}" | head -n1)
			LOCAL_SHA=$( ( cd "${3}"; [ -d ".git" ] && git log | grep -oE "[0-9a-f]{40}" | head -n1 ) )

			if [[ ! ${#REMOTE_SHA} -eq 41 ]]; then
				REMOTE_SHA=$(curl -s "${1}/commits/${2}" | grep "Copy the full SHA" | grep -oE "[0-9a-f]{40}" | head -n1)
			fi

			if [[ "${REMOTE_SHA}" != "" ]]; then
				echo -e "\nREMOTE: ${REMOTE_SHA}"
				echo -e "\nLOCAL:  ${LOCAL_SHA}"
				if [[ "${REMOTE_SHA}" != "${LOCAL_SHA}" ]]; then
					echo -e "\nSHA Mismatch. Fetching Upstream...\n"
					( rm -rf "${3}"; git clone --depth=1 "${1}" --single-branch -b "${2}" "${3}" )
				else
					echo -e "\nSHA Matched.\n"
				fi
			fi
		fi
	fi

}

use_llvm_for_gcc() {

	if [[ $USE_LLVM_TOOLS == "1" ]]; then

		PFX_OVERRIDE=$TOOLCHAIN_DIR/proton-clang-13.0/bin/

		if [[ $USER != "$USER_OVERRIDE" ]]; then
			echo -e "\nBuilding from CI. Fetching LLVM Tools...\n"
			SRC="https://github.com/kdrag0n/proton-clang/raw/master/bin"
			wget -q ${SRC}/lld -O /tmp/ld.lld && chmod +x /tmp/ld.lld
			wget -q ${SRC}/llvm-ar -O /tmp/llvm-ar && chmod +x /tmp/llvm-ar
			wget -q ${SRC}/llvm-as -O /tmp/llvm-as && chmod +x /tmp/llvm-as
			wget -q ${SRC}/llvm-nm -O /tmp/llvm-nm && chmod +x /tmp/llvm-nm
			wget -q ${SRC}/llvm-objcopy -O /tmp/llvm-strip && chmod +x /tmp/llvm-strip
			wget -q ${SRC}/llvm-objdump -O /tmp/llvm-objdump && chmod +x /tmp/llvm-objdump
			cp /tmp/llvm-strip /tmp/llvm-objcopy && chmod +x /tmp/llvm-objcopy # strip is objcopy as well
			PFX_OVERRIDE=/tmp/
			echo -e "\nDone.\n"
		fi

		MAKEOPTS="LD=${PFX_OVERRIDE}ld.lld AR=${PFX_OVERRIDE}llvm-ar AS=${PFX_OVERRIDE}llvm-as NM=${PFX_OVERRIDE}llvm-nm STRIP=${PFX_OVERRIDE}llvm-strip
					OBJCOPY=${PFX_OVERRIDE}llvm-objcopy OBJDUMP=${PFX_OVERRIDE}llvm-objdump READELF=${PFX_OVERRIDE}llvm-readelf
					HOSTAR=${PFX_OVERRIDE}llvm-ar HOSTAS=${PFX_OVERRIDE}llvm-as HOSTLD=${PFX_OVERRIDE}ld.lld"

		if [[ $DISABLE_LLD == "1" ]]; then
			MAKEOPTS="AR=${PFX_OVERRIDE}llvm-ar AS=${PFX_OVERRIDE}llvm-as NM=${PFX_OVERRIDE}llvm-nm STRIP=${PFX_OVERRIDE}llvm-strip
						OBJCOPY=${PFX_OVERRIDE}llvm-objcopy OBJDUMP=${PFX_OVERRIDE}llvm-objdump READELF=${PFX_OVERRIDE}llvm-readelf
						HOSTAR=${PFX_OVERRIDE}llvm-ar HOSTAS=${PFX_OVERRIDE}llvm-as"
		else
			if [[ $DISABLE_IAS == "1" ]]; then
				MAKEOPTS="LD=${PFX_OVERRIDE}ld.lld AR=${PFX_OVERRIDE}llvm-ar NM=${PFX_OVERRIDE}llvm-nm STRIP=${PFX_OVERRIDE}llvm-strip
							OBJCOPY=${PFX_OVERRIDE}llvm-objcopy OBJDUMP=${PFX_OVERRIDE}llvm-objdump READELF=${PFX_OVERRIDE}llvm-readelf
							HOSTAR=${PFX_OVERRIDE}llvm-ar HOSTLD=${PFX_OVERRIDE}ld.lld"
			else
				if [[ $DISABLE_LLD_IAS == "1" ]]; then
					MAKEOPTS="AR=${PFX_OVERRIDE}llvm-ar NM=${PFX_OVERRIDE}llvm-nm STRIP=${PFX_OVERRIDE}llvm-strip
								OBJCOPY=${PFX_OVERRIDE}llvm-objcopy OBJDUMP=${PFX_OVERRIDE}llvm-objdump READELF=${PFX_OVERRIDE}llvm-readelf
								HOSTAR=${PFX_OVERRIDE}llvm-ar"
				fi
			fi
		fi
	fi

}

get_gcc-4.9() {

	TC_64="$TOOLCHAIN_DIR/los-gcc-4.9-64"
	REPO_64="https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9"
	BRANCH_64="lineage-18.1"

	TC_32="$TOOLCHAIN_DIR/los-gcc-4.9-32"
	REPO_32="https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9"
	BRANCH_32="lineage-18.1"

	if [[ $USER != "$USER_OVERRIDE" ]]; then

		git_clone "${REPO_64}" "${BRANCH_64}" "${TC_64}" &
		check_updates_from_github "${REPO_64}" "${BRANCH_64}" "${TC_64}" &

		git_clone "${REPO_32}" "${BRANCH_32}" "${TC_32}" &
		check_updates_from_github "${REPO_32}" "${BRANCH_32}" "${TC_32}" &

		wait

		TC_64="$TC_64/$(echo ${REPO_64} | cut -f5 -d/)-${BRANCH_64}"
		TC_32="$TC_32/$(echo ${REPO_32} | cut -f5 -d/)-${BRANCH_32}"
	else
		git_clone "${REPO_64}" "${BRANCH_64}" "${TC_64}"
		check_updates_from_github "${REPO_64}" "${BRANCH_64}" "${TC_64}"

		git_clone "${REPO_32}" "${BRANCH_32}" "${TC_32}"
		check_updates_from_github "${REPO_32}" "${BRANCH_32}" "${TC_32}"
	fi

	CROSS="$TC_64/bin/aarch64-linux-android-"
	CROSS_ARM32="$TC_32/bin/arm-linux-androideabi-"

	MAKEOPTS=""

	use_llvm_for_gcc

}

get_gcc-4.9-aosp() {

	TC_64="$TOOLCHAIN_DIR/gcc-4.9-64"
	REPO_64="https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9"
	BRANCH_64="master"

	TC_32="$TOOLCHAIN_DIR/gcc-4.9-32"
	REPO_32="https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9"
	BRANCH_32="master"

	if [[ $USER != "$USER_OVERRIDE" ]]; then

		git_clone "${REPO_64}" "${BRANCH_64}" "${TC_64}" &
		check_updates_from_github "${REPO_64}" "${BRANCH_64}" "${TC_64}" &

		git_clone "${REPO_32}" "${BRANCH_32}" "${TC_32}" &
		check_updates_from_github "${REPO_32}" "${BRANCH_32}" "${TC_32}" &

		wait

		TC_64="$TC_64/$(echo ${REPO_64} | cut -f5 -d/)-${BRANCH_64}"
		TC_32="$TC_32/$(echo ${REPO_32} | cut -f5 -d/)-${BRANCH_32}"
	else
		git_clone "${REPO_64}" "${BRANCH_64}" "${TC_64}"
		check_updates_from_github "${REPO_64}" "${BRANCH_64}" "${TC_64}"

		git_clone "${REPO_32}" "${BRANCH_32}" "${TC_32}"
		check_updates_from_github "${REPO_32}" "${BRANCH_32}" "${TC_32}"
	fi

	CROSS="$TC_64/bin/aarch64-linux-android-"
	CROSS_ARM32="$TC_32/bin/arm-linux-androideabi-"

	MAKEOPTS=""
}

get_proton_clang-13.0() {

	TC="$TOOLCHAIN_DIR/proton-clang-13.0"
	REPO="https://github.com/kdrag0n/proton-clang"
	BRANCH="master"

	if [[ $USER != "$USER_OVERRIDE" ]]; then

		git_clone "${REPO}" "${BRANCH}" "${TC}" &
		check_updates_from_github "${REPO}" "${BRANCH}" "${TC}" &

		wait

		TC="$TC/$(echo ${REPO} | cut -f5 -d/)-${BRANCH}"
	else
		git_clone "${REPO}" "${BRANCH}" "${TC}"
		check_updates_from_github "${REPO}" "${BRANCH}" "${TC}"
	fi

	CROSS="$TC/bin/aarch64-linux-gnu-"
	CROSS_ARM32="$TC/bin/arm-linux-gnueabi-"

	PFX_OVERRIDE=""

	MAKEOPTS="CC=clang LD=${PFX_OVERRIDE}ld.lld AR=${PFX_OVERRIDE}llvm-ar AS=${PFX_OVERRIDE}llvm-as NM=${PFX_OVERRIDE}llvm-nm STRIP=${PFX_OVERRIDE}llvm-strip
				OBJCOPY=${PFX_OVERRIDE}llvm-objcopy OBJDUMP=${PFX_OVERRIDE}llvm-objdump READELF=${PFX_OVERRIDE}llvm-readelf
				HOSTAR=${PFX_OVERRIDE}llvm-ar HOSTAS=${PFX_OVERRIDE}llvm-as HOSTLD=${PFX_OVERRIDE}ld.lld"

	if [[ $DISABLE_LLD == "1" ]]; then
		MAKEOPTS="CC=clang AR=${PFX_OVERRIDE}llvm-ar AS=${PFX_OVERRIDE}llvm-as NM=${PFX_OVERRIDE}llvm-nm STRIP=${PFX_OVERRIDE}llvm-strip
					OBJCOPY=${PFX_OVERRIDE}llvm-objcopy OBJDUMP=${PFX_OVERRIDE}llvm-objdump READELF=${PFX_OVERRIDE}llvm-readelf
					HOSTAR=${PFX_OVERRIDE}llvm-ar HOSTAS=${PFX_OVERRIDE}llvm-as"
	else
		if [[ $DISABLE_IAS == "1" ]]; then
			MAKEOPTS="CC=clang LD=${PFX_OVERRIDE}ld.lld AR=${PFX_OVERRIDE}llvm-ar NM=${PFX_OVERRIDE}llvm-nm STRIP=${PFX_OVERRIDE}llvm-strip
						OBJCOPY=${PFX_OVERRIDE}llvm-objcopy OBJDUMP=${PFX_OVERRIDE}llvm-objdump READELF=${PFX_OVERRIDE}llvm-readelf
						HOSTAR=${PFX_OVERRIDE}llvm-ar HOSTLD=${PFX_OVERRIDE}ld.lld"
		else
			if [[ $DISABLE_LLD_IAS == "1" ]]; then
				MAKEOPTS="CC=clang AR=${PFX_OVERRIDE}llvm-ar NM=${PFX_OVERRIDE}llvm-nm STRIP=${PFX_OVERRIDE}llvm-strip
							OBJCOPY=${PFX_OVERRIDE}llvm-objcopy OBJDUMP=${PFX_OVERRIDE}llvm-objdump READELF=${PFX_OVERRIDE}llvm-readelf
							HOSTAR=${PFX_OVERRIDE}llvm-ar"
			fi
		fi
	fi

}

get_aospa_gcc-10.2() {

	TC_64="$TOOLCHAIN_DIR/aospa-gcc-10.2-64"
	REPO_64="https://github.com/AOSPA/android_prebuilts_gcc_linux-x86_aarch64_aarch64-elf"
	BRANCH_64="master"

	TC_32="$TOOLCHAIN_DIR/aospa-gcc-10.2-32"
	REPO_32="https://github.com/AOSPA/android_prebuilts_gcc_linux-x86_arm_arm-eabi"
	BRANCH_32="master"

	if [[ $USER != "$USER_OVERRIDE" ]]; then

		git_clone "${REPO_64}" "${BRANCH_64}" "${TC_64}" &
		check_updates_from_github "${REPO_64}" "${BRANCH_64}" "${TC_64}" &

		git_clone "${REPO_32}" "${BRANCH_32}" "${TC_32}" &
		check_updates_from_github "${REPO_32}" "${BRANCH_32}" "${TC_32}" &

		wait

		TC_64="$TC_64/$(echo ${REPO_64} | cut -f5 -d/)-${BRANCH_64}"
		TC_32="$TC_32/$(echo ${REPO_32} | cut -f5 -d/)-${BRANCH_32}"
	else
		git_clone "${REPO_64}" "${BRANCH_64}" "${TC_64}"
		check_updates_from_github "${REPO_64}" "${BRANCH_64}" "${TC_64}"

		git_clone "${REPO_32}" "${BRANCH_32}" "${TC_32}"
		check_updates_from_github "${REPO_32}" "${BRANCH_32}" "${TC_32}"
	fi

	CROSS="$TC_64/bin/aarch64-elf-"
	CROSS_ARM32="$TC_32/bin/arm-eabi-"

	MAKEOPTS="CONFIG_TOOLS_SUPPORT_RELR=n CONFIG_RELR=n"

}

get_arter-gcc() {

	if [[ $USE_LLVM_TOOLS == "1" ]]; then
		if [[ $USER == "$USER_OVERRIDE" ]]; then
			get_proton_clang-13.0
		fi
	fi

	TC_64="$TOOLCHAIN_DIR/arter-gcc-64"
	REPO_64="https://github.com/arter97/arm64-gcc"
	BRANCH_64="master"

	TC_32="$TOOLCHAIN_DIR/arter-gcc-32"
	REPO_32="https://github.com/arter97/arm32-gcc"
	BRANCH_32="master"

	if [[ $USER != "$USER_OVERRIDE" ]]; then
		# 9.3.0
		# BRANCH_64="811a3bc6b40ad924cd1a24a481b6ac5d9227ff7e"
		# BRANCH_32="566df579fa8123a5357c4bdcbbe62a192c5b37b4"
		# 11.1
		BRANCH_64="ec728817533e01cc90e0b51f100b24d943dc900b"
		BRANCH_32="909f80b4a17f86b1e600451d232bbb8153213c8e"
	fi

	if [[ $USER != "$USER_OVERRIDE" ]]; then

		git_clone "${REPO_64}" "${BRANCH_64}" "${TC_64}" &
		check_updates_from_github "${REPO_64}" "${BRANCH_64}" "${TC_64}" &

		git_clone "${REPO_32}" "${BRANCH_32}" "${TC_32}" &
		check_updates_from_github "${REPO_32}" "${BRANCH_32}" "${TC_32}" &

		wait

		TC_64="$TC_64/$(echo ${REPO_64} | cut -f5 -d/)-${BRANCH_64}"
		TC_32="$TC_32/$(echo ${REPO_32} | cut -f5 -d/)-${BRANCH_32}"
	else
		git_clone "${REPO_64}" "${BRANCH_64}" "${TC_64}"
		check_updates_from_github "${REPO_64}" "${BRANCH_64}" "${TC_64}"

		git_clone "${REPO_32}" "${BRANCH_32}" "${TC_32}"
		check_updates_from_github "${REPO_32}" "${BRANCH_32}" "${TC_32}"
	fi

	CROSS="$TC_64/bin/aarch64-elf-"
	CROSS_ARM32="$TC_32/bin/arm-eabi-"

	MAKEOPTS="CONFIG_TOOLS_SUPPORT_RELR=n CONFIG_RELR=n"

}

get_eva_gcc-12.0() {

	if [[ $USE_LLVM_TOOLS == "1" ]]; then
		if [[ $USER == "$USER_OVERRIDE" ]]; then
			get_proton_clang-13.0
		fi
	fi

	TC_64="$TOOLCHAIN_DIR/gcc-12.0-64"
	REPO_64="https://github.com/mvaisakh/gcc-arm64"
	BRANCH_64="gcc-new"

	TC_32="$TOOLCHAIN_DIR/gcc-12.0-32"
	REPO_32="https://github.com/mvaisakh/gcc-arm"
	BRANCH_32="gcc-new"

#	if [[ $USER != "$USER_OVERRIDE" ]]; then
# 		BRANCH_64="fdc38625ac88fba470e0c97e894319437ef1fcf5"
# 		BRANCH_32="b0446a5480a79b80cd0d58bdab75f9219035add6"
#	fi

	if [[ $USER != "$USER_OVERRIDE" ]]; then

		git_clone "${REPO_64}" "${BRANCH_64}" "${TC_64}" &
		check_updates_from_github "${REPO_64}" "${BRANCH_64}" "${TC_64}" &

		git_clone "${REPO_32}" "${BRANCH_32}" "${TC_32}" &
		check_updates_from_github "${REPO_32}" "${BRANCH_32}" "${TC_32}" &

		wait

		TC_64="$TC_64/$(echo ${REPO_64} | cut -f5 -d/)-${BRANCH_64}"
		TC_32="$TC_32/$(echo ${REPO_32} | cut -f5 -d/)-${BRANCH_32}"
	else
		git_clone "${REPO_64}" "${BRANCH_64}" "${TC_64}"
		check_updates_from_github "${REPO_64}" "${BRANCH_64}" "${TC_64}"

		git_clone "${REPO_32}" "${BRANCH_32}" "${TC_32}"
		check_updates_from_github "${REPO_32}" "${BRANCH_32}" "${TC_32}"
	fi

	CROSS="$TC_64/bin/aarch64-elf-"
	CROSS_ARM32="$TC_32/bin/arm-eabi-"

	MAKEOPTS="CONFIG_TOOLS_SUPPORT_RELR=n CONFIG_RELR=n"

	use_llvm_for_gcc

}

get_sdclang-12.1() {

	if [[ $USE_LLVM_TOOLS == "1" ]]; then
		get_proton_clang-13.0
	else
		get_gcc-4.9-aosp
	fi

	TC="$TOOLCHAIN_DIR/sdclang-12.1"
	REPO="https://github.com/ThankYouMario/proprietary_vendor_qcom_sdclang"
	BRANCH="ruby-12"

	if [[ $USER != "$USER_OVERRIDE" ]]; then

		git_clone "${REPO}" "${BRANCH}" "${TC}" &
		check_updates_from_github "${REPO}" "${BRANCH}" "${TC}" &

		wait

		TC="$TC/$(echo ${REPO} | cut -f5 -d/)-${BRANCH}"
	else
		git_clone "${REPO}" "${BRANCH}" "${TC}"
		check_updates_from_github "${REPO}" "${BRANCH}" "${TC}"
	fi

	if [[ $USE_LLVM_TOOLS == "1" ]]; then
		TRIPLE="$TC/bin/aarch64-linux-gnu-"

		PFX_OVERRIDE=$TOOLCHAIN_DIR/proton-clang-13.0/bin/

		MAKEOPTS="CC=clang CLANG_TRIPLE=$TRIPLE LD=${PFX_OVERRIDE}ld.lld AR=${PFX_OVERRIDE}llvm-ar AS=${PFX_OVERRIDE}llvm-as NM=${PFX_OVERRIDE}llvm-nm STRIP=${PFX_OVERRIDE}llvm-strip
					OBJCOPY=${PFX_OVERRIDE}llvm-objcopy OBJDUMP=${PFX_OVERRIDE}llvm-objdump READELF=${PFX_OVERRIDE}llvm-readelf
					HOSTAR=${PFX_OVERRIDE}llvm-ar HOSTAS=${PFX_OVERRIDE}llvm-as HOSTLD=${PFX_OVERRIDE}ld.lld"

		if [[ $DISABLE_LLD == "1" ]]; then
			MAKEOPTS="CC=clang CLANG_TRIPLE=$TRIPLE AR=${PFX_OVERRIDE}llvm-ar AS=${PFX_OVERRIDE}llvm-as NM=${PFX_OVERRIDE}llvm-nm STRIP=${PFX_OVERRIDE}llvm-strip
						OBJCOPY=${PFX_OVERRIDE}llvm-objcopy OBJDUMP=${PFX_OVERRIDE}llvm-objdump READELF=${PFX_OVERRIDE}llvm-readelf
						HOSTAR=${PFX_OVERRIDE}llvm-ar HOSTAS=${PFX_OVERRIDE}llvm-as"
		else
			if [[ $DISABLE_IAS == "1" ]]; then
				MAKEOPTS="CC=clang CLANG_TRIPLE=$TRIPLE LD=${PFX_OVERRIDE}ld.lld AR=${PFX_OVERRIDE}llvm-ar NM=${PFX_OVERRIDE}llvm-nm STRIP=${PFX_OVERRIDE}llvm-strip
							OBJCOPY=${PFX_OVERRIDE}llvm-objcopy OBJDUMP=${PFX_OVERRIDE}llvm-objdump READELF=${PFX_OVERRIDE}llvm-readelf
							HOSTAR=${PFX_OVERRIDE}llvm-ar HOSTLD=${PFX_OVERRIDE}ld.lld"
			else
				if [[ $DISABLE_LLD_IAS == "1" ]]; then
					MAKEOPTS="CC=clang CLANG_TRIPLE=$TRIPLE AR=${PFX_OVERRIDE}llvm-ar NM=${PFX_OVERRIDE}llvm-nm STRIP=${PFX_OVERRIDE}llvm-strip
								OBJCOPY=${PFX_OVERRIDE}llvm-objcopy OBJDUMP=${PFX_OVERRIDE}llvm-objdump READELF=${PFX_OVERRIDE}llvm-readelf
								HOSTAR=${PFX_OVERRIDE}llvm-ar"
				fi
			fi
		fi
	else
		TRIPLE="$TC/bin/aarch64-linux-gnu-"

		PFX_OVERRIDE="${TRIPLE%/*}/"

		MAKEOPTS="CONFIG_TOOLS_SUPPORT_RELR=n CONFIG_RELR=n CLANG_TRIPLE=$TRIPLE CC=clang LD=${PFX_OVERRIDE}ld.lld"

		if [[ $DISABLE_LLD == "1" ]]; then
			MAKEOPTS="CONFIG_TOOLS_SUPPORT_RELR=n CONFIG_RELR=n CLANG_TRIPLE=$TRIPLE CC=clang"
		fi
	fi

}

get_aosp_clang-r416183c() {

	get_gcc-4.9-aosp

	TC="$TOOLCHAIN_DIR/aosp-clang-r416183c"

	if [ ! -d "$TC/bin" ]; then
		mkdir -p "$TC"
		(
			cd "$TC"
			if [ ! -f "clang-r416183c.tar.gz" ]; then
				run "wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-r416183c.tar.gz &> /dev/null"
				run "tar -xf clang-r416183c.tar.gz -C . &> /dev/null"
			fi
		)
	fi

	TRIPLE="$TC/bin/aarch64-linux-gnu-"

	PFX_OVERRIDE="${TRIPLE%/*}/"

	MAKEOPTS="CONFIG_TOOLS_SUPPORT_RELR=n CONFIG_RELR=n CLANG_TRIPLE=$TRIPLE CC=clang LD=${PFX_OVERRIDE}ld.lld"

	if [[ $DISABLE_LLD == "1" ]]; then
		MAKEOPTS="CONFIG_TOOLS_SUPPORT_RELR=n CONFIG_RELR=n CLANG_TRIPLE=$TRIPLE CC=clang"
	fi

}

make_dtboimg() {

	(
		cd "$OUT_BOOT_DIR"
		[ ! -d "$UFDT_DIR" ] && git clone --depth=1 --single-branch "$UFDT_SRC" "$UFDT_DIR"
		chmod +x "$UFDT_DIR"/utils/src/mkdtboimg.py
		echo -e "\nMaking dtbo.img..."
		echo -e "\npython3 $UFDT_DIR/utils/src/mkdtboimg.py $(echo "$UFDT_ARGS")"
		python3 "$UFDT_DIR"/utils/src/mkdtboimg.py $(echo "$UFDT_ARGS")
		echo -e "\nDone."
	)

}

make_dtimg() {

	[ ! -d "$DTBTOOL_DIR" ] && wget -q "$DTBTOOL_SRC" -O "$DTBTOOL_DIR"/dtbtool.c
	cc "$DTBTOOL_DIR"/dtbtool.c -o "$OUT_BOOT_DIR"/dts

	(
		cd "$OUT_BOOT_DIR"/dts
		echo -e "\nMaking dt.img using dtbtool..."
		echo -e "\ndtbtool $(echo "$DTBTOOL_ARGS")"
		dtbtool $(echo "$DTBTOOL_ARGS")
		echo -e "\nDone."
	)

}

regen() {
	SRC="$KERNEL_ROOT_DIR/out/.config"
	DST="$KERNEL_ROOT_DIR/arch/$TARGET_ARCH/configs/$KERNEL_CONFIG"
	diff --new-line-format="%L" --old-line-format="" --unchanged-line-format="" "$SRC" "$DST"
	cp "$SRC" "$DST" && exit
}

build() {

	echo -e "\nApplying Temp YYLLOC Workarounds..."
	YYLL1="$KERNEL_ROOT_DIR/scripts/dtc/dtc-lexer.lex.c_shipped"
	YYLL2="$KERNEL_ROOT_DIR/scripts/dtc/dtc-lexer.l"
	[ -f "$YYLL1" ] && sed -i "s/extern YYLTYPE yylloc/YYLTYPE yylloc/g;s/YYLTYPE yylloc/extern YYLTYPE yylloc/g" "$YYLL1"
	[ -f "$YYLL2" ] && sed -i "s/extern YYLTYPE yylloc/YYLTYPE yylloc/g;s/YYLTYPE yylloc/extern YYLTYPE yylloc/g" "$YYLL2"
	echo -e "\nDone."

	case $TOOLCHAIN in
		1) echo -e "\nSelecting GCC-4.9...\n" && get_gcc-4.9 ;;
		2) echo -e "\nSelecting EVA-GCC-12.0...\n" && get_eva_gcc-12.0 ;;
		3) echo -e "\nSelecting PROTON-CLANG-13.0...\n" && get_proton_clang-13.0 ;;
		4) echo -e "\nSelecting SDCLANG-12.1...\n" && get_sdclang-12.1 ;;
		5) echo -e "\nSelecting AOSP-CLANG-R416183c...\n" && get_aosp_clang-r416183c ;;
		6) echo -e "\nSelecting AOSPA-GCC-10.2...\n" && get_aospa_gcc-10.2 ;;
		7) echo -e "\nSelecting ARTER-GCC...\n" && get_arter-gcc ;;
	esac

	if [[ $TARGET_ARCH = "arm" ]]; then
		CROSS_COMPILE=$CROSS_ARM32
	else
		CROSS_COMPILE=$CROSS
	fi

	CROSS_COMPILE_ARM32=$CROSS_ARM32

	if [[ $IS_WSL_USER == "1" ]]; then
		WIN_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin"
		PATH="${CROSS_COMPILE%/*}:${CROSS_COMPILE_ARM32%/*}:${WIN_PATH}"
		if [[ $PFX_OVERRIDE != "" ]]; then
			PATH="${CROSS_COMPILE%/*}:${CROSS_COMPILE_ARM32%/*}:${PFX_OVERRIDE%/*}:${WIN_PATH}"
		fi
	else
		PATH="${CROSS_COMPILE%/*}:${CROSS_COMPILE_ARM32%/*}:${PATH}"
		if [[ $PFX_OVERRIDE != "" ]]; then
			PATH="${CROSS_COMPILE%/*}:${CROSS_COMPILE_ARM32%/*}:${PFX_OVERRIDE%/*}:${PATH}"
		fi
	fi

	if [[ ! -f ${TRIPLE%/*}/clang ]]; then
		echo -e "TRIPLE unset. Assuming Bare-Metal...\n"
	else
		echo -e "$( "${TRIPLE%/*}"/clang -v )" && IS_AOSP_CLANG="1" && CHOSEN_CC="clang"
	fi

	if [[ ! -f ${CROSS_COMPILE}gcc ]]; then
		if [[ ! -f ${CROSS_COMPILE%/*}/clang ]]; then
			if [[ $IS_AOSP_CLANG == "1" ]]; then
				echo -e "\nARM64: Detected AOSP Binutils With Clang: ${CROSS_COMPILE}"
			else
				echo -e "\nCROSS_COMPILE not set properly." && exit
			fi
		else
			echo -e "$( "${CROSS_COMPILE%/*}"/clang -v )" && CHOSEN_CC="clang"
		fi
	else
		echo -e "$( "${CROSS_COMPILE}"gcc -v )" && CHOSEN_CC="gcc"
	fi

	if [[ ! -f ${CROSS_COMPILE_ARM32}gcc ]]; then
		if [[ ! -f ${CROSS_COMPILE_ARM32%/*}/clang ]]; then
			if [[ $IS_AOSP_CLANG == "1" ]]; then
				echo -e "\nARM32: Detected AOSP Binutils With Clang: ${CROSS_COMPILE_ARM32}"
			else
				echo -e "\nCROSS_COMPILE_ARM32 not set properly." && exit
			fi
		else
			echo -e "$( "${CROSS_COMPILE_ARM32%/*}"/clang -v )" && CHOSEN_CC="clang"
		fi
	else
		echo -e "$( "${CROSS_COMPILE_ARM32}"gcc -v )" && CHOSEN_CC="gcc"
	fi

	if [ -d out ]; then
			rm -rf out
	else
			mkdir -p out
	fi

	BUILD_START=$(date +"%s")

	MAKEOPTS="CONFIG_DEBUG_SECTION_MISMATCH=y $MAKEOPTS"
	if [[ $BUILD_DTBO_IMG == "1" || ${1} == "dtbs"  ]]; then
		MAKEOPTS="CONFIG_BUILD_ARM64_DT_OVERLAY=y $MAKEOPTS"
	fi

	run "PATH=$PATH CROSS_COMPILE=$CROSS_COMPILE CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 make $(echo -e $MAKEOPTS) O=out ARCH=$TARGET_ARCH $KERNEL_CONFIG || exit"
	[[ ${1} == "regen" ]] && regen

	if [[ $BUILD_MODULES == "1" ]]; then
		BUILD_HAS_MODULES=$( [[ $(grep "=m" "$KERNEL_ROOT_DIR"/out/.config | wc -c) -gt 0 ]] && echo 1 )
		if [[ $BUILD_HAS_MODULES == "1" ]]; then
			echo -e "\nHAS MODULES: $BUILD_HAS_MODULES"
		else
			echo -e "\nHAS MODULES: $BUILD_HAS_MODULES"
		fi
	fi

	if [[ $BUILD_DTBO_IMG == "1" || ${1} == "dtbs"  ]]; then
		BUILD_HAS_DTBO=$( [[ $(grep "DT_OVERLAY=y" "$KERNEL_ROOT_DIR"/out/.config | wc -c) -gt 0 ]] && echo 1 )

	else
		BUILD_HAS_DTBO="0"
	fi

	if [[ $BUILD_HAS_DTBO == "1" ]]; then
		echo -e "\nHAS DTBO: $BUILD_HAS_DTBO"
	else
		echo -e "\nHAS DTBO: $BUILD_HAS_DTBO"
	fi

	if [[ $DTC_EXT_FOR_DTC == "1" ]]; then
		DTC_EXT="$(which dtc) -q"
		DTC_FLAGS="-q"
		echo -e "\nUsing $DTC_EXT $DTC_FLAGS for DTC...\n"
		export DTC_EXT DTC_FLAGS
	fi

	if [[ $ENABLE_CCACHE == "1" ]]; then
		[[ "${CHOSEN_CC}" == "clang" ]] && NEW_CC="ccache clang" || NEW_CC="ccache ${CROSS_COMPILE}${CHOSEN_CC}"
		echo -e "\nNEW_CC: ${NEW_CC}"
	else
		[[ "${CHOSEN_CC}" == "clang" ]] && NEW_CC="clang" || NEW_CC="${CROSS_COMPILE}${CHOSEN_CC}"
		echo -e "\nNEW_CC: ${NEW_CC}"
	fi

	if [[ ${1} != "" && ${1} == "dtbs" ]]; then
		run "PATH=$PATH CROSS_COMPILE=$CROSS_COMPILE CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 make $(echo -e $MAKEOPTS) O=out ARCH=$TARGET_ARCH CC=\"${NEW_CC}\" dtbs || exit"
		if [[ $BUILD_HAS_DTBO == "1" ]]; then
			make_dtboimg
		fi
				echo -e "\nCopying dtb..."
				  cat $DTB_DTBO_DIR/*.dtb  > $OUT_BOOT_DIR/dt.img 
		exit
	fi

	run "PATH=$PATH CROSS_COMPILE=$CROSS_COMPILE CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 make $(echo -e $MAKEOPTS) O=out ARCH=$TARGET_ARCH CC=\"${NEW_CC}\" -j$(($(nproc))) || exit"

	if [[ $BUILD_HAS_DTBO == "1" ]]; then
		make_dtboimg
	fi

	if [[ $BUILD_MODULES == "1" ]]; then
		if [[ $BUILD_HAS_MODULES == "1" ]]; then
			if [ -d "$BUILD_MODULES_DIR" ]; then
					rm -rf "$BUILD_MODULES_DIR"
			else
					mkdir -p "$BUILD_MODULES_DIR"
			fi
			run "PATH=$PATH CROSS_COMPILE=$CROSS_COMPILE CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 make $(echo -e $MAKEOPTS) O=out ARCH=$TARGET_ARCH INSTALL_MOD_PATH=\"$BUILD_MODULES_DIR\" INSTALL_MOD_STRIP=1 modules_install || exit"
		fi
	fi

	[ -d "$KERNEL_ROOT_DIR"/.git ] && git restore "$YYLL1" "$YYLL2"

	DIFF=$(($(date +"%s") - BUILD_START))
	echo -e "\n\nBuild completed in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds.\n\n"

}

build_zip() {

	[ ! -d "$ANYKERNEL_DIR" ] && git clone --depth=1 --single-branch "$ANYKERNEL_SRC" -b master "$ANYKERNEL_DIR"

	echo -e "\nCleaning Up Old AnyKernel Remnants...\n"
	PRE_FILES="
	Image
	Image-dtb
	Image.gz
	Image.gz-dtb
	dtb
	dtb.img
	dt
	dt.img
	dtbo
	dtbo.img"

	echo "$PRE_FILES" | \
	while read -r f
	do
		if [[ -f $ANYKERNEL_DIR/$f ]]; then
			echo -e "Removing OLD $ANYKERNEL_DIR/$f" && rm "$ANYKERNEL_DIR"/"$f"
		fi
	done
	echo -e "\nDone."

	echo -e "
	# AnyKernel3 Ramdisk Mod Script
	# osm0sis @ xda-developers
	properties() { '
	kernel.string=generic
	device.name1=alioth
	do.devicecheck=1
	do.modules=0
	do.systemless=0
	do.cleanup=1
	do.cleanuponabort=0
	'; }
	block=boot;
	is_slot_device=1;
	ramdisk_compression=auto;
	. tools/ak3-core.sh;
	set_perm_recursive 0 0 755 644 \$ramdisk/*;
	set_perm_recursive 0 0 750 750 \$ramdisk/init* \$ramdisk/sbin;
	dump_boot;
	if [ -d \$ramdisk/overlay ]; then
		rm -rf \$ramdisk/overlay;
	fi;
	# patch_cmdline firmware_class.path firmware_class.path=/vendor/firmware_mnt/image
	# patch_cmdline androidboot.selinux androidboot.selinux=permissive
	# patch_cmdline ramoops_memreserve ramoops_memreserve=8M
	write_boot;
	" > "$ANYKERNEL_DIR"/anykernel.sh

	if [[ $BUILD_MODULES == "1" ]]; then
		BUILD_HAS_MODULES=$( [[ $(grep "=m" "$KERNEL_ROOT_DIR"/out/.config | wc -c) -gt 0 ]] && echo 1 )
		if [[ $BUILD_HAS_MODULES == "1" ]]; then
			sed -i "s/do.modules=0/do.modules=1/g" "$ANYKERNEL_DIR"/anykernel.sh
		fi
	fi

	if [[ $DO_SYSTEMLESS == "1" ]]; then
		sed -i "s/do.systemless=0/do.systemless=1/g" "$ANYKERNEL_DIR"/anykernel.sh
	fi

	if [[ $PATCH_PERMISSIVE == "1" ]]; then
		sed -i "s/# patch_cmdline androidboot.selinux/patch_cmdline androidboot.selinux/g" "$ANYKERNEL_DIR"/anykernel.sh
	fi

	if [[ $PATCH_CLASSPATH == "1" ]]; then
		sed -i "s/# patch_cmdline firmware_class.path/patch_cmdline firmware_class.path/g" "$ANYKERNEL_DIR"/anykernel.sh
	fi

	if [[ $RAMOOPS_MEMRESERVE == "1" ]]; then
		sed -i "s/# patch_cmdline ramoops_memreserve/patch_cmdline ramoops_memreserve/g" "$ANYKERNEL_DIR"/anykernel.sh
	fi

	sed -i "s/kernel.string=generic/kernel.string=$ZIP_KERNEL_STR/g" "$ANYKERNEL_DIR"/anykernel.sh
	sed -i "s/device.name1=generic/device.name1=$ZIP_DEVICE_NAME/g" "$ANYKERNEL_DIR"/anykernel.sh

	chmod +x "$ANYKERNEL_DIR"/anykernel.sh

	(
		echo -e "\nZipping...\n"

		cd "$ANYKERNEL_DIR"

		if [[ ! -f $OUT_BOOT_DIR/Image.gz-dtb ]]; then
			if [[ ! -f $OUT_BOOT_DIR/Image.gz ]]; then
				if [[ ! -f $OUT_BOOT_DIR/Image-dtb ]]; then
					if [[ ! -f $OUT_BOOT_DIR/Image ]]; then
						echo -e "\nNo kernels found. Exiting..." && exit
					else
						cp "$OUT_BOOT_DIR"/Image "$ANYKERNEL_DIR"
					fi
				else
					cp "$OUT_BOOT_DIR"/Image-dtb "$ANYKERNEL_DIR"
				fi
			else
				cp "$OUT_BOOT_DIR"/Image.gz "$ANYKERNEL_DIR" && make_dtimg
			fi
		else
			if [[ "$USE_UNCOMPRESSED_KERNEL" != "1" ]]; then
					cp "$OUT_BOOT_DIR"/Image.gz-dtb "$ANYKERNEL_DIR"
			else
					cp "$OUT_BOOT_DIR"/Image "$ANYKERNEL_DIR"
			fi
		fi

		if [[ ! -f $OUT_BOOT_DIR/dtbo.img ]]; then
			if [[ ! -f $OUT_BOOT_DIR/dt.img ]]; then
				echo -e "\nUsing appended dtb..."
			else
			     cat $DTB_DTBO_DIR/*.dtb  > $ANYKERNEL_DIR/dt.img
			fi
		else
			cp "$OUT_BOOT_DIR"/dtbo.img "$ANYKERNEL_DIR"
		fi

				echo -e "\nCopying dtb..."
				cat $DTB_DTBO_DIR/*.dtb  > $ANYKERNEL_DIR/dt.img

		ZIP_PREFIX_KVER=$(grep Linux "$KERNEL_ROOT_DIR"/out/.config | cut -f 3 -d " ")
		ZIP_POSTFIX_DATE=$(date +%d-%h-%Y-%R:%S | sed "s/:/./g")

		if [[ $BUILD_MODULES == "1" ]]; then
			BUILD_HAS_MODULES=$( [[ $(grep "=m" "$KERNEL_ROOT_DIR"/out/.config | wc -c) -gt 0 ]] && echo 1 )
		fi

		if [[ $BUILD_HAS_MODULES == "1" ]]; then
			MOD_DIR="$ANYKERNEL_DIR"/modules/system/lib/modules
			K_MOD_DIR="$KERNEL_ROOT_DIR"/out/modules
			[ -d "$MOD_DIR" ] && rm -rf "$MOD_DIR" && mkdir -p "$MOD_DIR"
			[ ! -d "$K_MOD_DIR" ] && mkdir -p "$K_MOD_DIR"
			find "$K_MOD_DIR" -type f -iname "*.ko" -exec cp {} "$MOD_DIR" \;
			zip -r9 ${ZIP_PREFIX_STR}_"${ZIP_PREFIX_KVER}"_"${ZIP_POSTFIX_DATE}".zip . -x '*.git*' '*patch*' '*ramdisk*' 'LICENSE' 'README.md'
		else
			zip -r9 ${ZIP_PREFIX_STR}_"${ZIP_PREFIX_KVER}"_"${ZIP_POSTFIX_DATE}".zip . -x '*.git*' '*modules*' '*patch*' '*ramdisk*' 'LICENSE' 'README.md'
		fi

		[[ $(find "$KERNEL_ROOT_DIR"/out -maxdepth 1 -type f -iname "*.zip") ]] && rm "$KERNEL_ROOT_DIR"/out/*.zip
		mv ./*.zip "$KERNEL_ROOT_DIR"/out

		echo -e "\nDone."
		echo -e "\n$(md5sum "$KERNEL_ROOT_DIR"/out/*.zip)"
	)

}

upload_zip() {
	curl bashupload.com -T "$(ls -1 "$KERNEL_ROOT_DIR"/out/*.zip)"
	str=$(
		for f in $(ls -1 "$KERNEL_ROOT_DIR"/out/*.zip); do
			echo "-F f[]=@${f}"
		done
	)
	curl -i "$str" https://oshi.at
}

case "${1}" in
	"build")
		build ;;
	"zip")
		build_zip ;;
	"upload")
		upload_zip ;;
	"dtboimg")
		make_dtboimg ;;
	"regen")
		build "${1}" && regen ;;
	*)
		build "${1}" && build_zip ;;
esac
