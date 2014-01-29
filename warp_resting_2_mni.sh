#!/bin/sh

#  warp_resting_2_mni.sh .sh
#  
#
#  Created by Brian M. Patenaude on 4/11/12.
#  Copyright 2012 Stanford University. All rights reserved.

function Usage(){
    echo "**********************************\n"
    echo "\n warp_resting_2_mni.sh <atlas_name> <analysis_directories> \n"
    echo "***********************************\n"

}

GRIDARGS="fsl_sub -q short.q -N warp_resting -l logs"

if [ $1 = -nogrid ] ; then 
    GRIDARGS=""
    shift 1
fi



if [ $# -lt 2 ] ; then 
    Usage
    exit 1
fi

ATLAS=$1
shift 1 




for i in $@ ;do
    echo "Warping FC for $i..."
    if [ ! -d ${i}/${ATLAS}.fc ] ; then 
        echo "${i}/${ATLAS}.fc Doesn't exist, exiting..."
        exit 1
    fi 

    export FSLOUTPUTTYPE=NIFTI
    if [ `${FSLDIR}/bin/imtest ${i}/${ATLAS}.fc/${ATLAS}_connectivity_roi_r` = 1 ] ; then 

        if [ ! -d ${i}/reg_standard/${ATLAS}.fc ] ; then 
            /bin/mkdir -p ${i}/reg_standard/${ATLAS}.fc

        fi 
        ${GRIDARGS} ${FSLDIR}/bin/applywarp -i  ${i}/${ATLAS}.fc/${ATLAS}_connectivity_roi_r -r ${FSLDIR}/data/standard/MNI152_T1_2mm -w ${i}/reg/highres2standard_warp --premat=${i}/reg/example_func2highres.mat -o ${i}/reg_standard/${ATLAS}.fc/${ATLAS}_connectivity_roi_r_mni -m ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil
    fi
    if [ `${FSLDIR}/bin/imtest ${i}/${ATLAS}.fc/mc/${ATLAS}_connectivity_roi_r` = 1 ] ; then 
        if [ ! -d ${i}/reg_standard/${ATLAS}.fc/mc ] ; then 
            /bin/mkdir -p ${i}/reg_standard/${ATLAS}.fc/mc
        fi 
        ${GRIDARGS} ${FSLDIR}/bin/applywarp -i  ${i}/${ATLAS}.fc/mc/${ATLAS}_connectivity_roi_r -r ${FSLDIR}/data/standard/MNI152_T1_2mm -w ${i}/reg/highres2standard_warp --premat=${i}/reg/example_func2highres.mat -o ${i}/reg_standard/${ATLAS}.fc/mc/${ATLAS}_connectivity_roi_r_mni -m ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil
    fi

done