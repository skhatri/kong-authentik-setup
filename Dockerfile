FROM kong:3.7.1
USER root
RUN luarocks install kong-oidc
USER kong
