ARG VER

FROM nginx:${VER}-alpine

RUN set -e \
	&& apk add --no-cache --virtual .geoip2-deps \
		libmaxminddb

RUN set -e \
	&& apk add --no-cache --virtual .build-deps \
		git \
		libmaxminddb-dev \
		gcc \
		libc-dev \
		make \
		openssl-dev \
		pcre-dev \
		zlib-dev \
		linux-headers \
		curl \
		gnupg \
		libxslt-dev \
		gd-dev \
		geoip-dev \
	&& git clone -q https://github.com/leev/ngx_http_geoip2_module.git \
	&& git clone -q -b AuthV2 https://github.com/anomalizer/ngx_aws_auth.git \
	&& git clone -q https://github.com/vozlt/nginx-module-vts.git \
	&& curl -fsSL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx.tar.gz \
	&& tar xzf nginx.tar.gz \
	&& cd nginx-${NGINX_VERSION} \
	&& CONFIG="\
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--modules-path=/usr/lib/nginx/modules \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
		--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
		--user=nginx \
		--group=nginx \
		--with-http_ssl_module \
		--with-http_realip_module \
		--with-http_addition_module \
		--with-http_sub_module \
		--with-http_dav_module \
		--with-http_flv_module \
		--with-http_mp4_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_random_index_module \
		--with-http_secure_link_module \
		--with-http_stub_status_module \
		--with-http_auth_request_module \
		--with-http_xslt_module=dynamic \
		--with-http_image_filter_module=dynamic \
		--with-http_geoip_module=dynamic \
		--with-threads \
		--with-stream \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-stream_realip_module \
		--with-stream_geoip_module=dynamic \
		--with-http_slice_module \
		--with-mail \
		--with-mail_ssl_module \
		--with-compat \
		--with-file-aio \
		--with-http_v2_module \
	" \
	&& ./configure $CONFIG --add-dynamic-module=/ngx_http_geoip2_module --add-dynamic-module=/ngx_aws_auth --add-dynamic-module=/nginx-module-vts \
	&& make -j$(getconf _NPROCESSORS_ONLN) modules \
	&& strip objs/ngx_http_geoip2_module.so \
	&& strip objs/ngx_http_aws_auth_module.so \
	&& strip objs/ngx_http_vhost_traffic_status_module.so \
	&& cp objs/ngx_http_geoip2_module.so /usr/lib/nginx/modules/ \
	&& cp objs/ngx_http_aws_auth_module.so /usr/lib/nginx/modules/ \
	&& cp objs/ngx_http_vhost_traffic_status_module.so /usr/lib/nginx/modules/ \
	&& rm -rf nginx-${NGINX_VERSION} ngx_http_geoip2_module ngx_aws_auth nginx-module-vts \
	&& apk del --no-cache .build-deps

RUN set -e \
	&& sed -i '1 i\load_module modules/ngx_http_vhost_traffic_status_module.so;' /etc/nginx/nginx.conf \
	&& sed -i '1 i\load_module modules/ngx_http_aws_auth_module.so;' /etc/nginx/nginx.conf \
	&& sed -i '1 i\load_module modules/ngx_http_geoip2_module.so;' /etc/nginx/nginx.conf

ENV NGINX_ENTRYPOINT_QUIET_LOGS 1
