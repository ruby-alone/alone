#!/usr/bin/env ruby
#
# alone : application framework for embedded systems.
#   Copyright (c) 2010 FAR END Technologies Corporation.
#   Copyright (c) 2025- Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
# database connection parameters


##
# PostgreSQL
#
# Prepare for use.
#   CREATE DATABASE al_testdb1;
#   CREATE USER al_user1 WITH PASSWORD 'al_pass1';
#   CREATE USER al_user2 WITH PASSWORD 'al_pass2';
#   GRANT ALL PRIVILEGES ON DATABASE al_testdb1 TO al_user1;
#   \c al_testdb1
#   GRANT ALL ON SCHEMA public TO al_user1;
#
class AlRdbwPostgresTest < Test::Unit::TestCase
  DSN = "host=localhost dbname=al_testdb1 user=al_user1 password=al_pass1"
  DSN2= "host=localhost dbname=al_testdb1 user=al_user2 password=al_pass2"
end


##
# MySQL (mysql2 gems)
#   create user al_user1 identified by 'al_pass1';
#   grant all on *.* to al_user1;
#   grant all on *.* to al_user2;
#   create database al_testdb1;
#
class AlRdbwMysql2Test < Test::Unit::TestCase
  DSN = {host:"localhost", database:"al_testdb1", username:"al_user1", password:"al_pass1"}
  DSN2= {host:"localhost", database:"al_testdb1", username:"al_user2", password:"al_pass2"}
end


##
# SQLite
#
class AlRdbwSqliteTest < Test::Unit::TestCase
  DSN = "/tmp/al_testdb1.sqlite"
  DSN2= "/tmp/al_testdb2.sqlite"
end
