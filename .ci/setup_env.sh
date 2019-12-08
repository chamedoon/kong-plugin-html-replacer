set -e


echo "deb https://kong.bintray.com/kong-deb `lsb_release -sc` main" | sudo tee -a /etc/apt/sources.list
curl -o bintray.key https://bintray.com/user/downloadSubjectPublicKey?username=bintray
sudo apt-key add bintray.key
sudo apt-get update
sudo apt-get install -y kong

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
