x=Array[]
y=command('grep MemTotal /proc/meminfo').stdout
x=y.split(" ")
z=x[1].to_i
a=Array[]
b=command('mongo --eval "printjson(db.stats())"').stdout
a=b.split(",")
c=Array[]
c=a[4].split(":").last,a[8].split(":").last
d=c[0].to_i+c[1].to_i
if d <= z
puts 'true'
end