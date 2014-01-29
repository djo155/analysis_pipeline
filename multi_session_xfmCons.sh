#!/bin/sh
dir=$1
mat=$2
warp=$3
odir=$4

for i in `imglob ${dir}/con*` ; do
    f=`basename $i`
    applywarp -i $i -o ${odir}/${f}_mni --premat=$mat -w $warp -r ${FSLDIR}/data/standard/MNI152_T1_2mm 

done
