set -e

export KONG_BUILD_DIR=$CACHE_DIR/openresty-build-tools
export BUILD_ROOT=$KONG_BUILD_DIR/buildroot
export KONG_INSTALL=$CACHE_DIR/kong

export KONG_BASE="kong-${KONG_VERSION}"

mkdir -p $CACHE_DIR
# mkdir $HOME/cache
# if [ ! "$(ls -A $CACHE_DIR)" ]; then
  # Not in cache
  pushd $CACHE_DIR


  # -----------------
  git clone https://github.com/Kong/openresty-build-tools.git
  pushd openresty-build-tools
  ./kong-ngx-build -p buildroot --openresty $OPENRESTY --openssl $OPENSSL --luarocks $LUAROCKS --pcre $PCRE
  popd
  
  # return from cache directory
  popd 
# fi

# export PATH=$PATH:$OPENRESTY_INSTALL/nginx/sbin:$OPENRESTY_INSTALL/bin:$LUAROCKS_INSTALL/bin
export PATH="$BUILD_ROOT/luarocks/bin:$BUILD_ROOT/openssl/bin:$BUILD_ROOT/openresty/bin:$PATH"
export OPENSSL_DIR="$BUILD_ROOT/openssl"

echo '======== DEV DEPS DONE ==========='

eval `luarocks path`

# luarocks install kong "$KONG_VERSION"-0; # 1. this rock does not copy bin/kong. 2. causes assertion failed!
luarocks install luacheck 0.20.0-1

echo '========= KONG START ==========='
mkdir -p $KONG_INSTALL
# if [ ! "$(ls -A $KONG_INSTALL)" ]; then
  # ----------------
  # Install Kong
  # ----------------
  echo 'building cache...'
  pushd $KONG_INSTALL
  export KONG_BASE="kong-${KONG_VERSION}"
  echo $KONG_BASE
  git clone https://github.com/Kong/kong.git $KONG_BASE
  pushd $KONG_BASE
  git checkout $KONG_VERSION
  make
  luarocks make
  make install
  make dev
  echo "PWD:: $PWD"
  popd
  popd
# fi
export PATH=$PATH:$KONG_INSTALL/$KONG_BASE/bin
export KONG_PATH=$KONG_INSTALL/$KONG_BASE/bin/kong
printenv
echo '========= KONG DONE ==========='

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
luacheck -v
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
