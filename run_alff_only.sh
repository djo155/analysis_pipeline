#!/bin/sh

function Usage(){
    echo "run_alff_only.sh <TR> <analysis_dir>"
    exit 1
}

TR=$1
OUTPUTDIR=$2

echo DIR $OUTPUTDIR
if [ $# -ne 2 ] || [ ! -d $OUTPUTDIR ] ; then 
    Usage
fi

MACHTYPE=`uname`


#first convert FWHM (HZ) to sigma (seconds)                                                                                
INPUT_DATA=${OUTPUTDIR}/prefiltered_func_data
MASK=/Volumes/Smurf-Village/Imaging/connectome/ROIs_connectome/GM_.4.nii.gz
FMASK=`remove_ext $MASK`
FMASK=`basename $FMASK`

if [ `imtest $INPUT_DATA` = 0  ]; then 
    echo $INPUT_DATA does not exist
    exit 1
fi 
                  
mkdir ${OUTPUTDIR}/falff 

#residualize for motion
fsl_glm --demean -i ${INPUT_DATA} -d ${OUTPUTDIR}/mc/prefiltered_func_data_mcf.par.txt -o ${OUTPUTDIR}/falff/motion_betas --out_res=${OUTPUTDIR}/falff/motion_residuals

#warp mask to native
applywarp -i $MASK -r ${OUTPUTDIR}/example_func -w ${OUTPUTDIR}/reg/standard2highres_warp.nii.gz --postmat=${OUTPUTDIR}/reg/highres2example_func.mat -o ${OUTPUTDIR}/falff/${FMASK}_2_example_func -d float

#thresh warped mask (0.5 threshold)
fslmaths  ${OUTPUTDIR}/falff/${FMASK}_2_example_func -thr 0.5 -bin ${OUTPUTDIR}/falff/${FMASK}_2_example_func -odt short

for freq_pair in 0.25,0.10 0.10,0.008 ; do
    #run alff
    flow=`echo $freq_pair | awk -F , '{ print $1 }'`
    fhigh=`echo $freq_pair | awk -F , '{ print $2 }'`
    fflow=`echo $flow | sed 's/0\./0/g'`
    ffhigh=`echo $fhigh | sed 's/0\./0/g'`

    ${ETKINLAB_DIR}/bin/${MACHTYPE}/run_alff -m ${OUTPUTDIR}/falff/${FMASK}_2_example_func -i ${OUTPUTDIR}/falff/motion_residuals  -d 0 -o ${OUTPUTDIR}/falff/prefilt_mc_lp${fflow}_hp${ffhigh}_gm --tr=2.0 --lp_freq=$flow --hp_freq=$fhigh --use_rms

    #warp falff results to MNI
    for i_alff in `imglob ${OUTPUTDIR}/falff/prefilt_mc_lp${fflow}_hp${ffhigh}_gm*rms.nii.gz ${OUTPUTDIR}/falff/prefilt_mc_lp${fflow}_hp${ffhigh}_gm_f???StDev.*` ; do
        applywarp -i $i_alff -r ${FSLDIR}/data/standard/MNI152_T1_2mm  -w ${OUTPUTDIR}/reg/highres2standard_warp.nii.gz --premat=${OUTPUTDIR}/reg/example_func2highres.mat -o ${i_alff}_2_mni  -m $MASK -d float
    #clean up native space
        imrm ${i_alff}

    done
done
#clean up
imrm ${OUTPUTDIR}/falff/motion_betas ${OUTPUTDIR}/falff/motion_residuals ${OUTPUTDIR}/falff/GM_.4_2_example_func.nii.gz