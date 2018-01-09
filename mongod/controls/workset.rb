#the sum of datasize and indexsize should be less tha RAM size
x=Array[]
y=command('grep MemTotal /proc/meminfo').stdout
x=y.split(" ")
z=x[1].to_i #RAM size
a=Array[]
b=command('mongo --eval "printjson(db.stats())"').stdout
a=b.split(",")
c=Array[]
c=a[4].split(":").last,a[8].split(":").last
d=c[0].to_i+c[1].to_i #sum of data and index size
if  d <= z
puts true
else
puts false
end

