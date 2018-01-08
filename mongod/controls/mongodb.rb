# encoding: utf-8
#
# Copyright 2018, Ramyha
#
only_if { os[:name]== 'ubuntu' && os[:release]=="16.04" }
#determining all the required paths
mongod_conf       = '/etc/mongod.conf'
mongod_ssl        = '/etc/ssl/mongodb.pem'
mongod_log        = '/var/lib/mongodb/mongod.lob'
#to determine RAM,data and index size
control 'os-ubuntu' do
impact 0.5
title "mongodb installed"
desc "mongodb service should be installed,enabled and running  " 
describe service("mongod") do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end
end
control "mongodb v3.2" do
impact 0.8
title "mongodb port and ip"
desc "The Mongodb version,port and ipaddress"
describe port('27017') do
it { should be_listening }
its('processes') { should include 'mongod'}
end
describe host('127.0.0.1', port: 27017, protocol: 'tcp') do
  it { should be_resolvable }
  its('ipaddress') { should cmp '127.0.0.1' }
end
end
control 'mongodb-conf' do
  impact 1.0
  title 'Checking mongodb config file owner, group and permissions'
  desc 'The Mongodb config file should owned by root, only be writable by owner and readable by others.'
  describe file(mongod_conf) do
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_readable.by('others') }
    it { should_not be_writable.by('others') }
    it { should_not be_executable.by('others') }
  end
end

#process security
control "mongod-process" do
 impact 0.7
  title "process-security"
  desc "Mongodb process should not run as the root user"
   describe processes("mongod") do
    its("users") { should_not include "root" }
  end
end
#to check the mongodb contents of etc/shadow 
control 'shadow' do
title "password details"
desc "The mongodb password details that are only readable by the root user"
describe shadow.users('mongodb') do
its('warn_days') { should include '7' }
its('max_days') { should include '99999' }
its('min_days') { should include '0' }
its('last_changes') { should include '17521'}
its('inactive_days') { should include nil }
its('expiry_dates') { should include nil }
end
end
#to check info of mongodb
control 'passwd' do
title "mongodb-info"
desc "It contains the Mongodb information that may log into the system"
if(describe passwd()do
  its('users') { should include 'mongodb' }
 end)
describe passwd.users('mongodb') do
its('uids') { should include '121' }
its('gids') { should include '65534' }
end
end
end
#to check about the user
control 'user' do
desc "The Mongodb profiles for a single, known/expected local user, including the groups to which that user belongs, the frequency of required password changes, and the directory paths to home and shell"
describe user('mongodb') do
it { should exist }
its('group') {should_not eq 'root' }
end
end
#mongodb security validation
control "mongod-security-http" do
impact 0.5
  title "HTTP-based interfaces are disabled"
  desc "MongoDB recommends all HTTP-based interfaces are disabled in production to avoid data leakage and authentication to be enabled to ensure security"
  describe parse_config_file(mongod_conf) do
    its("auth") { should eq true }
    its( "httpinterface") { should eq false }
     end
end
control "mongod-security-ssl" do
  title "SSL is enabled"
  desc "Enabling SSL ensures communication to mongod is secure"
  impact 0.6
    describe x509_certificate(mongod_ssl) do
  its('subject.CN') { should eq "Ramyha" }
  #its('not_before') { should eq ' 2018-01-04 10:31:56.000000000 +0000' }
  #its('not_after')  { should eq '2020-10-24 10:31:56.000000000 +0000' }
  its('version') { should eq 2 }
  its('signature_algorithm') { should eq 'sha256WithRSAEncryption' }
  its('key_length') { should be 2048 }
end
 describe parse_config_file(mongod_conf) do
    its("sslMode") { should eq "requireSSL" }
    its("sslPEMKeyFile") { should_not be_nil }
  end
end
control "mongod-security-objcheck" do
  title "checking payload is enabled"
  desc "Inspect all client data for validity on receipt (useful for developing drivers)"
  impact 0.1
  describe parse_config_file(mongod_conf) do
    its("objCheck") { should eq true }
  end
end
#ensure peformance
control 'performance' do
desc "WiredTiger's granular concurrency control and native compression will provide the best all-around performance and storage efficiency for the broadest range of applications"
describe command('mongo --eval "printjson(db.serverStatus().storageEngine.name)"') do
its('stdout') { should include 'wiredTiger' }
end
desc 'verifying log file size'
describe file('/var/log/mongodb/mongod.log') do
its('size') { should be < 2097152 }
end
desc "Leave journaling enabled in order to ensure that mongod will be able to recover its data files and keep the data files in a valid state following a crash"
describe parse_config_file(mongod_conf) do
its('nojournal') { should eq 'false' }
end
end
control 'wiredTiger' do
title "The WiredTiger cache size"
desc "Increasing wiredTiger cache size might improve performance"
describe parse_config_file(mongod_conf) do
its(['wiredTiger','engineConfig','cacheSizeGB']) { should eq ' 256MB ' }
its(['wiredTiger','engineConfig','directoryForIndexes']) { should eq 'true' }
its(['wiredTiger','engineConfig','journalCompressor']) { should eq 'snappy' }
end
end
control 'storage-RAM' do
title 'Mongodb storage fits into RAM size'
desc 'The Mongodb working set should be fits into RAM size else it degrades performance'
describe command('inspec exec workset.rb') do
its ('stdout') { should include 'true' }
end
end
#elsif { os[:name]== 'redhat' && os[:release] ==