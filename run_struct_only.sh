#!/bin/sh

SGEARGS_ORIG="fsl_sub -q short.q"
if [ $1 = -nogrid ] ; then 
	SGEARGS_ORIG=""
	shift 1
fi

#takes in t1 images as input

#Loop over images
for i in $@ ; do 
	i=`remove_ext $i`
    echo $i 
	if [ ! -d ${i}.struct_only ] ; then     
${SGEARGS_ORIG} analysis_pipeline.sh -struct_only -t1 $i  -output_extension struct_only
	fi
done

#-bet_mask first/${i}_cort_inv_mni_bet_1mm.nii.gz