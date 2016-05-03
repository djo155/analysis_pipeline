#!/bin/sh

function Usage(){
    echo "\n run_append_atlas <TR> <delVolumes> <atlas> <analysis_dir_0> <analysis_dir_1> ... <analysis_dir_N> \n"
    echo "This function uses analysis_pipeline.sh to append a new atlas to an existing analysis directory."
    echo "Compulsary Arguments: \n"
    echo "      nifti of 4D atlas\n"
   echo "       a list of T1-weighted structural images. \n"
    echo "Optional Arguments: "
    echo "      -nogrid  : this option disable the submission to SGE. "
    echo "                 i.e. will run locally.\n"
    echo "      -l logs_dir"
}


SGEARGS_ORIG="fsl_sub -q short.q "
LOGARG=logs_root

if [ $# = 0 ] ; then 
    Usage
    exit 1
fi

if [ $1 = -l ] ; then 
    LOGARG=$2
    shift 2
fi


if [ $# = 0 ] ; then 
    Usage
    exit 1
fi

SGEARGS_ORIG="${SGEARGS_ORIG} -l $LOGARG"
#takes in t1 images as input

if [ $1 = -nogrid ] ; then
    SGEARGS_ORIG=""
    shift 1
fi

TR=$1
shift 1
DELV=$1
shift 1
ATLAS=$1
shift 1


#Loop over images
for i in $@ ; do 
    i=`remove_ext $i`
    echo $i 
    
    STDIR=`readlink ${i}/struct/orig.nii.gz | sed 's/\/struct\/orig\.nii\.gz//g'`    
    STIM=`echo $STDIR | sed 's/\.struct_only//g'`
    EXT=`echo $i | awk -F . '{ print $NF }'`
    DIR=`dirname $i`
    FUNC_DATA=`basename $i .$EXT`
    FUNC_DATA="${DIR}/${FUNC_DATA}"

    echo analysis_pipeline.sh -tr ${TR} -deleteVolumes ${DELV} -appendToAnalysis $i -resting -rest_conn_only -reg_info $STDIR -t1 $STIM -atlas_conn_opts --useAllLabels -fc_rois_mni $ATLAS -no_resting_gm_mask -output_extension $EXT -func_data $FUNC_DATA -motion
    ${SGEARGS_ORIG} analysis_pipeline.sh -tr ${TR} -deleteVolumes ${DELV} -appendToAnalysis $i -resting -rest_conn_only -reg_info $STDIR -t1 $STIM -atlas_conn_opts --useAllLabels -fc_rois_mni $ATLAS -no_resting_gm_mask -output_extension $EXT -func_data $FUNC_DATA -motion

#    if [ ! -d ${i}.struct_only ] ; then     
 #	${SGEARGS_ORIG} analysis_pipeline.sh -struct_only -t1 $i  -output_extension struct_only
  #  fi
done

#-bet_mask first/${i}_cort_inv_mni_bet_1mm.nii.gz
