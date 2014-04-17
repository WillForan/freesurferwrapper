#!/usr/bin/env bash
# see /data/Luna1/Raw/MRCTR/linkToMRRC_Org
# should be done by moving script!

SUBJDIR="/data/Luna1/Reward/FS_Subjects/";
RAWDIR="/data/Luna1/Raw/MRCTR/"
# compare a list of all subjects in raw
# with all subjects who's logs match 'finished'
# and take the set difference
# run surfOne on them to que them up

comm -23 \
  <( 
       find  $RAWDIR -mindepth 1 -maxdepth 1 -type d | xargs -n1 basename |sort ) \
  <(
       find $SUBJDIR -maxdepth 3 -mindepth 3 -name recon-all.log |
        xargs grep -l finished |
        while read d; do 
          # get subject id and date, only print if date is a date
          echo ${d##$SUBJDIR}|cut -f 1 -d/ 
        done | sort
   )  | 
 perl -lne 'print if $1<=12 && $2<=31 && m/^\d{5}_20\d\d(\d\d)(\d\d)$/'| # only print valid Ids
while read id; do  
  echo ./surfOne.sh -t Reward -i $id;
  #sleep 1;
done
