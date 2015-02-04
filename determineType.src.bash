### this files describes all the studies that could use FS
# use/sourced by surfOne.sh and findMissingFS.bash


###### TYPE
# if we can figure out what we're dealing with by looking at type:
# generally we have 
#  /data/Luna1/Raw/TYPE/scandate_subjid
#  /data/Luna1/TYPE/{FS_Subjects,mprage}
function listtypes {
 # parse out only the switches that set SUBJECT_DIR (options to type)
 egrep '"\).*SUBJECTS_' ${BASH_SOURCE[0]}| sed -e 's/"//g;s/)//;' && exit 1
}

# raid is mounted funny depending on host
case $HOSTNAME in
*gromit*)
   # as of 2013-03-11 this is unnessary. Mathew has added the sym link to gromit
   LUNADIR="/raid/r3/p2/Luna"
   ;;
*wallace*)
   LUNADIR="/data/Luna1"
   ;;
*)
  echo dont know what to do on $HOSTNAME && exit 1;;
esac

# should be empty
rageSuperSuffix="";

case $TYPE in 
 WM|"WorkingMemory") SUBJECTS_DIR="/data/Luna1/WorkingMemory/FS_Subjects/";TYPE=WorkingMemory ;; # added 2013-03-12
 "P5")               SUBJECTS_DIR="/data/Luna1/P5/FS_Subjects/";TYPE=P5;rawdir="P5Sz";ragepatt="tfl-multi" ;; # added 2015-02-04
 "Reward")           SUBJECTS_DIR="/data/Luna1/Reward/FS_Subjects/"; rawdir="MRCTR"; TYPE="Reward" ;;
 AF|"AutFace")       SUBJECTS_DIR="/data/Luna1/Autism_Faces/FS_Subjects/";   TYPE=Autism_Faces ;;
 "AF2")              SUBJECTS_DIR="/data/Luna1/Autism_Faces/FS_Subjects_2/"; TYPE=Autism_Faces ;;
 MM|MultiModal)      SUBJECTS_DIR="/data/Luna1/Multimodal/FS_Subjects/" ;  TYPE=MultiModal; rageStorageSuffix=ANTI;rageSuperSuffix="mprage/" ;;
 # mprage sorted luna1/multimodal/ANTI/$subjid/mprage/  while the rest are $type/mprage/$subjid/
 "list")             listtypes;;
 "")                 ;; # no one says you have to put a type in
 *)                  echo "Unknown type! use:" && listtypes ;;
esac

# sane defaults if these aren't provided
[ -z "$TYPE" ]      && TYPE=$(basename $(dirname $SUBJECTS_DIR))
[ -z "$rawdir" ]    && rawdir=$TYPE
[ -z "$ragepatt" ]  && ragepatt="rage"

# where in the Study folder should mprage files be stored?
[ -z "$rageStorageSuffix" ] && rageStorageSuffix=mprage
RAWDIR=$LUNADIR/Raw/$rawdir
