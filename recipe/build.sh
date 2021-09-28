#!/usr/bin/env bash
set -eux

cd sources

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

autoreconf --install --force

declare -a MAKE_FLAGS

if [[ "${CONDA_BUILD_CROSS_COMPILATION-}" == "1" ]]; then
    # Build soapcpp2 for the host so it can be used during the build
    mkdir -p "${SRC_DIR}"
    cp -rp "${SRC_DIR}/sources" "${SRC_DIR}/sources-for-host"
    cd "${SRC_DIR}/sources-for-host"

    export CC_FOR_TARGET=$CC
    export CC=$CC_FOR_BUILD
    export CFLAGS_FOR_TARGET=$CFLAGS
    export CFLAGS=${CFLAGS//${PREFIX}/${BUILD_PREFIX}}

    export CXX_FOR_TARGET=$CXX
    export CXX=$CXX_FOR_BUILD
    export CXXFLAGS_FOR_TARGET=$CXXFLAGS
    export CXXFLAGS=${CXXFLAGS//${PREFIX}/${BUILD_PREFIX}}

    export LDFLAGS_FOR_TARGET=$LDFLAGS
    export LDFLAGS=${LDFLAGS//${PREFIX}/${BUILD_PREFIX}}

    ./configure \
        --prefix="${BUILD_PREFIX}" \
        --with-openssl="${BUILD_PREFIX}/" \
        --with-zlib="${BUILD_PREFIX}/" \
        --enable-ipv6 \
        --host="${BUILD}"
    make -j1
    cd "${SRC_DIR}/sources"
    export CC=$CC_FOR_TARGET
    export CFLAGS=$CFLAGS_FOR_TARGET
    export CXX=$CXX_FOR_TARGET
    export CXXFLAGS=$CXXFLAGS_FOR_TARGET
    export LDFLAGS=$LDFLAGS_FOR_TARGET
    MAKE_FLAGS+=( SOAP="${SRC_DIR}/sources-for-host/gsoap/src/soapcpp2" )
fi

./configure \
    --prefix="${PREFIX}" \
    --with-openssl="${PREFIX}/" \
    --with-zlib="${PREFIX}/" \
    --enable-ipv6

# Using multiple cores fails so explicitly use -j1
make -j1 ${MAKE_FLAGS[@]+"${MAKE_FLAGS[@]}"}

make install

rm "${PREFIX}/lib"/libgsoap*.a
