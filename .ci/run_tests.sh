set -e

export BUSTED_ARGS="-o gtest -v --exclude-tags=ci"
export TEST_CMD="KONG_SERF_PATH=$SERF_INSTALL/serf bin/busted $BUSTED_ARGS"

if [ "$TEST_SUITE" == "lint" ]; then
  make lint
elif [ "$TEST_SUITE" == "unit" ]; then
  make test
else
  #  createuser --createdb kong
#  psql -U postgres -c "create role kong with createdb login password '123';"
#  createdb -U kong kong_tests

# POSTGRES
  psql -U postgres <<EOQ
  DROP DATABASE IF EXISTS kong_tests;
  DROP ROLE IF EXISTS kong;
  CREATE USER kong WITH createdb password '123';
  CREATE DATABASE kong_tests OWNER kong;
EOQ

  # CASSANDRA
  cqlsh -u cassandra -p cassandra --execute "CREATE ROLE kong with SUPERUSER = true AND LOGIN = true and PASSWORD = '123';"
  cqlsh -u kong -p 123 --execute "DROP KEYSPACE IF EXISTS kong_tests;"
  cqlsh -u kong -p 123 --execute "CREATE KEYSPACE IF NOT EXISTS kong_tests  WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };"

  ./bin/kong migrations bootstrap -c ./spec/kong_tests.conf

  if [ "$TEST_SUITE" == "integration" ]; then
    make test-integration
  elif [ "$TEST_SUITE" == "plugins" ]; then
    make test-plugins
  fi
fi
