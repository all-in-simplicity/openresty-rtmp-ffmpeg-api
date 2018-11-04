# ----------------------------------------------------------------------------------
# MIT License
#
# Copyright 2018 thiago-dev
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights 
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ----------------------------------------------------------------------------------

################
# 1. build API #
################

# Builder image
FROM golang:1.11.2-alpine3.8 as builder
WORKDIR /work

# enable gin gonic relase mode
ENV GIN_MODE=release

# install required packages
RUN apk add --no-cache git

# add files
ADD api/ .
# compile app static
RUN \
  CGO_ENABLED=0 \
  GOOS=linux \
  GOARCH=amd64 \
  go build -a -installsuffix cgo -ldflags="-w -s" -o go-rtmp-api .

# Main image
FROM openresty/openresty:alpine
LABEL maintainer="Thiago Zimmermann thiago-dev902<at>outlook.com"

#######################
# Environment variables
ENV HLS_DIR "/tmp/hls"

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

########################
# Docker Build Arguments
ARG BUILD_DATE
ARG NGINX_RTMP_VERSION="1.2.1"

ARG RESTY_VERSION="1.13.6.2"
ARG RESTY_OPENSSL_VERSION="1.0.2p"
ARG RESTY_PCRE_VERSION="8.42"
ARG RESTY_LUAROCKS_VERSION="2.4.4"
ARG RESTY_CONFIG_OPTIONS_MORE=""
ARG RESTY_J="1"
ARG RESTY_CONFIG_OPTIONS="\
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    "
# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-openssl=/tmp/openssl-${RESTY_OPENSSL_VERSION} --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION} --with-pcre=/tmp/pcre-${RESTY_PCRE_VERSION}"

ARG FFMPEG_VERSION="4.0.2"
ARG FFMPEG_CONFIG_OPTIONS="\
    --disable-debug \
	--disable-doc \ 
	--disable-ffplay \ 
    --enable-avresample \ 
    --enable-gnutls \
    --enable-gpl \ 
    --enable-libass \ 
    --enable-libfreetype \ 
    --enable-libmp3lame \ 
    --enable-libopus \ 
    --enable-librtmp \ 
    --enable-libtheora \
    --enable-libfdk-aac \ 
    --enable-libvorbis \ 
    --enable-libvpx \ 
    --enable-libwebp \ 
    --enable-libx264 \ 
    --enable-libx265 \ 
    --enable-nonfree \ 
    --enable-postproc \ 
    --enable-small \ 
    --enable-version3 \
    "

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=${BUILD_DATE}
LABEL org.label-schema.name="thiagodev/openresty-rtmp-ffmpeg-api"
LABEL org.label-schema.description="Example of nginx-rtmp for streaming, including ffmpeg and videojs for playback."

#####################################################
# Build steps
# 1) Install apk dependencies
# 2) Download and untar OpenSSL, LuaRocks, ffmpeg, nginx-rtmp, PCRE, and OpenResty
# 3) Build OpenResty with nginx-rtmp-module
# 4) Build LuaRocks
# 5) Build ffmpeg
# 6) Cleanup
RUN apk add --no-cache --virtual .build-deps \
        build-base \
        curl \
        gd-dev \
        geoip-dev \
        libxslt-dev \
        linux-headers \
        make \
        perl-dev \
        readline-dev \
        zlib-dev \
		bzip2 \ 
		coreutils \ 
		gnutls \ 
		nasm \ 
		tar \ 
		x264 \
		curl \
    && apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted \
        fdk-aac-dev \
    && apk add --no-cache \
        gd \
        geoip \
        libgcc \
        supervisor \
        perl \
        libxslt \
        zlib \
        bash \
        freetype-dev \
        gnutls-dev \
        lame-dev \
        libass-dev \
        libogg-dev \
        libtheora-dev \
        libvorbis-dev \ 
        libvpx-dev \
        libwebp-dev \ 
        libssh2 \
        opus-dev \
        rtmpdump-dev \
        x264-dev \
        x265-dev \
	    yasm-dev \
    && cd /tmp \
    && curl -fSL https://www.openssl.org/source/openssl-${RESTY_OPENSSL_VERSION}.tar.gz -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && curl -fSL https://github.com/luarocks/luarocks/archive/${RESTY_LUAROCKS_VERSION}.tar.gz -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && tar xzf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && curl -fSL https://github.com/arut/nginx-rtmp-module/archive/v$NGINX_RTMP_VERSION.tar.gz -o nginx-rtmp-module.tar.gz \
    && tar xzf nginx-rtmp-module.tar.gz \
    && curl -fSL https://ftp.pcre.org/pub/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && curl -sL https://www.ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz -o ffmpeg.tar.gz \
    && tar xzf ffmpeg.tar.gz \
    && curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd /tmp/openresty-${RESTY_VERSION} \
    && ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_CONFIG_OPTIONS_MORE} \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && cd /tmp \
    && cd luarocks-${RESTY_LUAROCKS_VERSION} \
    && ./configure \
        --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit \
        --lua-suffix=jit-2.1.0-beta3 \
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    && make build \
    && make install \
    && cd /tmp/ffmpeg* \
    && PATH="/usr/bin:$PATH" \
	  && ./configure --bindir="/usr/bin" ${FFMPEG_CONFIG_OPTIONS} \
	  && make -j$(getconf _NPROCESSORS_ONLN) \
	  && make install \
	  && make distclean \
    && cd /tmp \
    && rm -rf \
        openssl-${RESTY_OPENSSL_VERSION} \
        openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
        luarocks-${RESTY_LUAROCKS_VERSION} luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
        nginx-rtmp-module-${NGINX_RTMP_VERSION} \
        nginx-rtmp-module.tar.gz \
        ffmpeg-${FFMPEG_VERSION} ffmpeg.tar.gz \
        openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
        pcre-${RESTY_PCRE_VERSION}.tar.gz pcre-${RESTY_PCRE_VERSION} \
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    && runDeps="$( \
        scanelf --needed --nobanner /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache --virtual $runDeps \
    && apk del .build-deps .gettext \
    && mv /tmp/envsubst /usr/local/bin \
    && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log 
# Add LuaRocks paths
# If OpenResty changes, these may need updating:
#    /usr/local/openresty/bin/resty -e 'print(package.path)'
#    /usr/local/openresty/bin/resty -e 'print(package.cpath)'
ENV LUA_PATH="/usr/local/openresty/site/lualib/?.ljbc;/usr/local/openresty/site/lualib/?/init.ljbc;/usr/local/openresty/lualib/?.ljbc;/usr/local/openresty/lualib/?/init.ljbc;/usr/local/openresty/site/lualib/?.lua;/usr/local/openresty/site/lualib/?/init.lua;/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/?/init.lua;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua"
ENV LUA_CPATH="/usr/local/openresty/site/lualib/?.so;/usr/local/openresty/lualib/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so"

# Copy nginx configuration files and sample page
COPY etc/nginx/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY html /usr/local/nginx/html

EXPOSE 80 1935
STOPSIGNAL SIGTERM

# Copy api and config
COPY --from=builder /work/go-rtmp-api /

# setup cron; see clean-hls-dir.sh for more information
COPY clean-hls-dir.sh /clean-hls-dir.sh
RUN chmod +x /clean-hls-dir.sh

COPY etc/cron.d/clean-hls-dir /etc/cron.d/clean-hls-dir
# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/clean-hls-dir
# Apply cron job
RUN crontab /etc/cron.d/clean-hls-dir

COPY etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]