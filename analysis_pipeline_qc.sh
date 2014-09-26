#!/bin/sh

ANADIR=/Users/brian/susrc/analysis_pipeline/


function sliceImage()
{
pairimage=""
if [ $1 = -p ]; then
    pairimage=$2
    shift 2
fi

A=`${FSLDIR}/bin/remove_ext $1`
OUTPUT=`${FSLDIR}/bin/remove_ext $2`

IMAGE_dir=${OUTPUT}_dir

mkdir ${IMAGE_dir}
sliceropts="$edgeopts -x 0.4 ${IMAGE_dir}/grota.png -x 0.5 ${IMAGE_dir}/grotb.png -x 0.6 ${IMAGE_dir}/grotc.png -y 0.4 ${IMAGE_dir}/grotd.png -y 0.5 ${IMAGE_dir}/grote.png -y 0.6 ${IMAGE_dir}/grotf.png -z 0.4 ${IMAGE_dir}/grotg.png -z 0.5 ${IMAGE_dir}/groth.png -z 0.6 ${IMAGE_dir}/groti.png"

convertopts="${IMAGE_dir}/grota.png + ${IMAGE_dir}/grotb.png + ${IMAGE_dir}/grotc.png + ${IMAGE_dir}/grotd.png + ${IMAGE_dir}/grote.png + ${IMAGE_dir}/grotf.png + ${IMAGE_dir}/grotg.png + ${IMAGE_dir}/groth.png + ${IMAGE_dir}/groti.png"


${FSLDIR}/bin/slicer  $A $pairimage -s 1 $sliceropts
 ${FSLDIR}/bin/pngappend $convertopts ${OUTPUT}.png

rm -r ${IMAGE_dir}


}


ANALYSISDIR=$1

#ANALYSISDIR=`readlink -f $1`

QCDIR=${ANALYSISDIR}/qc
if [ ! -d ${QCDIR} ]; then
    mkdir ${QCDIR}
fi


#do structural QC
STRUCT=${ANALYSISDIR}/struct/orig

if [ 1 = 0 ]; then
echo "Slicing structural image..."
sliceImage $STRUCT ${QCDIR}/structural
slicer ${STRUCT} -s 1 -A 10000 ${QCDIR}/structural_allaxial.png

FUNC=${ANALYSISDIR}/example_func
echo "Slicing functional image..."
sliceImage $FUNC ${QCDIR}/example_func
slicer ${FUNC} -s 1 -A 1000 ${QCDIR}/example_func_allaxial.png

FUNC=${ANALYSISDIR}/reg/example_func2highres
echo "Slicing functional->structural registration image..."
sliceImage -p $STRUCT $FUNC ${QCDIR}/example_func2highres
slicer  ${FUNC} $STRUCT  $ -s 1 -A 10000 ${QCDIR}/example_func2highres_allaxial.png

fi

#lets do structural to standard space
#warp highres image
STD=${FSLDIR}/data/standard/MNI152_T1_2mm
applywarp -i $STRUCT -r $STD -w ${ANALYSISDIR}/reg/highres2standard_warp -o ${ANALYSISDIR}/reg/highres2standard_warped
WARPED=${ANALYSISDIR}/reg/highres2standard_warped
sliceImage -p $STD $WARPED ${QCDIR}/highres2standard
slicer  ${WARPED} $STD  $ -s 1 -A 2000 ${QCDIR}/highres2standard_allaxial.png

#DO BET

BETMASK=${ANALYSISDIR}/struct/brain_fnirt_mask.nii.gz
sliceImage -p $BETMASK $STRUCT ${QCDIR}/brain_extraction
slicer  ${STRUCT} $BETMASK  $ -s 1 -A 2000 ${QCDIR}/brain_extraction_allaxial.png




#sliceImage $1 $2
echo "Creating HTML ${QCDIR}/index.html "
${ANADIR}/create_subject_report/create_subject_report ${QCDIR}/index $ANALYSISDIR


