set -e

export LUAROCKS_INSTALL=$CACHE_DIR/setup-luarocks
export LUAROCKS_DESTDIR=luarocks

export OPENRESTY_INSTALL=$CACHE_DIR/setup-openresty
export OPENRESTY_DESTDIR=openresty

export OPENSSL_INSTALL=$CACHE_DIR/setup-openssl
export OPENSSL_DESTDIR=openssl

mkdir -p $CACHE_DIR

cd $CACHE_DIR
printenv

mkdir -p $LUAROCKS_INSTALL
pushd $LUAROCKS_INSTALL
wget https://luarocks.org/releases/luarocks-3.2.1.tar.gz
tar zxpf luarocks-3.2.1.tar.gz
pushd luarocks-3.2.1
./configure
make build
sudo make install
popd
popd

luarocks install luacheck 0.20.0-1 --local
echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FINISHED  luarocks: luacheck'
cd $CACHE_DIR
ls -la
git clone https://github.com/Kong/kong
cd kong/
git checkout v1.4
# install the Lua sources
echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> START luarocks: make kong'
luarocks make
echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FINISHED luarocks: make kong'

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
