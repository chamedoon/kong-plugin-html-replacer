set -e

export OPENRESTY_INSTALL=$CACHE_DIR/openresty
export LUAROCKS_INSTALL=$CACHE_DIR/luarocks
export KONG_INSTALL=$CACHE_DIR/kong

mkdir -p $CACHE_DIR

if [ ! "$(ls -A $CACHE_DIR)" ]; then
  # Not in cache

  # ---------------
  # Install OpenSSL
  # ---------------
  OPENSSL_BASE=openssl-$OPENSSL
  curl -L http://www.openssl.org/source/$OPENSSL_BASE.tar.gz | tar xz

  # -----------------
  # Install OpenResty
  # -----------------
  OPENRESTY_BASE=openresty-$OPENRESTY
  mkdir -p $OPENRESTY_INSTALL
  curl -L https://openresty.org/download/$OPENRESTY_BASE.tar.gz | tar xz

  pushd $OPENRESTY_BASE
    ./configure \
      --prefix=$OPENRESTY_INSTALL \
      --with-openssl=../$OPENSSL_BASE \
      --with-ipv6 \
      --with-pcre-jit \
      --with-http_ssl_module \
      --with-http_realip_module \
      --with-http_stub_status_module
    make
    make install
  popd

  rm -rf $OPENRESTY_BASE

  # ----------------
  # Install Luarocks
  # ----------------
  LUAROCKS_BASE=luarocks-$LUAROCKS
  mkdir -p $LUAROCKS_INSTALL
  git clone https://github.com/keplerproject/luarocks.git $LUAROCKS_BASE

  pushd $LUAROCKS_BASE
    git checkout v$LUAROCKS
    ./configure \
      --prefix=$LUAROCKS_INSTALL \
      --lua-suffix=jit \
      --with-lua=$OPENRESTY_INSTALL/luajit \
      --with-lua-include=$OPENRESTY_INSTALL/luajit/include/luajit-2.1
    make build
    make install
  popd

  rm -rf $LUAROCKS_BASE

  # ----------------
  # Install Kong
  # ----------------
  export KONG_VERSION="1.3"
  export KONG_BASE=$KONG_INSTALL-$KONG_VERSION
  echo '========= KONG START ==========='
  echo $KONG_BASE
  mkdir -p $KONG_BASE
  pushd $KONG_BASE
  wget -O "kong.deb" "https://bintray.com/kong/kong-deb/download_file?file_path=kong-${KONG_VERSION}.xenial.amd64.deb"
  sudo dpkg -i "kong.deb" || true
  popd
  rm -rf $KONG_BASE
  echo '========= KONG DONE ==========='
fi

export PATH=$PATH:$OPENRESTY_INSTALL/nginx/sbin:$OPENRESTY_INSTALL/bin:$LUAROCKS_INSTALL/bin

# luarocks install kong "$KONG_VERSION"-0
luarocks install luacheck 0.23.0-1

# # -------------------------------------
# # Install ccm & setup Cassandra cluster
# # -------------------------------------
# if [[ "$TEST_SUITE" != "unit" ]] && [[ "$TEST_SUITE" != "lint" ]]; then
#   pip install --user PyYAML six
#   git clone https://github.com/pcmanus/ccm.git
#   pushd ccm
#     ./setup.py install --user
#   popd
#   ccm create test -v binary:$CASSANDRA -n 1 -d
#   ccm start -v
#   ccm status
# fi

# nginx -V
# resty -V
luarocks --version
kong version
echo "^^^ kong version ^^^"
# serf version
pip install cassandra-driver --user
wget https://archive.apache.org/dist/cassandra/2.2.7/apache-cassandra-2.2.7-bin.tar.gz && tar -xvzf apache-cassandra-2.2.7-bin.tar.gz
sed -i 's/^\(authenticator: \)\(AllowAllAuthenticator\)$/\1PasswordAuthenticator/i' apache-cassandra-2.2.7/conf/cassandra.yaml
cd apache-cassandra-2.2.7 && sh ./bin/cassandra && cd ..
export PATH="${PATH}:${PWD}/apache-cassandra-2.2.7/bin"
sudo service postgresql start
while ! cqlsh -u cassandra -p cassandra -e 'describe cluster' ; do sleep 1; done
echo "lua version:"
lua -v
