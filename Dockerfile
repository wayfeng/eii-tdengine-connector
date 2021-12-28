# Dockerfile for TDengineConnector

ARG EII_VERSION
ARG UBUNTU_IMAGE_VERSION
ARG ARTIFACTS="/artifacts"
FROM ia_common:${EII_VERSION} as common
FROM ia_eiibase:${EII_VERSION} as builder
LABEL description="TDengineConnector image"
WORKDIR /root
ADD . /root
RUN dpkg -i TDengine-server-2.3.5.0-beta-Linux-x64.deb

WORKDIR ${GOPATH}/src/IEdgeInsights
ARG CMAKE_INSTALL_PREFIX
ENV CMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
COPY --from=common ${CMAKE_INSTALL_PREFIX}/include ${CMAKE_INSTALL_PREFIX}/include
COPY --from=common ${CMAKE_INSTALL_PREFIX}/lib ${CMAKE_INSTALL_PREFIX}/lib
COPY --from=common /eii/common/util/influxdb common/util/influxdb
COPY --from=common /eii/common/util/util.go common/util/util.go
COPY --from=common ${GOPATH}/src ${GOPATH}/src
COPY --from=common /eii/common/libs/EIIMessageBus/go/EIIMessageBus $GOPATH/src/EIIMessageBus
COPY --from=common /eii/common/libs/ConfigMgr/go/ConfigMgr $GOPATH/src/ConfigMgr
RUN mkdir TDengineConnector
RUN cp /root/TDengineConnector.go ./TDengineConnector


ENV PATH="$PATH:/usr/local/go/bin" \
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH:${CMAKE_INSTALL_PREFIX}/lib/pkgconfig" \
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${CMAKE_INSTALL_PREFIX}/lib"

ENV CGO_CFLAGS="$CGO_FLAGS -I ${CMAKE_INSTALL_PREFIX}/include -O2 -D_FORTIFY_SOURCE=2 -Werror=format-security -fstack-protector-strong -fPIC" \
    CGO_LDFLAGS="$CGO_LDFLAGS -L${CMAKE_INSTALL_PREFIX}/lib -z noexecstack -z relro -z now"

ARG ARTIFACTS
RUN mkdir $ARTIFACTS && \
    go build -o $ARTIFACTS/TDengineConnector TDengineConnector/TDengineConnector.go

WORKDIR /root
RUN cp $ARTIFACTS/TDengineConnector .

EXPOSE 6030-6042/tcp 
EXPOSE 6030-6042/udp 
ENTRYPOINT ["./startup.sh"]
