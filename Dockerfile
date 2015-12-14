# FROM centos:latest
FROM registry.access.redhat.com/rhel7:latest

RUN yum -y update && yum -y install pcre openssl-libs zlib

ENV HAPROXY_MAJOR 1.6
ENV HAPROXY_VERSION 1.6.2
ENV HAPROXY_MD5 d0ebd3d123191a8136e2e5eb8aaff039

# take a look at http://www.lua.org/download.html for
# newer version

ENV LUA_URL http://www.lua.org/ftp/lua-5.3.1.tar.gz
ENV LUA_MD5 797adacada8d85761c079390ff1d9961

# see http://git.haproxy.org/?p=haproxy-1.6.git;a=blob_plain;f=Makefile;hb=HEAD
# for some helpful navigation of the possible "make" arguments

RUN buildDeps='pcre-devel openssl-devel gcc make zlib-devel readline-devel openssl tar' \
	&& set -x \
	&& yum -y install curl $buildDeps \
        && curl -SL ${LUA_URL} -o lua-5.3.1.tar.gz \
        && echo "${LUA_MD5} lua-5.3.1.tar.gz" | md5sum -c \
        && mkdir -p /usr/src/lua \
        && tar -xzf lua-5.3.1.tar.gz -C /usr/src/lua --strip-components=1 \
        && rm lua-5.3.1.tar.gz \
        && make -C /usr/src/lua linux test install \
	&& curl -SL "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz" -o haproxy.tar.gz \
	&& echo "${HAPROXY_MD5}  haproxy.tar.gz" | md5sum -c \
	&& mkdir -p /usr/src/haproxy \
	&& tar -xzf haproxy.tar.gz -C /usr/src/haproxy --strip-components=1 \
	&& rm haproxy.tar.gz \
	&& make -C /usr/src/haproxy \
		TARGET=linux2628 \
		USE_PCRE=1 \
		USE_OPENSSL=1 \
		USE_ZLIB=1 \
                USE_LINUX_SPLICE=1 \
                USE_TFO=1 \
                USE_PCRE_JIT=1 \
                USE_LUA=1 \
		all \
		install-bin \
	&& mkdir -p /usr/local/etc/haproxy \
        && mkdir -p /usr/local/etc/haproxy/ssl \
        && mkdir -p /usr/local/etc/haproxy/ssl/cas \
        && mkdir -p /usr/local/etc/haproxy/ssl/crts \
	&& cp -R /usr/src/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors \
	&& rm -rf /usr/src/haproxy /usr/src/lua \
	&& yum -y autoremove $buildDeps \
        && yum -y clean all

#         && openssl dhparam -out /usr/local/etc/haproxy/ssl/dh-param_4096 4096 \

COPY haproxy.conf /usr/local/etc/haproxy/haproxy.cfg
COPY dh-param_4096 /usr/local/etc/haproxy/ssl/dh-param_4096

#CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
CMD ["haproxy", "-vv"]
