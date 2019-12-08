set -e

export LUAROCKS_INSTALL=$CACHE_DIR/luarocks

#  LUAROCKS_INSTALL                 Overrides the `./config --prefix` value (default is `<prefix>/luarocks`)

#  LUAROCKS_DESTDIR                 Overrides the `make install DESTDIR` (default is `/`)

#  OPENRESTY_INSTALL                Overrides the `./config --prefix` value (default is `--prefix/openresty)

#  OPENRESTY_DESTDIR                Overrides the `make install DESTDIR` (default is `/`)

#  OPENSSL_INSTALL                  Overrides the `./config --prefix` value (default is `--prefix/openssl)

#  OPENRESTY_RPATH

mkdir -p $CACHE_DIR


cd $CACHE_DIR
git clone https://github.com/Kong/openresty-build-tools.git
cd openresty-build-tools
./kong-ngx-build -p buildroot --openresty 1.13.6.2 --openssl 1.1.1b --luarocks 3.0.4 




echo "deb https://kong.bintray.com/kong-deb `lsb_release -sc` main" | sudo tee -a /etc/apt/sources.list
curl -o bintray.key https://bintray.com/user/downloadSubjectPublicKey?username=bintray
sudo apt-key add bintray.key
sudo apt-get update
sudo apt-get install -y kong luarocks

# luarocks install kong "$KONG_VERSION"-0; # 1. this rock does not copy bin/kong. 2. causes assertion failed!
luarocks install luacheck 0.20.0-1 --local

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
