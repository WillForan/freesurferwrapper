#!/usr/bin/env bash

# input is either 
#  - a specific type
#  - empty (all types)

if [ -z "$1" ]; then 
  # if empty, get all types by listing them in surfOne
  types=$(./surfOne.sh -t list|sed 's/^ //;s/[| ].*//')
else
  types="$1"
fi

tmp=$(mktemp)

qstat -f|grep Job_Name > $tmp

for TYPE in $types; do
  ## get type information, set
  # SUBJECTS_DIR, TYPE, rawdir, ragepat, rageStorageSuffix, rageSuperSuffix
  . determineType.src.bash

  comm -23 \
    <( 
         find  $RAWDIR -mindepth 1 -maxdepth 1 -type d \
             -name '[0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' |
           xargs -n1 basename |sort ) \
    <(
         find $SUBJECTS_DIR -maxdepth 3 -mindepth 3 -name recon-all.log |
          xargs grep -l finished |
          while read d; do 
            echo ${d##$SUBJECTS_DIR}|cut -f 1 -d/;
          done | sort
     )  | 
  while read id; do  
    grep "FS-$TYPE-$id" $tmp 1>/dev/null && echo "# found $TYPE $id in qstat queue" && continue 
    echo ./surfOne.sh -t $TYPE -i $id;
    #sleep 1;
  done

done

rm $tmp
