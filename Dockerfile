# Dockerfile
#
FROM ubuntu:22.04

LABEL name="docker-arm-toolchain"
LABEL vendor="E8A81L R080T1X"
LABEL maintainer="E8A81L R080T1X"
LABEL summary="Ubuntu Linux based gcc-arm-none-eabi (13.2.1-1.1) toolchain with CMake and this utils."

ENV DEBIAN_FRONTEND=noninteractive

ARG INSTALL_PATH=/opt

ARG TOOLCHAIN_URL=https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/download/v13.2.1-1.1/xpack-arm-none-eabi-gcc-13.2.1-1.1-linux-x64.tar.gz
ARG TOOLCHAIN_NAME=xpack-arm-none-eabi-gcc-13.2.1-1.1

COPY ./tools/* ${INSTALL_PATH}/tools

RUN chmod -R 777 ${INSTALL_PATH}/tools

# Set timezone environment and 
# install development support tools.
ENV TZ=Europe/Berlin
COPY ./docker/apt-packages.lst .
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    apt-get update && \
    apt-get install --no-install-recommends -y $(sed 's/#.*$//' ./apt-packages.lst | tr '\n' ' ') && \
    apt autoremove -y && \
    apt clean -y && \
    rm -rf /var/cache/apt /var/lib/apt/lists/*

# Install the toolchain.
RUN wget -O ${TOOLCHAIN_NAME}.tar.gz ${TOOLCHAIN_URL} \
    && tar xf ${TOOLCHAIN_NAME}.tar.gz -C ${INSTALL_PATH} \
    && rm ${TOOLCHAIN_NAME}.tar.gz

# Add toolchain to PATH.
ENV PATH="${INSTALL_PATH}/${TOOLCHAIN_NAME}/bin:${INSTALL_PATH}/tools:${PATH}"

# Disable git safe directory feature,
# because we want to allow different directory owners.
RUN git config --global --add safe.directory '*'

# Set up a build working directory.
RUN mkdir /build
WORKDIR /build

# Install pip packages as root (so all users can use them).
ENV PIP_ROOT_USER_ACTION=ignore
RUN pip install --upgrade pip
