#!/usr/bin/env bash
set -eu

# These are needed to fix building with C++ 11 support
sed -i 's@"FMT"@" FMT "@g' gsoap/Makefile.in
sed -i 's@"VERSION"@" VERSION "@g' gsoap/wsdl/wsdl2h.cpp
sed -i 's@"VERSION"@" VERSION "@g' gsoap/wsdl/service.cpp

# patches change autoconf and automake files, so we must reconfigure
autoreconf --install --force

# enable IPv6 support
sed 's/Cflags:/& -DWITH_IPV6/' -i gsoap*.pc.in
CFLAGS="-DWITH_IPV6 ${CFLAGS}"
CXXFLAGS="-DWITH_IPV6 ${CXXFLAGS}"

./configure \
    --prefix="${PREFIX}" \
    --disable-shared

# Using multiple cores fails so explicitly use -j1
make -j1
make install
