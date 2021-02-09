ARG NGINX_VERSION=1.19.6
ARG BITNAMI_NGINX_REVISION=r48
ARG BITNAMI_NGINX_TAG=${NGINX_VERSION}-debian-10-${BITNAMI_NGINX_REVISION}

FROM bitnami/nginx:${BITNAMI_NGINX_TAG} AS builder
USER root
# Redeclare NGINX_VERSION so it can be used as a parameter inside this build stage
ARG NGINX_VERSION
ARG MOD_UPLOAD_VERSION=2.3.0
# Install required packages and build dependencies
RUN install_packages dirmngr gpg gpg-agent curl build-essential libpcre3-dev zlib1g-dev libssl-dev
# Add trusted NGINX PGP key for tarball integrity verification
RUN gpg --keyserver keyserver.ubuntu.com --recv-key 520A9993A1C052F8
# Download NGINX, verify integrity and extract
RUN cd /tmp && \
    curl -O http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    curl -O http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc && \
    gpg --verify nginx-${NGINX_VERSION}.tar.gz.asc nginx-${NGINX_VERSION}.tar.gz && \
    tar xzf nginx-${NGINX_VERSION}.tar.gz
COPY nginx-upload-module-${MOD_UPLOAD_VERSION}.tar.gz /tmp
RUN cd /tmp && \
    #curl doesnt work for whatever reason curl http://github.com/fdintino/nginx-upload-module/archive/${MOD_UPLOAD_VERSION}.tar.gz -o "nginx-upload-module-${MOD_UPLOAD_VERSION}.tar.gz"  && \
    #notice download file name doesnt actually match url
    tar xzf nginx-upload-module-${MOD_UPLOAD_VERSION}.tar.gz
# Compile NGINX with desired module
RUN cd /tmp/nginx-${NGINX_VERSION} && \
    rm -rf /opt/bitnami/nginx && \
    ./configure --prefix=/opt/bitnami/nginx --with-compat --add-dynamic-module=/tmp/nginx-upload-module-${MOD_UPLOAD_VERSION} && \
    make modules && \
    make install

FROM bitnami/nginx:${BITNAMI_NGINX_TAG}
USER root
# Install ngx_http_perl_module system package dependencies
RUN install_packages libssl-dev
# Install ngx_http_perl_module files
#notice file name is from config file not from actual file name
COPY --from=builder /opt/bitnami/nginx/modules/ngx_http_upload_module.so /opt/bitnami/nginx/modules/ngx_http_upload_module.so
# Enable module
RUN echo "load_module modules/ngx_http_upload_module.so;" | cat - /opt/bitnami/nginx/conf/nginx.conf > /tmp/nginx.conf && \
    cp /tmp/nginx.conf /opt/bitnami/nginx/conf/nginx.conf
# Set the container to be run as a non-root user by default
USER 1001