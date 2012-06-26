#!/usr/bin/env bash

###                 ###
### options for pbs ###
###                 ###

#PBS -l ncpus=1
#PBS -l walltime=40:00:00
#dont use leading zeros
#PBS -q batch

# PARAMETERS
# expect 
#  o subjctid     -- e.g. 10900
#  o niifile      --      xxxxxxx/*ni.gz
#  o subjdir      --      $LUNADIR/Rest/FS_Subjets
#

## Where are the files (host dependent)
case $HOSTNAME in
*gromit*)
   LUNADIR="/raid/r3/p2/Luna"
   ;;
*wallace*)
   LUNADIR="/data/Luna1"
   ;;
*)
  echo dont know what to do on $HOSTNAME
  exit
  ;;
esac

# setup tool path and vars
source /home/foranw/src/freesurfersearcher/ni_path_local.bash

# try to prepend lunadir if it's been stripped
[ ! -r $subjdir ] && subjdir=$LUNADIR/$subjdir
[ ! -r $niifile ] && niifile=$LUNADIR/$niifile

# setup local vars
[ -z "$subjctid" ] && echo "no subjctid!" && exit 1
[ -z "$subjdir" -o ! -d "$subjdir" ] && echo "no SUBJECTS_DIR! ($subjdir $SUBJECTS_DIR)" && exit 1
export SUBJECTS_DIR=$subjdir



[ ! -r $niifile ] && "cannot read niifile ($niifile)" && exit 1

echo SUBJECT:	        $subjctid
echo NiFTI:	        $niifile
echo SUBJECTS_DIR:	$SUBJECTS_DIR
echo LUNADIR:   	$LUNADIR
echo

set -ex
recon-all -i $niifile -sid ${subjctid} -all 

chmod -R g+rw $SUBJECTS_DIR/${subjctid}
