#!/bin/sh

function Usage(){

    echo "\n analysis_pipeline_qc.sh  [ -struct_only ] <raw_func_4D> <analysis directory>"

}




ANADIR=`dirname $0`
#/Users/brian/susrc/analysis_pipeline/
#echo $0




function sliceImage()
{
    pairimage=""
    SLCOPTS=""
    PARSEOPTS=1;
    while [ $PARSEOPTS = 1 ]; do
	if [ $1 = -p ]; then
	    pairimage=$2
	    shift 2
	elif [ $1 = -e ]; then
	    SLCOPTS="${SLCOPTS} -e $2 "
	    shift 2
	else
	    PARSEOPTS=0
	fi

    done

    A=`${FSLDIR}/bin/remove_ext $1`
    OUTPUT=`${FSLDIR}/bin/remove_ext $2`

    IMAGE_dir=${OUTPUT}_dir

    mkdir ${IMAGE_dir}
    sliceropts="$edgeopts -x 0.4 ${IMAGE_dir}/grota.png -x 0.5 ${IMAGE_dir}/grotb.png -x 0.6 ${IMAGE_dir}/grotc.png -y 0.4 ${IMAGE_dir}/grotd.png -y 0.5 ${IMAGE_dir}/grote.png -y 0.6 ${IMAGE_dir}/grotf.png -z 0.4 ${IMAGE_dir}/grotg.png -z 0.5 ${IMAGE_dir}/groth.png -z 0.6 ${IMAGE_dir}/groti.png"

    convertopts="${IMAGE_dir}/grota.png + ${IMAGE_dir}/grotb.png + ${IMAGE_dir}/grotc.png + ${IMAGE_dir}/grotd.png + ${IMAGE_dir}/grote.png + ${IMAGE_dir}/grotf.png + ${IMAGE_dir}/grotg.png + ${IMAGE_dir}/groth.png + ${IMAGE_dir}/groti.png"


    ${FSLDIR}/bin/slicer  $A $pairimage $SLCOPTS -s 1 $sliceropts
    ${FSLDIR}/bin/pngappend $convertopts ${OUTPUT}.png

    rm -r ${IMAGE_dir}


}


if [ $# = 0 ]; then

    Usage;
    exit 1

fi

STRUCT_ONLY=0
if [ $1 = -struct_only ] ; then 
    STRUCT_ONLY=1
fi

RAW_FUNC=$1
ANALYSISDIR=$2

ANALYSISDIR=`readlink -f $2`

QCDIR=${ANALYSISDIR}/report
if [ ! -d ${QCDIR} ]; then
    mkdir ${QCDIR}
fi


#do structural QC
STRUCT=${ANALYSISDIR}/struct/orig
FUNC2HIGHRES=${ANALYSISDIR}/reg/example_func2highres
STD=${FSLDIR}/data/standard/MNI152_T1_2mm
SUBCORT=${ANALYSISDIR}/struct/first_all_fast_firstseg.nii.gz
BETMASK=${ANALYSISDIR}/struct/brain_fnirt_mask.nii.gz
WARPED=${ANALYSISDIR}/reg/highres2standard_warped
FUNC=${ANALYSISDIR}/example_func
FAST=${ANALYSISDIR}/struct/brain_fnirt_pveseg.nii.gz


#if [ 0 = 1 ]; then
    echo "Slicing structural image..."
    sliceImage $STRUCT ${QCDIR}/structural
    slicer ${STRUCT} -s 1 -A 10000 ${QCDIR}/structural_allaxial.png

    echo "Slicing functional image..."
    sliceImage $FUNC ${QCDIR}/example_func
    slicer ${FUNC} -s 8 -A 10000 ${QCDIR}/example_func_allaxial.png

    echo "Slicing functional->structural registration image..."
    sliceImage -p $STRUCT $FUNC2HIGHRES ${QCDIR}/example_func2highres
    slicer  ${FUNC2HIGHRES} $STRUCT  $ -s 1 -A 10000 ${QCDIR}/example_func2highres_allaxial.png


#lets do structural to standard space
#warp highres image
    echo "Warping structural to standard space and slicing"
    applywarp -i $STRUCT -r $STD -w ${ANALYSISDIR}/reg/highres2standard_warp -o ${ANALYSISDIR}/reg/highres2standard_warped
    sliceImage -p $STD $WARPED ${QCDIR}/highres2standard
    slicer  ${WARPED} $STD  $ -s 1 -A 2000 ${QCDIR}/highres2standard_allaxial.png

#DO BET
    echo "Creating Brain Extraction Outline and Slicing"
    sliceImage -p $BETMASK $STRUCT ${QCDIR}/brain_extraction
    slicer  ${STRUCT} $BETMASK  $ -s 1 -A 2000 ${QCDIR}/brain_extraction_allaxial.png

#lets do the subcortical
    echo "Creating Subcortical Outlines and Slicing"
    sliceImage -e -0.5 -p $SUBCORT $STRUCT ${QCDIR}/firstseg
    slicer  ${STRUCT} $SUBCORT  -e -0.5 -s 1 -A 2000 ${QCDIR}/firstseg_allaxial.png

#lets do the subcortical
    echo "Creating Tissue Segmentation Outlines and Slicing"
    sliceImage -e -0.1 -p $FAST $STRUCT ${QCDIR}/fastpveseg
    slicer  ${STRUCT} $FAST  -e -0.1 -s 1 -A 2000 ${QCDIR}/fastpveseg_allaxial.png

#sSNR

flirt -in ${ANALYSISDIR}/struct/brain_fnirt_mask -ref ${ANALYSISDIR}/example_func -applyxfm -init ${ANALYSISDIR}/reg/highres2example_func.mat -out ${ANALYSISDIR}/struct/brain_fnirt_mask_2_example_func

#fi
#fslmaths $ORIGFUNC -mas ${ANALYSISDIR}/struct/brain_fnirt_mask_2_example_func -Tstd  ${QCDIR}/func_std
#fslmaths $ORIGFUNC -mas ${ANALYSISDIR}/struct/brain_fnirt_mask_2_example_func -Tmean  ${QCDIR}/func_mean
#fslmaths ${QCDIR}/func_mean -div ${QCDIR}/func_std ${QCDIR}/vSNR

#fslstats ${QCDIR}/vSNR -M > ${ANALYSISDIR}/vSNR.txt


#copy motion p[lots
cp ${ANALYSISDIR}/mc/*.png ${QCDIR}/

#sliceImage $1 $2
echo "Creating HTML ${QCDIR}/index.html "
${ANADIR}/create_subject_report/create_subject_report ${QCDIR}/index $RAW_FUNC $ANALYSISDIR


