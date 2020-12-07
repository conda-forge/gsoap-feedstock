#!/usr/bin/env bash
set -eu

cd sources

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

autoconf

declare -a MAKE_FLAGS

if [[ "${CONDA_BUILD_CROSS_COMPILATION-}" == "1" ]]; then
    # Build soapcpp2 for the host so it can be used during the build
    mkdir -p "${SRC_DIR}"
    cp -rp "${SRC_DIR}/sources" "${SRC_DIR}/sources-for-host"
    cd "${SRC_DIR}/sources-for-host"
    export CC_FOR_TARGET=$CC
    export CC=$CC_FOR_BUILD
    export CXX_FOR_TARGET=$CXX
    export CXX=$CXX_FOR_BUILD
    ./configure \
        --prefix="${BUILD_PREFIX}" \
        --with-openssl="${BUILD_PREFIX}/" \
        --with-zlib="${BUILD_PREFIX}/" \
        --enable-ipv6 \
        --host="${BUILD}"
    make -j1
    cd "${SRC_DIR}/sources"
    export CC=$CC_FOR_TARGET
    export CXX=$CXX_FOR_TARGET
    MAKE_FLAGS+=( SOAP="${SRC_DIR}/sources-for-host/gsoap/src/soapcpp2" )
fi

./configure \
    --prefix="${PREFIX}" \
    --with-openssl="${PREFIX}/" \
    --with-zlib="${PREFIX}/" \
    --enable-ipv6

# Using multiple cores fails so explicitly use -j1
make -j1 "${MAKE_FLAGS[@]}"
# make -j${CPU_COUNT}
make install
