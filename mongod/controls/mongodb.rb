# encoding: utf-8
#
# Copyright 2018, Ramyha V S
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#
#
#
#
# Unless required by applicable law or agreed to in writing,software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#author : Ramyha V S
#The File can be viewed under github using the link https://github.com/RamyhaSubramani/mongodbinspec
#
#

#testing mongodb  for ubuntu
if ( os[:name]== 'ubuntu' && os[:family]=='debian' && os[:release]=='16.04' )
#determining all the required paths
mongod_conf       = '/etc/mongod.conf'
mongod_ssl        = '/etc/ssl/mongodb.pem'
mongod_log        = '/var/lib/mongodb/mongod.log'
mongod_service    = '/lib/systemd/system/mongod.service'

#to check MongoDB is installed,enabled and running
control 'os-ubuntu' do
impact 0.5
title 'MongoDB installed'
desc 'MongoDB service should be installed,enabled and running'
describe service('mongod') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end
end

#MongoDB file check
control 'MongoDB-file-check' do
desc 'Mongod.conf should exist and mongod should be a executable file'
describe file(mongod_conf) do
it { should exist }
it { should be_file }
its('mode') { should cmp '0644' }
end
describe file('/usr/bin/mongod') do
it { should exist }
it { should be_executable }
end
describe file(mongod_service) do
it { should exist }
it { should be_file }
end
end

#MongoDB_service file contents and permissions
control 'mongod-sercice' do
title 'Verify mongod.service file'
desc 'The Mongod service file should contain the path to mongod.conf file ant it should be owned by root and only be writable by others and readable by others'
describe file(mongod_service) do
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_readable.by('others') }
    it { should_not be_writable.by('others') }
    it { should_not be_executable.by('others') }
end
describe file(mongod_service) do
its('content') { should match 'User=mongodb' }
its('content') { should match 'Group=mongodb' }
its('content') { should match 'ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf' }
end
end

#MongoDB port and ip
control 'MongoDB-server' do
impact 0.8
title 'MongoDB port and ip'
desc 'The MongoDB port and ipaddress'
describe port('27017') do
it { should be_listening }
its('processes') { should include 'mongod'}
its ('protocols') { should include 'tcp' }
end
describe host('127.0.0.1', port: 27017, protocol: 'tcp') do
  it { should be_resolvable }
  its('ipaddress') { should cmp '127.0.0.1' }
end
end

#check permissions of MongoDB config file
control 'MongoDB-conf' do
  impact 1.0
  title 'Checking MongoDB config file owner, group and permissions'
  desc 'The MongoDB config file should owned by root, only be writable by owner and readable by others.'
  describe file(mongod_conf) do
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_readable.by('others') }
    it { should_not be_writable.by('others') }
    it { should_not be_executable.by('others') }
  end
end

#process security
control 'mongod-process' do
 impact 0.7
  title 'Process-security'
  desc 'MongoDB process should not run as the root user'
   describe processes('mongod') do
    its('users') { should_not include 'root' }
  end
end

#to check the MongoDB contents of etc/shadow 
control 'shadow' do
title 'Password details'
desc 'The MongoDB password details that are only readable by the root user'
describe shadow.users('mongodb') do
its('warn_days') { should include '7' }
its('max_days') { should include '99999' }
its('min_days') { should include '0' }
its('last_changes') { should include '17521'}
its('inactive_days') { should include nil }
its('expiry_dates') { should include nil }
end
end

#to check info of MongoDB
#fetching uid and gid of a system
File.open('/etc/passwd').each do |line|
if line .include? "mongodb"
user= line
userdata=user.split(":")
user_uid=userdata[2]
user_gid=userdata[3]
control 'passwd' do
title 'MongoDB-info'
desc 'It contains the MongoDB information that may log into the system'
if(describe passwd()do
  its('users') { should include 'mongodb' }
 end)
describe passwd.users('mongodb') do
its('uids') { should include user_uid }
its('gids') { should include user_gid }
end
end
end
end
end
#to check about the user
control 'user' do
desc 'The MongoDB profiles for a single, known/expected local user, including the groups to which that user belongs, the frequency of required password changes, and the directory paths to home and shell'
describe user('mongodb') do
it { should exist }
its('group') {should_not eq 'root' }
end
end

#MongoDB security validation
control 'mongod-security-http' do
impact 0.5
  title 'HTTP-based interfaces are disabled'
  desc 'MongoDB recommends all HTTP-based interfaces are disabled in production to avoid data leakage and authentication to be enabled to ensure security'
  describe parse_config_file(mongod_conf,options) do
    its("auth") { should eq true }
    its( "httpinterface") { should eq false }
     end
end
control 'mongod-security-ssl' do
  title 'SSL is enabled'
  desc 'Enabling SSL ensures communication to mongod is secure'
  impact 0.6
=begin
# The ssl can be enabled in mongodb by adding the below line of codes in /etc/mongod.conf
security:
   clusterAuthMode: x509
net:
   ssl:
      mode: requireSSL
      PEMKeyFile: <path to TLS/SSL certificate and key PEM file>
      CAFile: <path to root CA PEM file>
=end
  describe ssl(port: 27017) do
  it { should be_enabled }
end
    describe x509_certificate(mongod_ssl) do
  its('subject.CN') { should eq "#name of a subject" } 
  #its('not_before') { should eq ' 2018-01-04 10:31:56.000000000 +0000' }
  #its('not_after')  { should eq '2020-10-24 10:31:56.000000000 +0000' }
  its('version') { should eq 2 }
  its('signature_algorithm') { should eq 'sha256WithRSAEncryption' }
  its('key_length') { should be 2048 }
end
 describe parse_config_file(mongod_conf) do
    its('sslMode') { should eq 'requireSSL' }
    its('sslPEMKeyFile') { should_not be_nil }
  end
end
control 'mongod-security-objcheck' do
  title 'checking payload is enabled'
  desc 'Inspect all client data for validity on receipt (useful for developing drivers)'
  impact 0.1
  describe parse_config_file(mongod_conf) do
    its('objCheck') { should eq true }
  end
end

#MongoDB performance validation
control 'performance' do
desc "WiredTiger's granular concurrency control and native compression will provide the best all-around performance and storage efficiency for the broadest range of applications"
describe command('mongo --eval "printjson(db.serverStatus().storageEngine.name)"') do
its('stdout') { should include 'wiredTiger' }
end
desc 'verifying log file size'
describe parse_config_file(mongod_conf) do
its('smallfiles') { should eq 'true' }
end
desc 'Leave journaling enabled in order to ensure that mongod will be able to recover its data files and keep the data files in a valid state following a crash'
describe parse_config_file(mongod_conf,options) do
its('journalenabled') { should eq 'true' }
end
end
control 'wiredTiger' do
title 'The WiredTiger options'
desc 'Increasing wiredTiger cache size might improve performance and the default value for directoryForIndexes is true and journalCompressor is snappy'
describe parse_config_file(mongod_conf) do
its('cacheSize') { should eq ' 256MB ' }
its('directoryForIndexes') { should eq 'true' }
its('journalCompressor') { should eq 'snappy' }
end
desc 'Replica Set is the feature provided by the MongoDB database to achieve high availability and automatic failover'
describe parse_config_file(mongod_conf) do
its('replSet') { should eq '#replica set name' }
its('rest') { should eq true }
end
title 'MongoDB storage fits into RAM size'
desc 'The MongoDB working set should be fits into RAM size else it degrades performance'
describe command('inspec exec workset.rb') do # the file workset.rb should retrive system's RAM size and database size from its working set and compare two values and return true it the db size fits into RAM size.
its ('stdout') { should include 'true' }
end
end
end

