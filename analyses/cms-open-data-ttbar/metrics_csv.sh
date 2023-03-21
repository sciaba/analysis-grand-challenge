#! /bin/bash

read_mbytes=()
rx_mbytes=()
wtime=()
eff=()
exe=()
read_rate=()
rx_rate=()
thr=()

metrics() {
    local prmon=$1/prmon.json
    local output=$1/ttbar.out
    local workers=$2
    rmb=$(grep -A 18 Max ${prmon} | awk '/read_bytes/ {sub(/,/, "", $2); print ($2 / 1024 ** 2)}')
    read_mbytes+=($rmb)
    rxmb=$(grep -A 18 Max ${prmon} | awk '/rx_bytes/ {sub(/,/, "", $2); print ($2 / 1024 ** 2)}')
    rx_mbytes+=($rxmb)
    u=$(grep -A 18 Max ${prmon} | awk '/utime/ {sub(/,/, "", $2); print $2}')
    s=$(grep -A 18 Max ${prmon} | awk '/stime/ {sub(/,/, "", $2); print $2}')
    w=$(grep -A 18 Max ${prmon} | awk '/wtime/ {sub(/,/, "", $2); print $2}')
    wtime+=($w)
    eff+=($(awk "BEGIN {print(100*($u+$s)/$w/$workers)}"))
    e=$(grep '^execution took' ${output} | awk '{print $3}')
    exe+=($e)
    read_rate+=($(awk "BEGIN {print($rmb / $e)}"))
    rx_rate+=($(awk "BEGIN {print($rxmb / $e)}"))
    thr+=($(grep processtime ${output} | awk '{print $7}'))
    d=$(grep '^amount' ${output} | awk '{print $5}')
    data+=($d)
    data_rate+=($(awk "BEGIN {print($d / $e)}"))
}
base=$1

jobs="${base} ${base}.*"
workers=$(echo $base | awk -F_ '{print($NF)}')
locstor=$(echo ${base} | grep 'local')
njobs=0
for job in $jobs; do
    if [ -d "$job" ] ; then
	njobs=$((njobs+1))
	metrics $job $workers
    fi
done
if [ "${njobs}" -lt 2 ] ; then
    echo "Only ${njobs} job found, cannot estimate errors. Exiting..." 1>&2
    exit 1
fi

echo "${njobs} jobs for ${workers} workers" 1>&2
echo -n "${workers},"
echo -n ${wtime[@]} | awk '{for (i=1;i<=NF;i++)sum+=$i; avg=(sum/NF); for (i=1;i<=NF;i++)sum2+=($i-avg)^2;err=sqrt(sum2/(NF-1)/NF); printf "%.3f,%.3f,", avg, err}'
echo -n ${eff[@]} | awk '{for (i=1;i<=NF;i++)sum+=$i; avg=(sum/NF); for (i=1;i<=NF;i++)sum2+=($i-avg)^2;err=sqrt(sum2/(NF-1)/NF); printf "%.3f,%.3f,", avg, err}'
if [ -n "$locstor" ] ; then
    echo -n ${read_rate[@]} | awk '{for (i=1;i<=NF;i++)sum+=$i; avg=(sum/NF); for (i=1;i<=NF;i++)sum2+=($i-avg)^2;err=sqrt(sum2/(NF-1)/NF); printf "%.2f,%.2f,", avg, err}'
else
    echo -n ${rx_rate[@]} | awk '{for (i=1;i<=NF;i++)sum+=$i; avg=(sum/NF); for (i=1;i<=NF;i++)sum2+=($i-avg)^2;err=sqrt(sum2/(NF-1)/NF); printf "%.2f,%.2f,", avg, err}'
fi
echo ${thr[@]} | awk '{for (i=1;i<=NF;i++)sum+=$i; avg=(sum/NF); for (i=1;i<=NF;i++)sum2+=($i-avg)^2;err=sqrt(sum2/(NF-1)/NF); printf "%.3f,%.3f\n", avg, err}'
