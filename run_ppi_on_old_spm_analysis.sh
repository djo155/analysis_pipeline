#!/bin/sh

ODIR=$1
SUBID=$2
SUBID=pain_p002
con=5


mask=/Volumes/EtkinLab_Data/Imaging/ctr_gad_mdd_cmd_pts/fmri/emoconflict/${SUBID}_fmri_emoconflict.estroop_bbr/reg_standard/masks/L_Amyg_first_highres_2_mni.nii

fmask=`basename $mask`
fmask=`remove_ext $fmask`

echo fmask $fmask
echo con $con
echo mask $mask 
echo odir $ODIR


fSUBID=`echo $SUBID | awk -F _ '{ print $2 }'`
echo analysis_pipeline_SPM_VOI.sh ${ODIR}/run_voi.m $mask  $con $ODIR $fmask "/Volumes/HD2TB/pain_data/LBP_${fSUBID}/results/emoconflict_detrended_0s_mvmtparams/SPM.mat"

analysis_pipeline_SPM_VOI.sh ${ODIR}/run_voi.m $mask  $con $ODIR $fmask "/Volumes/HD2TB/pain_data/LBP_${fSUBID}/results/emoconflict_detrended_0s_mvmtparams/SPM.mat"

CURDIR=$PWD
cd ${ODIR}
pwd
echo run_voi | matlab -nodesktop -nodisplay -nosplash
cd $CURDIR


mv /Volumes/HD2TB/pain_data/LBP_${fSUBID}/results/emoconflict_detrended_0s_mvmtparams/VOI_${fmask}_session_1_1.mat ${ODIR}/

analysis_pipeline_SPM_PPI.sh ${ODIR}/run_ppi.m $mask  $con $ODIR $fmask "/Volumes/HD2TB/pain_data/LBP_${fSUBID}/results/emoconflict_detrended_0s_mvmtparams/SPM.mat"


CURDIR=$PWD
cd ${ODIR}
echo run_ppi | matlab -nodesktop -nosplash
cd $CURDIR
