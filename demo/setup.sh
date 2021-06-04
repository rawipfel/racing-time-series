MAPR_UID=2000
MAPR_GID=2000
CLUSTER_IP=192.168.56.101
CLUSTER_HOST=maprdemo
CLUSTER_NAME=demo.mapr.com

source /vagrant/config.conf

# Install dependencies

apt-get update
apt-get install -y ca-certificates build-essential libxmu-dev libxmu6 libxi-dev libxine-dev libalut-dev freeglut3 freeglut3-dev cmake libogg-dev libvorbis-dev libxxf86dga-dev libxxf86vm-dev libxrender-dev libxrandr-dev zlib1g-dev libpng12-dev libplib-dev wmctrl

# Download sources of TORCS

cd /vagrant
wget -nc http://sourceforge.net/projects/torcs/files/all-in-one/1.3.6/torcs-1.3.6.tar.bz2/download
cd -
cp /vagrant/download ./torcs-1.3.6.tar.bz2
tar xfvj torcs-1.3.6.tar.bz2

# Apply the patch to store telemetry
cd torcs-1.3.6
patch -p1 < /vagrant/src.diff

# Compile the TORCS binary
./configure --enable-debug
make
make install
make datainstall

# Setup MapR Client
echo 'deb http://package.mapr.com/releases/ecosystem-5.x/ubuntu binary/' >> /etc/apt/sources.list
echo 'deb http://package.mapr.com/releases/v5.1.0/ubuntu/ mapr optional' >> /etc/apt/sources.list
apt-get update --allow-unauthenticated 
apt-get install mapr-kafka -y --allow-unauthenticated
add-apt-repository ppa:openjdk-r/ppa -y
apt-get update -y
apt-get install openjdk-8-jdk -y

if [ -n "${CLUSTER_IP}" ]
	then echo "${CLUSTER_IP} ${CLUSTER_HOST}" >> /etc/hosts
fi
/opt/mapr/server/configure.sh -N "${CLUSTER_NAME}" -c -C "${CLUSTER_HOST}":7222 -HS "${CLUSTER_HOST}" -Z "${CLUSTER_HOST}"

groupadd mapr -g ${MAPR_GID}
useradd mapr -u ${MAPR_UID} -g ${MAPR_GID}

# Build the TelemetryAgent (MapR Streams producers/consumers) and UI Server

# apt-get install -y maven
cd /vagrant/racing-telemetry-application
wget -nc https://ftp.wayne.edu/apache/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz
tar -zxvf apache-maven-3.8.1-bin.tar.gz
MAVEN_OPTS=-Xss256m ./apache-maven-3.8.1/bin/mvn clean install

# Add the launcher to the desktop
mkdir -p /home/vagrant/Desktop
cat > /home/vagrant/Desktop/Streams-Demo.desktop << EOF
#!/usr/bin/env xdg-open

[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Exec=/vagrant/run.sh
Name=Streams Demo
Comment=executes the streams demo
Icon=/usr/share/icons/gnome/48x48/status/starred.png
EOF

chmod +x /home/vagrant/Desktop/Streams-Demo.desktop
