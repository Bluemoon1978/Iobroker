FROM debian:latest

MAINTAINER Andre Germann <info@buanet.de> / Heiko Holzheimer 

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y build-essential python apt-utils curl avahi-daemon git libpcap-dev libavahi-compat-libdnssd-dev 
RUN apt-get update && apt-get install -y libfontconfig gnupg2 locales procps libudev-dev unzip sudo wget ffmpeg android-tools-adb 
RUN apt-get update && apt-get install -y android-tools-fastboot bluetooth bluez libbluetooth-dev libudev-dev libpam0g-dev nano arp-scan

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash
RUN apt-get install -y nodejs

RUN sed -i '/^rlimit-nproc/s/^\(.*\)/#\1/g' /etc/avahi/avahi-daemon.conf
RUN sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen && \dpkg-reconfigure --frontend=noninteractive locales && \update-locale LANG=de_DE.UTF-8
ENV LANG de_DE.UTF-8 
RUN cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime
ENV TZ Europe/Berlin

RUN mkdir -p /opt/iobroker/ && chmod 777 /opt/iobroker/
RUN mkdir -p /opt/scripts/ && chmod 777 /opt/scripts/

WORKDIR /opt/scripts/

ADD scripts/avahi_startup.sh avahi_startup.sh
RUN chmod +x avahi_startup.sh
RUN mkdir /var/run/dbus/

ADD scripts/iobroker_startup.sh iobroker_startup.sh
RUN chmod +x iobroker_startup.sh

WORKDIR /opt/iobroker/

RUN npm install iobroker --unsafe-perm && npm i --production --unsafe-perm
RUN update-rc.d iobroker.sh remove && echo $(hostname) > .install_host
RUN npm install node-gyp -g
RUN npm install --global speed-test

RUN mkdir -p /opt/iobroker/node_modules/iobroker.node-red/node_modules 
RUN chmod 777 /opt/iobroker/node_modules/iobroker.node-red/node_modules
WORKDIR /opt/iobroker/node_modules/iobroker.node-red/node_modules
RUN npm install node-red-contrib-join

WORKDIR /opt/iobroker/

CMD ["sh", "/opt/scripts/iobroker_startup.sh"]

ENV DEBIAN_FRONTEND teletype
