#!/usr/bin/env bash
SUBJDIR=/data/Luna1/WorkingMemory/FS_Subjects/;
# compare a list of all subjects in raw
# with all subjects who's logs match 'finished'
# and take the set difference
# run surfOne on them to que them up

comm -23 \
  <( 
       find  /data/Luna1/Raw/WorkingMemory/ -mindepth 1 -maxdepth 1 -type d | xargs -n1 basename) \
  <(
       find $SUBJDIR -maxdepth 3 -mindepth 3 -name recon-all.log |
        xargs grep -l finished |
        while read d; do 
          echo ${d##$SUBJDIR}|cut -f 1 -d/;
        done
   )  | 
while read id; do  
  ./surfOne.sh -t WM -i $id;
  sleep 1;
done
