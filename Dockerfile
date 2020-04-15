FROM amd64/debian:buster

MAINTAINER Heiko H. from / Andre Germann <https://buanet.de>

ENV DEBIAN_FRONTEND noninteractive

# Install prerequisites
RUN apt-get update && apt-get install -y \
        acl \
        apt-utils \
        build-essential \
        curl \
        git \
        gnupg2 \
	jq \
        libcap2-bin \
        libpam0g-dev \
        libudev-dev \
        locales \
        procps \
        python \
        gosu \
        unzip \
        wget \
	procps \
	pkg-config \
    && rm -rf /var/lib/apt/lists/*
    
      RUN apt-get update && apt-get install -y \
	android-tools-adb \
	android-tools-fastboot \
	bluetooth \
	bluez \
	libbluetooth-dev \
	nano \
	arp-scan \
	udev \
	net-tools \
  && rm -rf /var/lib/apt/lists/* 

# Install node10.xx
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash \
    && apt-get update && apt-get install -y \
        nodejs \
    && rm -rf /var/lib/apt/lists/*

# Generating locales
RUN sed -i 's/^# *\(de_DE.UTF-8\)/\1/' /etc/locale.gen \
	&& sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
	&& locale-gen

# Create scripts directorys and copy scripts
RUN mkdir -p /opt/scripts/ \
        && mkdir -p /opt/userscripts/ \
        && chmod 777 /opt/scripts/ \
        && chmod 777 /opt/userscripts/
    
WORKDIR /opt/scripts/
COPY scripts/iobroker_startup.sh iobroker_startup.sh
COPY scripts/setup_avahi.sh setup_avahi.sh
COPY scripts/setup_packages.sh setup_packages.sh
COPY scripts/setup_zwave.sh setup_zwave.sh
COPY scripts/setcab.sh setcab.sh
RUN chmod +x iobroker_startup.sh \
    && chmod +x setup_avahi.sh \
    && chmod +x setup_packages.sh \
    && chmod +x setup_zwave.sh \
    && chmod +x setcab.sh
    
WORKDIR /opt/userscripts/
COPY scripts/userscript_firststart_example.sh userscript_firststart_example.sh
COPY scripts/userscript_everystart_example.sh userscript_everystart_example.sh
    
# Install ioBroker
WORKDIR /
RUN apt-get update \
    && curl -sL https://raw.githubusercontent.com/ioBroker/ioBroker/stable-installer/installer.sh | bash - \
    && echo $(hostname) > /opt/iobroker/.install_host \
    && echo $(hostname) > /opt/.firstrun \
    && rm -rf /var/lib/apt/lists/*

# Install node-gyp
WORKDIR /opt/iobroker/
RUN npm install -g node-gyp

# Backup initial ioBroker and userscript folder
RUN tar -cf /opt/initial_iobroker.tar /opt/iobroker \
    && tar -cf /opt/initial_userscripts.tar /opt/userscripts

# Setting up iobroker-user
RUN chsh -s /bin/bash iobroker

# Script for radar2
RUN /opt/scripts/setcab.sh

# Setting up ENVs
ENV DEBIAN_FRONTEND="teletype" \
	LANG="de_DE.UTF-8" \
	LANGUAGE="de_DE:de" \
	LC_ALL="de_DE.UTF-8" \
	TZ="Europe/Berlin" \
	PACKAGES="nano" \
	SETGID=1000 \
	SETGID=1000  

# Setting up EXPOSE for Admin
EXPOSE 8081/tcp	
	
# Run Startup Script
ENTRYPOINT ["/bin/bash", "-c", "/opt/scripts/iobroker_startup.sh"]
