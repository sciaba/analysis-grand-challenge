#! /bin/bash

# Default values
afname="unl"
workers=4
fraction=50

while getopts "n:a:w:df:" arg; do
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
    esac
done

sudo sysctl vm.drop_caches=3

if [ -z "${nfiles}" ] ; then
    nfiles='all'
    nf='-1'
else
    nf=${nfiles}
fi

if [ -z "${disable_proc}" ] ; then
    noproc='False'
    WDIR="ttbar_run_${nfiles}_${afname}_${workers}"
else
    noproc='True'
    WDIR="ttbar_run_${nfiles}_${afname}_noproc_${fraction}_${workers}"
fi
if [ -d ${WDIR} ] ; then
    echo "Directory already exit. Exiting..."
    exit 1
fi
mkdir ${WDIR}
cat ttbar_template.py | sed "s/_NFILES_/${nf}/" | sed "s/_AFNAME_/${afname}/" | sed "s/_WORKERS_/${workers}/" | sed "s/_NOPROC_/${noproc}/" | sed "s/_FRACTION_/${fraction}/" > ${WDIR}/ttbar_tmp.py
cd ${WDIR}
ln -s ../utils utils
ln -s ../ntuples.json .
ln -s ../ntuples_merged.json .
ln -s ../cabinetry_config.yml .
prmon -i 10 -- ipython ttbar_tmp.py &> ttbar.out
