#! /bin/bash

# Default values
afname="unl"
workers=4
fraction=50

usage() {
    echo "Usage : run_ttbar.sh [-n NFILES] -a AFNAME -w NWORKERS [-d] [-m] -h]"
    echo "                     [-f FRACTION]"
    echo
    echo "        -n NFILES: specify the maximum number of files per dataset"
    echo "        -a AFNAME: specify the data source. Possible choices:"
    echo "                   cern-xrootd: from EOSCMS via xrootd"
    echo "                   cern-http: from EOSCMS via HTTPS"
    echo "                   cernbox-xrootd: from CERNBOX via xrootd"
    echo "                   cern-local: from the local filesystem of iopef01"
    echo "                   unl: from Mebraska via HTTP"
    echo "        -w NWORKERS: specify how many workers should be used"
    echo "        -d: use if the data processing should be skipped"
    echo "        -m: use of the merged dataset should be used instead of the original"
    echo "        -f FRACTION: use to specify the percentage of data to read"
    echo "                     ((4, 15, 25, 50) default is 50)"
    echo "        -h: this help message"
}


while getopts "n:a:w:df:mih" arg; do
    case $arg in
	n)
	    nfiles=$OPTARG
	    ;;
	a)
	    afname=$OPTARG
	    ;;
	w)
	    workers=$OPTARG
	    ;;
	d)
	    disable_proc=1
	    ;;
	f)
	    fraction=$OPTARG
	    ;;
	m)
	    merged=1
	    ;;
	?|h)
	    usage
	    exit 1
	    ;;
    esac
done

sudo sysctl vm.drop_caches=3

if [ -z "${nfiles}" ] ; then
    nfiles='all'
    nf='-1'
else
    nf=${nfiles}
fi

if [ -z "${merged}" ] ; then
    WDIR="ttbar_orig_run_"
    datasets="ntuples.json"
else
    WDIR="ttbar_merged_run_"
    datasets="ntuples_merged.json"
fi
if [ -z "${disable_proc}" ] ; then
    noproc='False'
    WDIR="${WDIR}${nfiles}_${afname}_${workers}"
else
    noproc='True'
    WDIR="${WDIR}${nfiles}_${afname}_noproc_${fraction}_${workers}"
fi
if [ -d ${WDIR} ] ; then
    echo "Directory already exit. Exiting..."
    exit 1
fi
mkdir ${WDIR}
cat ttbar_template.py | sed "s/_NFILES_/${nf}/" | sed "s/_AFNAME_/${afname}/" | sed "s/_WORKERS_/${workers}/" | sed "s/_NOPROC_/${noproc}/" | sed "s/_FRACTION_/${fraction}/" | sed "s/_DATASETS_/${datasets}/" > ${WDIR}/ttbar_tmp.py
cd ${WDIR}
ln -s ../utils utils
ln -s ../ntuples.json .
ln -s ../ntuples_merged.json .
ln -s ../cabinetry_config.yml .
export EXTRA_CLING_ARGS="-O2"
prmon -i 5 -- ipython ttbar_tmp.py &> ttbar.out
