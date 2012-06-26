#!/usr/bin/env bash

## USAGE
##     surfOne -i ID  -s SUBJECTS_DIR  -n NIFTI 
##      subjects_dir can be omited if exported in environment
## other options:
##  -e email notifications from qsub (also EMAILS env var)
##  -t FS-{TYPE}-subject qsub title 
##  -d dcm dir (instead of -n), not implemented
##END
function helpmsg {
   sed -n 's/^## //p;/##END/q' $0; exit 
}

case $HOSTNAME in
*gromit*)
   LUNADIR="/raid/r3/p2/Luna"
   ;;
*wallace*)
   LUNADIR="/data/Luna1"
   ;;
*)
  echo dont know what to do on $HOSTNAME && exit ;;
esac

# exit if no arguments
[ -z "$1" ] && helpmsg

# get options
while getopts 's:i:n:t:e:h' switch; do
 case $switch in
    s) SUBJECTS_DIR=$OPTARG ;;
    i)     subjctid=$OPTARG ;;
    n)      niifile=$OPTARG ;;
    t)         TYPE=$OPTARG ;;
    e)       EMAILS=$OPTARG ;;
    d)       dcmdir=$OPTARG ;;
    *) helpmsg ;;
 esac
done
if [ -n "$dcmdir" ]; then
 #TODO: run dcm2nii, set niifile
 echo
fi

#### Sanity checks ######

[ -z "$niifile"      -o ! -r "$niifile"      ] && echo "nifti input must (-i $niifile) must exist"             && exit 1
[ -z "$subjctid" ]                             && echo "need subjectid (-i) to exist"                          && exit 1
 
# subjects dir is likely exported already
[ -z "$SUBJECTS_DIR" -o ! -d "$SUBJECTS_DIR" ] && echo "SUBJECTS_DIR must be defined and exist as a directory" && exit 1

# we can find sane defaults if these aren't provided
[ -z "$TYPE" ]                                 && TYPE=$(basename $(dirname $SUBJECTS_DIR))
[ -z "$EMAILS" ]                               && EMAILS="foranw@upmc.edu"

###############
## submit to qsub 
###############
# remove lunadir from niifile so it can be replaced by
# gromit specific path
scriptloc=$(dirname $0)

# check if finished
tail -n1 ${SUBJECTS_DIR}/$subjctid/scripts/recon-all.log | grep 'without error' && echo "already finished without error" && exit 1
# check if already in que
qstat -f | grep FS-$TYPE-$subjctid && echo "FS-$TYPE-$subjctid already in que" && exit 1

set -ex
 # use -h to hold by default
 qsub -m abe -M $EMAILS \
      -e $scriptloc/log  -o $scriptloc/log \
      -N "FS-$TYPE-$subjctid" \
      -v subjctid="$subjctid",niifile="${niifile##$LUNADIR}",subjdir="${SUBJECTS_DIR##$LUNADIR}",TYPE="$TYPE" \
      $scriptloc/queReconall.sh 

set +ex

