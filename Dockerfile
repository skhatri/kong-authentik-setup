FROM kong:2.8.0-alpine
USER root
RUN luarocks install kong-oidc
USER kong
