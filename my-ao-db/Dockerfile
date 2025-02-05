FROM --platform=linux/amd64 p3rmaw3b/ao:0.1.4

USER root

# Install Lua 5.4 and development files
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    lua5.4 \
    liblua5.4-dev && \
    mkdir -p /usr/local/include/lua5.4 && \
    cp -L /usr/include/lua5.4/* /usr/local/include/lua5.4/ && \
    # Create multiarch header
    echo '#define LUA_MULTIARCH "x86_64-linux-gnu"' > /usr/local/include/lua5.4/lua5.4-deb-multiarch.h && \
    rm -rf /var/lib/apt/lists/*

# Work directory
WORKDIR /workspace

CMD ["/bin/bash"]
