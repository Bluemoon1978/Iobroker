FROM debian:latest

MAINTAINER Andre Germann <info@buanet.de> / Heiko Holzheimer 

ENV DEBIAN_FRONTEND noninteractive

# INSTALL PACKAGs
RUN apt-get update && \
apt-get install -y \
  build-essential python apt-utils curl avahi-daemon git libpcap-dev libavahi-compat-libdnssd-dev \
  libfontconfig gnupg2 locales procps libudev-dev unzip sudo wget ffmpeg android-tools-adb \
  android-tools-fastboot bluetooth bluez libbluetooth-dev libudev-dev libpam0g-dev nano arp-scan \
  libcap2-bin && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get -y clean all && \
    apt-get autoremove

# INSTALL NODE 8
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash
RUN apt-get install -y nodejs && \
   && rm -rf /var/lib/apt/lists/*

# Configure avahi-daemon 
# RUN sed -i '/^rlimit-nproc/s/^\(.*\)/#\1/g' /etc/avahi/avahi-daemon.conf

# Configure locales/ language/ timezone
RUN sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen \
    && \dpkg-reconfigure --frontend=noninteractive locales \
    && \update-locale LANG=de_DE.UTF-8
RUN cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# DIRECTORYS AND SCRIPTS
RUN mkdir -p /opt/scripts/ && chmod 777 /opt/scripts/
WORKDIR /opt/scripts/
COPY scripts/avahi_startup.sh avahi_startup.sh
COPY scripts/iobroker_startup.sh iobroker_startup.sh
COPY scripts/packages_install.sh packages_install.sh

RUN chmod +x avahi_startup.sh \
    && chmod +x iobroker_startup.sh \
	&& chmod +x packages_install.sh

# Install ioBroker
WORKDIR /
RUN apt-get update \
    && curl -sL https://raw.githubusercontent.com/ioBroker/ioBroker/stable-installer/installer.sh | bash - \
    && echo $(hostname) > /opt/iobroker/.install_host \
    && rm -rf /var/lib/apt/lists/*

# Install node-gyp
WORKDIR /opt/iobroker/
RUN npm install node-gyp -g

# Backup initial ioBroker-folder
RUN tar -cf /opt/initial_iobroker.tar /opt/iobroker

# Giving iobroker-user sudo rights
RUN echo 'iobroker ALL=(ALL) NOPASSWD: ALL' | EDITOR='tee -a' visudo \
    && echo "iobroker:iobroker" | chpasswd \
    && adduser iobroker sudo
USER iobroker

# INSTALL KEYBLE
RUN npm install --update --global --unsafe-perm keyble
RUN setcap cap_net_raw+eip $(eval readlink -f `which node`)

# Setting up ENV
ENV DEBIAN_FRONTEND="teletype" \
	LANG="de_DE.UTF-8" \
	TZ="Europe/Berlin" \
	PACKAGES="nano" \
	AVAHI="false"


# Setting up EXPOSE for Admin
EXPOSE 8081/tcp 8082/tcp 8083/tcp 8084/tcp

# Run startup-script
CMD ["sh", "/opt/scripts/iobroker_startup.sh"]
