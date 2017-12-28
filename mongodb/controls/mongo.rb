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
control 'os' do
impact 1.2
title 'os configuration'
if(describe file('/usr/bin/ubuntu-software') do
it { should exist }
end)
describe command('lsb_release -r -s') do
its ('stdout') { should eq "16.04\n" }
end
end
end
control 'process' do
impact 1.3
title 'mongodb donot run as a root'
describe processes('mongod') do
its ('users') { should_not include 'root' }
end 
end
