#!/bin/sh 

#ashley_atlas_connectivity_avg.nii.gz
IN=$1
OUT=`basename $2 .csv`
 NX=`fslinfo $IN  | grep -m 1 dim1  | awk '{ print $2 }'`

roi=0;
files=""
while [ $roi -lt $NX ] ; do
    echo ROI $roi
    fslroi  $IN ${OUT}_grot $roi 1 0 1 0 1
    fslstats -t ${OUT}_grot -M > ${OUT}_roi${roi}.txt
    files="${files} ${OUT}_roi${roi}.txt"

    let roi+=1 
done

paste -d , $files > ${OUT}.csv

imrm ${OUT}_grot
rm $files
