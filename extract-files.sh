#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

VENDOR=samsung
DEVICE=zeroltexx

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi


# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

# Fix proprietary blobs
BLOB_ROOT="$ANDROID_ROOT"/vendor/"$VENDOR"/"$DEVICE"/proprietary

# hidlbase legacy hack
"${PATCHELF}" --replace-needed libhidlbase.so libhidlbase-v32.so $BLOB_ROOT/vendor/lib64/vendor.samsung.security.skeymaster@3.0.so

"${PATCHELF}" --replace-needed libgui.so libsensor.so $BLOB_ROOT/bin/gpsd
"${PATCHELF}" --replace-needed libprotobuf-cpp-full.so libprotobuf-cpp-fl24.so $BLOB_ROOT/vendor/lib/libsec-ril.so
sed -i "s/libprotobuf-cpp-full/libprotobuf-cpp-fl24/" $BLOB_ROOT/vendor/lib64/libsec-ril.so
"${PATCHELF}" --replace-needed libprotobuf-cpp-full.so libprotobuf-cpp-fl24.so $BLOB_ROOT/vendor/lib/libsec-ril-dsds.so
sed -i "s/libprotobuf-cpp-full/libprotobuf-cpp-fl24/" $BLOB_ROOT/vendor/lib64/libsec-ril-dsds.so

"${PATCHELF}" --remove-needed vendor.samsung.hardware.nfc@1.0.so $BLOB_ROOT/vendor/lib/hw/nfc_nci.default.so
"${PATCHELF}" --remove-needed vendor.samsung.hardware.nfc@1.0.so $BLOB_ROOT/vendor/lib64/hw/nfc_nci.default.so
sed -i "s/\/system\/app/\/vendor\/app/g" $BLOB_ROOT/vendor/bin/mcDriverDaemon

"${MY_DIR}/setup-makefiles.sh"
