#******************************************************************************
#*** HS build enivronment
#******************************************************************************

if [ -z "${HSB_TARGET}" ]; then
    echo "HSB_TARGET not specified"
    exit 1
fi

case ${HSB_TARGET} in
    arm-*)
        HSB_TARGET_CPU=arm
    ;;
    i*86-*|armsim-darwin)
        HSB_TARGET_CPU=i386
    ;;
    x86_64-*)
        HSB_TARGET_CPU=x86_64
    ;;
    # if we want to support universal binaries for darwin,
    # we might add a special case or similar here in the future.
    *)
        echo "HSB_TARGET [$HSB_TARGET]: Unsupported CPU"
        exit 1
    ;;
esac
case ${HSB_TARGET} in
    *-darwin*)
        HSB_TARGET_OS=darwin
    ;;
    *-android*)
        HSB_TARGET_OS=android
        if [ -z "$ANDROID_TOOLCHAIN_ROOT" ]; then
          echo "ERROR: ANDROID_TOOLCHAIN_ROOT must be set"
          exit 1
        fi
    ;;
    *-linux*)
        HSB_TARGET_OS=linux
    ;;
    *)
        echo "HSB_TARGET [$HSB_TARGET]: Unsupported Operating System"
        exit 1
    ;;
esac
export HSB_TARGET_CPU
export HSB_TARGET_OS

#------------------------------------------------------------------------------
# Build tools flags
#------------------------------------------------------------------------------

CPPFLAGS=""
CFLAGS=""
CXXFLAGS=""
LDFLAGS=""
OBJCFLAGS=""
ACLOCAL_FLAGS=""

#******************************************************************************
# -------====< CPU architecture >====--------
#******************************************************************************
case ${HSB_TARGET_CPU} in
    i386)
        CFLAGS="-m32"
        LDFLAGS="-m32"
    ;;
    x86_64)
        CFLAGS="-m64"
        LDFLAGS="-m64"
    ;;
    arm)
        CFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=softfp -fsigned-char"
        LDFLAGS="-march=armv7-a"
    ;;
esac
CXXFLAGS="${CFLAGS}"

#******************************************************************************
# -------====< Operating System >====--------
#******************************************************************************
case ${HSB_TARGET} in
    *-darwin)
        case ${HSB_TARGET_CPU} in
            arm)
                DARWIN_MINVER="4.0"
                DARWIN_MINVER_FLAG="iphoneos-version-min"
                DARWIN_ARCH="-arch armv7"
                export DEVROOT="/Developer/Platforms/iPhoneOS.platform/Developer"
                export SDKROOT="${DEVROOT}/SDKs/iPhoneOS5.0.sdk"
                export IPHONEOS_DEPLOYMENT_TARGET=${DARWIN_MINVER}
            ;;
            armsim)
                DARWIN_MINVER="4.0"
                DARWIN_MINVER_FLAG="iphoneos-version-min"
                DARWIN_ARCH=""
                export DEVROOT="/Developer/Platforms/iPhoneSimulator.platform/Developer"
                export SDKROOT="${DEVROOT}/SDKs/iPhoneSimulator5.0.sdk"
                export IPHONEOS_DEPLOYMENT_TARGET=${DARWIN_MINVER}
            ;;
            *)
                DARWIN_MINVER="10.6"
                DARWIN_MINVER_FLAG="macosx-version-min"
                DARWIN_ARCH=""
                export DEVROOT=""
                export SDKROOT="/Developer/SDKs/MacOSX10.7.sdk"
                export MACOSX_DEPLOYMENT_TARGET=${DARWIN_MINVER}
            ;;
        esac

        PKG_CONFIG_LIBDIR="${SDKROOT}/usr/lib/pkgconfig"
        export PATH="${DEVROOT}/usr/bin:${PATH}"

        CPPFLAGS="${DARWIN_ARCH} ${CPPFLAGS} -isysroot ${SDKROOT} -m${DARWIN_MINVER_FLAG}=${DARWIN_MINVER}"
        CFLAGS="${DARWIN_ARCH} ${CFLAGS} -isysroot ${SDKROOT} -m${DARWIN_MINVER_FLAG}=${DARWIN_MINVER}"
        LDFLAGS="${DARWIN_ARCH} ${LDFLAGS} -Wl,-syslibroot,${SDKROOT} -Wl,-$(echo ${DARWIN_MINVER_FLAG} | tr '-' '_'),${DARWIN_MINVER}"

        LDFLAGS="${LDFLAGS} -Wl,-dead_strip -Wl,-headerpad_max_install_names" #-Wl,-no-undefined
    ;;
    *-linux)
        PKG_CONFIG_LIBDIR="/usr/lib/pkgconfig:/usr/share/pkgconfig"

        export CFLAGS="${CFLAGS} -ffunction-sections -fdata-sections"
        export LDFLAGS="${LDFLAGS} -Wl,--gc-sections"
    ;;
    *-android)
        export ANDROID_SYSROOT="${ANDROID_TOOLCHAIN_ROOT}/sysroot"

        export PATH="${ANDROID_TOOLCHAIN_ROOT}/bin:${PATH}"
        export CPPFLAGS="${CPPFLAGS} --sysroot=${ANDROID_SYSROOT}"
        export CFLAGS="${CFLAGS} -ffunction-sections -fdata-sections"
        export LDFLAGS="--sysroot=${ANDROID_SYSROOT} ${LDFLAGS} -Wl,--gc-sections"
    ;;
    *)
        echo "HSB_TARGET [$HSB_TARGET]: Unsupported target"
        exit 1
    ;;
esac

[ -z "${CXXFLAGS}" ] && CXXFLAGS="${CFLAGS}"
[ -z "${OBJCFLAGS}" ] && OBJCFLAGS="${CFLAGS}"
export CPPFLAGS
export CFLAGS
export CXXFLAGS
export OBJCFLAGS
export LDFLAGS

#------------------------------------------------------------------------------
# Global environment variables
#------------------------------------------------------------------------------
export HSB_BUILD="$(pwd)"
[ -z "${HSB_OUTPUT}" ] && export HSB_OUTPUT="$(dirname ${HSB_BUILD})/hsbprefix"
export HSB_PREFIX="${HSB_OUTPUT}/${HSB_TARGET}"
export HSB_TOOLCHAIN="${HSB_BUILD}/toolchain"


build_os=$(uname -s | tr '[A-Z]' '[a-z]')

case $build_os in
  linux)
    download_command="wget -O - -nv"
    tar_stdin=""
    ;;
  darwin)
    download_command="curl -sS"
    tar_stdin="-"

    build_os=osx
    ;;
  *)
    echo "Could not determine build OS"
    exit 1
esac

export PATH="${HSB_TOOLCHAIN}/bin:${HSB_PREFIX}/bin:${PATH}"

#------------------------------------------------------------------------------
# Shell
#------------------------------------------------------------------------------
color=33
export CLICOLOR=1
export PS1="[ \[\e[0;36m\]\d \t\[\e[m\]  \[\e[0;${color}m\]Target\[\e[m\]:\[\e[1;${color}m\]${HSB_TARGET}\[\e[m\]  \[\e[0;31m\]\u\[\e[m\]@\[\e[1;34m\]\h\[\e[m\]:\[\e[0;32m\]\w\[\e[m\] ] \$ "

#------------------------------------------------------------------------------
# Autoconf
#------------------------------------------------------------------------------
export CONFIG_SITE="${HSB_BUILD}/config.site"

#------------------------------------------------------------------------------
# ACLOCAL
#------------------------------------------------------------------------------
#[ ! -d "${HSB_PREFIX}/share/aclocal}" ] && mkdir -p "${HSB_PREFIX}/share/aclocal"
export ACLOCAL_FLAGS="-I ${HSB_TOOLCHAIN}/share/aclocal"
export ACLOCAL="${HSB_TOOLCHAIN}/bin/aclocal ${ACLOCAL_FLAGS}"

#------------------------------------------------------------------------------
# PkgConfig
#------------------------------------------------------------------------------
#[ ! -d "${HSB_PREFIX}/lib/pkgconfig}" ] && mkdir -p "${HSB_PREFIX}/lib/pkgconfig"
if [ -z "${PKG_CONFIG_LIBDIR}" ]; then
    export PKG_CONFIG_LIBDIR="${HSB_PREFIX}/lib/pkgconfig"
else
    export PKG_CONFIG_LIBDIR="${HSB_PREFIX}/lib/pkgconfig:${PKG_CONFIG_LIBDIR}"
fi


#------------------------------------------------------------------------------
# Deploy the toolchain
#------------------------------------------------------------------------------
# find all files (recursivly) tc.<name>.in -> <name>
for template in $(find ${HSB_TOOLCHAIN} -name "tc.*.in"); do
  target=$(echo $template | sed 's,\(.*\)\/tc\.\(.*\)\.in,\1/\2,')
  cp -a "$template" "$target"
  sed -e "s,@TOOLROOT@,${HSB_TOOLCHAIN},g" "$template" > "$target"
done

[ ! -h ${HSB_TOOLCHAIN}/bin/m4 ] && ln -s ${HSB_TOOLCHAIN}/bin/${build_os}/m4 ${HSB_TOOLCHAIN}/bin/m4
[ ! -h ${HSB_TOOLCHAIN}/bin/pkg-config ] && ln -s ${HSB_TOOLCHAIN}/bin/${build_os}/pkg-config ${HSB_TOOLCHAIN}/bin/pkg-config
