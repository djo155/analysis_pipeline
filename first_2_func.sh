#!/bin/sh

#  first_2_func.sh
#  
#
#  Created by Brian M. Patenaude on 1/6/12.
#  Copyright 2012 __MyCompanyName__. All rights reserved.
#
#   This warp the specified first masks into functional space
#
#
#
function Usage(){
    echo "\n\n first_2_func -regions <first_regions(csv)> -d <directories> \n\n"
    echo  
    exit 1 
}
if [ $# -le 2 ] ; then 
    Usage
fi

DIRS=""
FIRST_REGIONS=""
while [ $# -gt 0 ] ; do 
    if [ $1 = -regions ] ; then 
        FIRST_REGIONS=`echo $2 | sed 's/,/ /g'`
        shift 2
    elif [ -d $1 ] ; then 
        DIRS="${DIRS} $1"
        shift 1
    else 
        echo "Unrecognized input, $1"
        Usage
    fi 

done


for i in $DIRS ; do 
    echo Processing $i
    if [ ! -d ${i}/masks ] ; then 
        /bin/mkdir ${i}/masks
    fi
    if [ ! -d ${i}/masks/unwarped ] ; then 
        /bin/mkdir ${i}/masks/unwarped
    fi

    for i_f in $FIRST_REGIONS ; do 

        lt=0;
        ut=0;
        if [ $i_f = L_Amyg ] ; then
        lt=17.5
        ut=18.5
        elif [ $i_f = R_Amyg ] ; then
        lt=53.5
        ut=54.5
        elif [ $i_f = L_Thal ] ; then
        lt=9.5
        ut=10.5
        elif [ $i_f = R_Thal ] ; then
        lt=48.5
        ut=49.5
        elif [ $i_f = L_Caud ] ; then
        lt=10.5
        ut=11.5
        elif [ $i_f = R_Caud ] ; then
        lt=49.5
        ut=50.5
        elif [ $i_f = L_Puta ] ; then
        lt=11.5
        ut=12.5
        elif [ $i_f = R_Puta ] ; then
        lt=50.5
        ut=51.5
        elif [ $i_f = L_Pall ] ; then
        lt=12.5
        ut=13.5
        elif [ $i_f = R_Pall ] ; then
        lt=51.5
        ut=52.5
        elif [ $i_f = L_Hipp ] ; then
        lt=16.5
        ut=17.5
        elif [ $i_f = R_Hipp ] ; then
        lt=52.5
        ut=53.5
        elif [ $i_f = L_Accu ] ; then
        lt=25.5
        ut=26.5
        elif [ $i_f = R_Accu ] ; then
        lt=57.5
        ut=58.5
        else
        echo "invalid FIRST region selected : $i_f"
        exit 1
        fi

        #extract region

        if [ `${FSLDIR}/bin/imtest ${i}/struct/first_all_fast_firstseg` = 0 ] ; then 
            echo "Subcortical segmentation:${OUTPUTDIR}/struct/first_all_fast_firstseg, not found "
            exit 1
        fi
        ${FSLDIR}/bin/fslmaths ${i}/struct/first_all_fast_firstseg -thr $lt -uthr $ut -bin ${i}/masks/unwarped/${i_f}_first_highres
        ${FSLDIR}/bin/flirt -in ${i}/masks/unwarped/${i_f}_first_highres -applyxfm -init  ${i}/reg/highres2example_func.mat -ref ${i}/example_func  -o ${i}/masks/${i_f}_first_highres_2_func -datatype float 
        ${FSLDIR}/bin/fslmaths ${i}/masks/${i_f}_first_highres_2_func -thr 0.5 -bin ${i}/masks/${i_f}_first_highres_2_func
        N=`${FSLDIR}/bin/fslstats ${i}/masks/${i_f}_first_highres_2_func -V | awk '{ print $1 }'`

        if [ $N = 0 ] ; then
            echo "******************WARNING*********************"
            echo "**  No voxels passed 0.5 threshold for $i_f **"
            echo "******************WARNING*********************"
        fi


    done


done    
