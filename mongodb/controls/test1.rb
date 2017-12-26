control 'ver-2.6' do                        
  impact 0.7                                
  title 'version'            
    describe file('/etc/mongodb.conf') do                 
    it { should exist }
      end
   describe port(27017) do
  it { should be_listening }
end
end
