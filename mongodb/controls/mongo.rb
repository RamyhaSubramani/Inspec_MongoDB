#to check ubuntu and its version
control 'os' do
impact 1.2
title 'os configuration'
if os[:name]== 'ubuntu'
describe command('lsb_release -r -s') do
its ('stdout') { should eq "16.04\n" }
end
describe passwd()do
  its('users') { should include 'mongodb' }
 end
end
end
#to check mongodb is installed and enabled
control 'install' do
impact 1.0
title 'mongodb should be installed'
desc 'mongodb should be installed'
if (describe service('mongodb') do
  it { should be_installed }
 end)
describe service('mongodb') do
it { should be_enabled }
it { should be_running }
end
end
end
#to check the port and ip address 
control 'host' do                     
impact 1.1                                
title 'configuration'            
describe file('/etc/mongodb.conf') do                 
it { should exist }
end
describe port(27017) do
it { should be_listening }
end
 describe host('127.0.1.1', port: 27017, protocol: 'tcp') do
  it { should be_resolvable }
  its('ipaddress') { should include '127.0.1.1' }
end
end
#to check properties of resource running on system
control 'process' do
impact 1.3
title 'mongodb donot run as a root'
describe processes('mongod') do
its ('users') { should_not include 'root' }
end 
end
#to check uids and gids
control 'passwd' do
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
describe user('mongodb') do
it { should exist }
its('uid') { should eq 121 }
its('group') {should_not eq 'root' }
end
end
#to check the mongodb contents of etc/shadow 
control 'shadow' do
describe shadow.users('mongodb') do
its('warn_days') { should include '7' }
its('max_days') { should include '99999' }
its('min_days') { should include '0' }
its('last_changes') { should include '17521'}
its('inactive_days') { should include nil }
its('expiry_dates') { should include nil }
end
end
