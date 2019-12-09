set -e

export LUAROCKS_INSTALL=$CACHE_DIR/setup-luarocks
export LUAROCKS_DESTDIR=$CACHE_DIR/luarocks

export OPENRESTY_INSTALL=$CACHE_DIR/setup-openresty
export OPENRESTY_DESTDIR=$CACHE_DIR/openresty

export OPENSSL_INSTALL=$CACHE_DIR/setup-openssl
export OPENSSL_DESTDIR=$CACHE_DIR/openssl

mkdir -p $CACHE_DIR

cd $CACHE_DIR
git clone https://github.com/Kong/openresty-build-tools.git
cd openresty-build-tools
./kong-ngx-build -p buildroot --openresty $OPENRESTY --openssl $OPENSSL --luarocks  $LUAROCKS
ls -la
# luarocks install kong "$KONG_VERSION"-0; # 1. this rock does not copy bin/kong. 2. causes assertion failed!
luarocks install luacheck 0.20.0-1 --local

cd $CACHE_DIR
ls -la
git clone https://github.com/Kong/kong
cd kong/
git checkout v1.4
# install the Lua sources
luarocks make

# nginx -V
# resty -V
luarocks --version
luacheck -v
kong version
echo "^^^ kong version ^^^"
kong check
kong roar
kong health
echo "................................................................................"

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
