#!/usr/bin/env bash
##!/home/foranw/bin/bash-42

## submit freesurfer job to torque/PBS
## ----------------------------------
## 
## USAGE
##  surfOne.sh   -t TYPE -i SUBJECT_ID
##  
##  surfOne.sh   -i ID -d DCMDIR [ -s SUBJECTS_DIR] [ -r rawdir ] 
##  surfOne.sh   -i ID -n NIFILE [ -s SUBJECTS_DIR] [ -r rawdir ] 
## 
##
##  -i SUBJID       subject ID as it will be known by freesurfer (eg lunaid_date)
##  -t TYPE         can set SUBJECT_DIR and raw data directories
##                  which can then set dcmdir
##                  **expects subject_id to also be the raw data ID**
##                       set -d and -s to avoid assumption
##                  -t list to see known types
##                  also sets qsub title to FS-{TYPE}-subject, defaults to dir before FS_SUBJ
##  -d DCMDIR       create and use nii from dcm dir 
##                  nii.gz stored in FS_SUBJ/../mprage/subj/
##                  alternative to -n, -d is ignored if -n is provided
##  -n NIFILE       use NIFILE as nifti for reconall  
##                  alternative to -d, forces -d to be  ignored
##  -s SUBJECTS_DIR freesurfer subjects directory
##                  ommit if exported in environment
##  -r RAWDIR       where the data is: $LUNADIR/Raw/{RAWDIR}/SUBJECT_ID/*mprage*/*dmc
##                  omit if same name as $SUBJECTS_DIR/..
##  -e EMAIL        notifications from qsub 
##                  omit if willforan@gmail.com is good, or export EMAILS set
##
## 
##  job gets passed to queReconAll.sh which will run on gromit
##  queReconAll knows to strip wallaces $LUNADIR 
##   and tries to append $LUNADIR specific to gromit for files that DNE
##END

## TODO??
##   if just given -i, check FS_SUBJ/../mprage for nii
##    if that doesn't exist, check raw/$(basename FS_SUBJ/..) for subj/*mprage* 
##    and use as -d
##

function helpmsg {
   # print the top of this file
   sed -n 's/^## //p;/##END/q' $0; exit 1
}
function listtypes {
 # parse out only the switches that set SUBJECT_DIR (options to type)
 egrep '"\).*SUBJECTS_' $0| sed -e 's/"//g;s/)//;' && exit 1
}

# raid is mounted funny depending on host
case $HOSTNAME in
*gromit*)
   LUNADIR="/raid/r3/p2/Luna"
   ;;
*wallace*)
   LUNADIR="/data/Luna1"
   ;;
*)
  echo dont know what to do on $HOSTNAME && exit 1;;
esac

# exit if no arguments
[ -z "$1" ] && helpmsg

# get options
while getopts 's:i:n:t:e:d:r:h' switch; do
 case $switch in
    s) SUBJECTS_DIR=$OPTARG ;;
    i)     subjectid=$OPTARG ;;
    n)      niifile=$OPTARG ;;
    t)         TYPE=$OPTARG ;;
    e)       EMAILS=$OPTARG ;;
    d)       dcmdir=$OPTARG ;;
    r)       rawdir=$OPTARG ;;
    *) helpmsg ;;
 esac
done

###### TYPE
# if we can figure out what we're dealing with by looking at type:
case $TYPE in 
 "Reward")     SUBJECTS_DIR="/data/Luna1/Reward/FS_Subjects/"; rawdir="MRCTR_Org" ;;
 "AutFace"|AF) SUBJECTS_DIR="/data/Luna1/Autism_Faces/FS_Subjects/" ;;
 "MM")         SUBJECTS_DIR="/data/Luna1/Multimodal/" ;;
 "list")       listtypes;;
 "")        ;; # no one says you have to put a type in
 *)        echo "Unknown type! use:" && listtypes ;;
esac

# sane defaults if these aren't provided
[ -z "$TYPE" ]      && TYPE=$(basename $(dirname $SUBJECTS_DIR))
[ -z "$EMAILS" ]    && EMAILS="willforan@gmail.com"
[ -z "$rawdir" ]    && rawdir=$TYPE


#### Sanity checks ######
[ -z "$subjectid" ] && echo "need subjectid (-i) to exist"  && exit 1



## SUBJECT DIR (and location of raw data)

# subjects dir is likely exported already
if [ -z "$SUBJECTS_DIR" -o ! -d "$SUBJECTS_DIR" ]; then
  echo "SUBJECTS_DIR must be defined and exist as a directory" 
  exit 1
fi


## guess at dcmdir if no nii and no dcmdir provided
if [ -z "$dcmdir" -a -z "$niifile" ]; then
 # assumptions:
 #  * experiment files are one level above SUBJECT_DIR
 #     -- need ragedir=$(dirname $SUBJECTS_DIR)/mprage, will make $ragedir/$subjectid/
 #        eg /data/Luna1/AutismFaces/mprage/$subjid
 #  * rawdir/subject/*rage* is a directory with mprage
 #             
 
 dcmdir=$LUNADIR/Raw/$rawdir/$subjectid/*rage*/
 [ ! -d $dcmdir ] && echo "raw not where expected for $subjectid ($dcmdir), use -d" && exit 1

 echo $dcmdir
 exit
fi

# try using dcmdir to make and set niifile
if [ -n "$dcmdir" -a -z "$niifile" ]; then

 # do we have a place to store the nii files?
 ragedir=$(dirname $SUBJECTS_DIR)/mprage
 [ -z "$ragedir" -o ! -d "$ragedir" ] && echo "mprage subjects dir DNE (fix: mkdir $ragedir)" && exit 1

 # make sure we can go to the provided directory and go there
 cd $dcmdir || exit 1

 # check that no nii's already exist
 ls $dcmdir/*nii.gz 2>/dev/null && echo "already have nii files in dcm folder ($dcmdir), use those (-n)?" && exit 1
 # TODO?: use them? move them?

 # should provide dicom
 ls $ragedir/$subjectid/*nii.gz 2>/dev/null >&2 && echo "already have nii files, use those (-n $ragedir/$subjectid/*nii.gz)?" && exit 1
 
 mkdir -p $ragedir/$subjectid/ || exit 1

 # convert raw to nifti
 dcm2nii -c N -e N -f N -p N -x N -r N * || exit 1 # doesn't always return failure when it doesn't work

 # move them (or exit if they don't exist/cant move)
 mv *nii.gz $ragedir/$subjectid/ || exit 1
 cd -

 # with dcm2nii options and initial check, there should be only one niifile, use that
 [ "$(ls $ragedir/$subjectid/*nii.gz |wc -l)" != 1 ] && echo "there was not 1 and only 1 nii file produced!" && exit 1
 niifile="$(ls $ragedir/$subjectid/*nii.gz)"
fi


# check niifile
# it is either provided as an option (-n) or created ( implicit or explicit -d)
[ -z "$niifile"      -o ! -r "$niifile"      ] && echo "nifti input must (-i $niifile) must exist"             && exit 1


#### get absolute path of inputs ###
niifile=$(cd $(dirname $niifile); echo $(pwd)/$(basename $niifile))
SUBJECTS_DIR=$(cd $(dirname $SUBJECTS_DIR); echo $(pwd)/$(basename $SUBJECTS_DIR))




###############
## submit to qsub 
###############
# remove lunadir from niifile so it can be replaced by
# gromit specific path
scriptloc=$(dirname $0)

# check if finished, shouldn't matter: reconall wont run if the directory even exists
tail -n1 ${SUBJECTS_DIR}/$subjectid/scripts/recon-all.log 2>/dev/null | 
  grep 'without error' && echo "already finished without error" && exit 1

# check if already in queue
qstat -f | grep FS-$TYPE-$subjectid && echo "FS-$TYPE-$subjectid already in queue" && exit 1

set -ex
 # use -h to hold by default
 qsub -m abe -M $EMAILS \
      -e $scriptloc/log  -o $scriptloc/log \
      -N "FS-$TYPE-$subjectid" \
      -v subjectid="$subjectid",niifile="${niifile##$LUNADIR}",subjdir="${SUBJECTS_DIR##$LUNADIR}",TYPE="$TYPE" \
      $scriptloc/queReconall.sh 

set +ex

