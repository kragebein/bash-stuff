
#!/bin/bash
. scripts/master.sh
get_ups_status=$(sshpass -p<OMITTED> ssh <OMITTED>@10.0.0.1 upsc ups@localhost)
get_diskmon(){
rm /tmp/file.htm
wget -q "http://10.0.0.108/" --http-user=<OMITTED> --http-password=<OMITTED> -O /dev/null #bugfix
wget -q "http://10.0.0.108/hwmon.htm" --http-user=<OMITTED> --http-password=<OMITTED> -O /tmp/file.htm 1>/dev/null 2>/dev/null
COUNTER=0
for i in $(cat /tmp/file.htm |grep "&#186;C" |sed 's/&#186;C//' |awk -F '>' '{print $2}' |awk -F '<' '{print $1}'|tail -n 24)
do
while [  $COUNTER -lt 24 ]; do
        export disk_$COUNTER="$i c"
        curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "disk_data,host=goliath,sensor=disk.$COUNTER.temp value=$i"
        let COUNTER=COUNTER+1
        break;
done
done

}
bc=$(echo "$get_ups_status" | grep "battery.charge: "|awk -F ': ' '{print $2}')
bcs=$(echo "$get_ups_status" | grep "battery.charger.status: " | awk -F ': ' '{print $2}')
watt=$(echo "$get_ups_status" | grep "ups.realpower: " |awk -F ': ' '{print $2}')
amps=$(echo "$get_ups_status" | grep "output.current: " |awk -F ':  ' '{print $2}')
volt=$(echo "$get_ups_status" | grep "output.voltage: " |awk -F ': ' '{print $2}')
temp=$(echo "$get_ups_status" | grep "ambient.temperature: " |awk -F ': ' '{print $2}')
load=$(echo "$get_ups_status" | grep "ups.load: " |awk -F ': ' '{print $2}' |awk -F ' ' '{print $1}')
memf=$(free |grep Mem | awk '{print $7}')
memff=$(echo "$memf/1024" |bc)
memp=$(free | grep Mem | awk '{print $3/$7 * 100.0}')
memu=$(free |grep Mem | awk '{print $3}')
memuu=$(echo "$memu/1024" |bc)
cputemp=$(sensors |grep "id 0:" |awk '{print $4}' |sed -e 's/+//' |sed -e 's/°C//')
cpuload=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
proc=$(ps -A --no-headers | wc -l)
avgone=$(cat /proc/loadavg |awk '{print $1}')
mov_tot="`sudo -u plex -H LD_LIBRARY_PATH=/usr/lib/plexmediaserver /usr/lib/plexmediaserver/Plex\ Media\ Scanner -l -c 18 |wc -l`"
tv_tot="`sudo -u plex -H LD_LIBRARY_PATH=/usr/lib/plexmediaserver /usr/lib/plexmediaserver/Plex\ Media\ Scanner -l -c 12 |wc -l`"
stream_count=$(curl -s "http://localhost:8181/api/v2?apikey=<OMITTED>&cmd=get_activity" |awk -F "\"stream_count\":" '{print $2}' |awk -F "\"" '{print $2}')
avgtwo=$(cat /proc/loadavg |awk '{print $2}')
avgthree=$(cat /proc/loadavg |awk '{print $3}')
if [ "$bcs" = "discharging" ]; then facebook_chat "WARNING; Power outage! $bc% battery remaining on ups, services temporarily stopped"; stop_services ; fi
if [ "$bcs" = "charging" ]; then start_services; fi
echo "ups.charge: $bc%"
echo "ups.load: $load%"
echo "ups.status: $bcs"
echo "ups.output: ${watt}W/${amps}A/${volt}V"
echo "ups.temp: $tempºC"
echo "sys.mem: ${memuu}mb/${memff}mb ($memp)"
echo "sys.cputemp $cputemp"
echo "sys.cpuload $cpuload"
echo "sys.proc $proc"
echo "plex.tvtot: $tv_tot"
echo "plex.movtot: $mov_tot"
echo "plex.streams: $stream_count"
echo "load.avg $avgone $avgtwo $avgthree"
write() {
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "ups_data,host=goliath,sensor=battvoltage value=$volt"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "ups_data,host=goliath,sensor=battcharge value=$bc"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "ups_data,host=goliath,sensor=battload value=$load"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "ups_data,host=goliath,sensor=battwatt value=$watt"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "ups_data,host=goliath,sensor=battamps value=$amps"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "ups_data,host=goliath,sensor=batttemp value=$temp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "sys_data,host=goliath,sensor=system.mem.free value=$memuu"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "sys_data,host=goliath,sensor=system.mem.used value=$memff"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "sys_data,host=goliath,sensor=system.mem.perc value=$memp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "sys_data,host=goliath,sensor=system.cputemp value=$cputemp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "sys_data,host=goliath,sensor=system.cpuload value=$cpuload"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "sys_data,host=goliath,sensor=system.proc value=$proc"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "sys_data,host=goliath,sensor=load.avg.5 value=$avgone"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "sys_data,host=goliath,sensor=load.avg.10 value=$avgtwo"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "sys_data,host=goliath,sensor=load.avg.15 value=$avgthree"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "plex_data,host=goliath,sensor=tv.total value=$tv_tot"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "plex_data,host=goliath,sensor=movie.total value=$mov_tot"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "plex_data,host=goliath,sensor=stream.count value=$stream_count"

}
get_diskmon
write
