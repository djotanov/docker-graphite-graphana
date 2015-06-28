from	ubuntu:14.04
run	echo 'deb http://us.archive.ubuntu.com/ubuntu/ trusty universe' >> /etc/apt/sources.list
run	apt-get -y update

run	apt-get -y install software-properties-common &&\
	add-apt-repository ppa:chris-lea/node.js &&\
	apt-get -y update

run     apt-get -y install  python-django-tagging python-simplejson python-memcache \
			    python-ldap python-cairo python-django python-twisted   \
			    python-pysqlite2 python-support python-pip gunicorn     \
			    supervisor nginx-light nodejs git wget curl

run apt-get install -y openssh-server
run mkdir /var/run/sshd
run echo 'root:admin' | chpasswd
run sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
run sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

env NOTVISIBLE "in users profile"
run echo "export VISIBLE=now" >> /etc/profile

# Install statsd
run	mkdir /src && git clone https://github.com/etsy/statsd.git /src/statsd

# Install required packages
run	pip install whisper
run	pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/lib" carbon
run	pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/webapp" graphite-web

# graphana
run     cd ~ &&\
	wget https://grafanarel.s3.amazonaws.com/builds/grafana_2.0.2_amd64.deb &&\
        dpkg -i grafana_2.0.2_amd64.deb && rm grafana_2.0.2_amd64.deb

# statsd
add	./statsd/config.js /src/statsd/config.js

# Add graphite config
add	./graphite/initial_data.json /var/lib/graphite/webapp/graphite/initial_data.json
add	./graphite/local_settings.py /var/lib/graphite/webapp/graphite/local_settings.py
add	./graphite/carbon.conf /var/lib/graphite/conf/carbon.conf
add	./graphite/storage-schemas.conf /var/lib/graphite/conf/storage-schemas.conf
add	./graphite/storage-aggregation.conf /var/lib/graphite/conf/storage-aggregation.conf

# Add system service config
add	./nginx/nginx.conf /etc/nginx/nginx.conf
add	./supervisord.conf /etc/supervisor/conf.d/supervisord.conf


# Nginx
#
# graphite
expose	80:80
# grafana
expose  3000:3000

# Carbon line receiver port
expose	2003:2003
# Carbon pickle receiver port
expose	2004:2004
# Carbon cache query port
expose	7002:7002

# Statsd UDP port
expose	8125:8125/udp
# Statsd Management port
expose	8126:8126

#sshd
expose 22:22

add ./bin/init /usr/bin/init
cmd /usr/bin/init
