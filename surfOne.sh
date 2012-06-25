#!/usr/bin/env bash

#
# search for subjects in raw/MM
# that do not have directory in MM/FS
#   do reconall -all on these subjects
# 
#  input  <--  /data/Luna1/Raw/MultiModal/lunaid_date/*mprage*/*dcm
#
#  nii    -->  /data/Luna1/Multimodal/ANTI/${subjctid}/mprage
#  FS     -->  /data/Luna1/Multimodal/FS_Subjects/${subjctid}  
#
#  FS log -->  /data/Luna1/Multimodal/FS_Subjects/${subjctid}/scripts/recon-all.log # longer log file
#         -->  /data/Luna1/Multimodal/ANTI/${subjctid}/mprage/recon-all.log         # redirect of stdout/err
#
#


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

# if using qsub, who to email about jobs
# Directories
#LUNADIR="/raid/r3/p2/Luna"

while getopts 's:i:n:t:e:m:' switch; do
 case $switch in
    s) SUBJECTS_DIR=$OPTARG ;;
    i)     subjctid=$OPTARG ;;
    n)      niifile=$OPTARG ;;
    t)         TYPE=$OPTARG ;;
    e)       EMAILS=$OPTARG ;;
    d)       dcmdir=$OPTARG ;;
 esac
done
if [ -n "$dcmdir" ]; then
 #TODO: run dcm2nii, set niifile
 echo
fi

[ -z "$SUBJECTS_DIR" -o ! -d "$SUBJECTS_DIR" ] && echo "SUBJECTS_DIR must be defined and exist as a directory" && exit 1
[ -z "$niifile"      -o ! -r "$niifile"      ] && echo "nifti input must (-i $niifile) must exist"             && exit 1
[ -z "$subjctid" ]                             && echo "need subjectid (-i) to exist"                          && exit 1
[ -z "$TYPE" ]                                 && TYPE=$(basename $(dirname $SUBJECTS_DIR))
[ -z "$EMAILS" ]                               && EMAILS="foranw@upmc.edu"
 

###############
## submit to qsub 
###############
# remove lunadir from niifile so it can be replaced by
# gromit specific path
scriptloc=$(dirname $0)
set -ex
 # use -h to hold by default
 echo qsub -m abe -M $EMAILS \
      -e $scriptloc/log  -o $scriptloc/log \
      -N "FS-$TYPE-$subjctid" \
      -v subjctid="$subjctid",niifile="${niifile##$LUNADIR}",subjdir="${SUBJECTS_DIR##$LUNADIR}",TYPE="$TYPE" \
      $scriptloc/queReconall.sh 

set +ex

