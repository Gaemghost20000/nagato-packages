# ==============================================================================
# properties.sh Patch Specification for Nagato (com.nagato.agent)
# ==============================================================================
#
# This document specifies the exact lines in nagato-packages/scripts/properties.sh
# that must be changed to support the com.nagato.agent package name.
#
# IMPORTANT: Only change variables EXPLICITLY listed as safe by upstream Termux:
# https://github.com/termux/termux-packages/blob/master/scripts/properties.sh
#
# ==============================================================================

## Safe Variables to Modify

These variables have been verified as safe to change per upstream docs:

TERMUX_APP__PACKAGE_NAME="com.nagato.agent"
TERMUX_APP__DATA_DIR="/data/data/com.nagato.agent"
TERMUX__NAME="Nagato"
TERMUX__LNAME="nagato"
TERMUX__UNAME="nagato"

## Derived Variables (AUTO-COMPUTED in latest properties.sh)

In modern properties.sh, the following are DERIVED from TERMUX_APP__PACKAGE_NAME
and should NOT be changed directly. If they have hardcoded values, the build
system may use the hardcoded ones instead of the derived ones:

TERMUX_APP__DATA_DIR      -> auto: /data/data/${TERMUX_APP__PACKAGE_NAME}
TERMUX__ROOTFS            -> auto: ${TERMUX_APP__DATA_DIR}/files
TERMUX__PREFIX            -> auto: ${TERMUX__ROOTFS}/usr
TERMUX_ANDROID_HOME       -> auto: ${TERMUX__ROOTFS}/home
TERMUX_APP__NAME          -> auto: derived from TERMUX__NAME

## What NOT to Change

DO NOT modify:
- TERMUX_SDK_REVISION
- TERMUX_ANDROID_BUILD_TOOLS_VERSION
- TERMUX_NDK_VERSION_NUM
- TERMUX_ARCHITECTURES (keep default unless you know why)
- Any regex variables (TERMUX_REGEX_*)
- Any repo/mirror URLs unless you host your own apt mirror

## Verification

After patching, verify with:
    grep "com.termux" scripts/properties.sh | grep -v "TERMUX_REPO"

If any lines remain (outside TERMUX_REPO_* which point to official repos),
those are bugs that will cause runtime failures.

## Apt Repository Reality

Official Termux apt repos serve debs compiled for `com.termux`:
    https://packages-cf.termux.dev/apt/termux-main

If you rebuild the bootstrap with `com.nagato.agent`, `apt install` downloads
official debs which will TRY to extract to `/data/data/com.termux/...` inside
your chroot. They will fail because that path does not exist in your namespace.

Solutions:

1. **Option C (Minimal Bootstrap + Post-Install)** [RECOMMENDED]
   - Bootstrap contains: bash, coreutils, apt, python, termux-exec, termux-keyring
   - Everything else (pip, hermes-agent) installed via script after extraction
   - No custom apt repo needed
   - Tradeoff: ~2-3 minutes first-launch setup

2. **Build Everything from Source**
   - Uses build-bootstraps.sh to build ALL packages into the bootstrap
   - No apt repo needed at runtime
   - Tradeoff: 4-8 hours compute per architecture

3. **Custom Apt Mirror** (Advanced)
   - Rebuild all ~1000 packages with new prefix
   - Host a package mirror compatible with official one
   - Tradeoff: Massive compute and hosting

## Recommended: Option C for MVP

The fastest path to a working APK:

1. Build a bootstrap with just the essential Termux base + Python
2. On first launch, run the auto-setup script:
   pkg install -y python python-pip git curl openssl nodejs
   pip install hermes-agent[web]
   hermes agent &
   hermes webui &
3. The Chat tab shows a progress spinner until localhost:8787 responds.

Bootstrap packages for Option C (add to build script):
    bash, coreutils, apt, dpkg, bzip2, gzip, tar, xz-utils,
    termux-exec, termux-keyring, termux-tools,
    python, python-pip
