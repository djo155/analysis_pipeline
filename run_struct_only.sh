#!/bin/sh

function Usage(){
    echo "\n run_struct_only.sh [-nogrid] <im_t1_0> <im_t1_1> ... <im_t1_N> \n"
    echo "This function uses analysis_pipeline.sh to run the structural portion "
    echo "of the pipeline. The output directory will be the name a of T1-weight "
    echo "image with \".struct_only\" appended to it. \n"
    echo "Compulsary Arguments: \n"
    echo "       a list of T1-weighted structural images. \n"
    echo "Optional Arguments: "
    echo "      -nogrid  : this option disable the submission to SGE. "
    echo "                 i.e. will run locally.\n"

}


SGEARGS_ORIG="fsl_sub -q short.q"


if [ $# = 0 ] ; then 
    Usage
    exit 1
fi

if [ $1 = -nogrid ] ; then 
    SGEARGS_ORIG=""
    shift 1
fi

if [ $# = 0 ] ; then 
    Usage
    exit 1
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
