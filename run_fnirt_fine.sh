#!/bin/sh
myscan=$1
shift
mymat=$1
shift
out=$1
shift

DEBUG=0

if [ $# = 1 ] ; then
    DEBUG=$1
    echo DEBUG $DEBUG
fi

FINE=1

FNIRTDIR=/Volumes/EtkinLab_Data/SoftwareRepository/fsl/fsl_new/bin
#FNIRTDIR=/usr/local/fsl/bin

CONFDIR=${ANALYSIS_PIPE_DIR}/fnirt_fine_config/

MNI152=${FSLDIR}/data/standard/MNI152_T1_2mm
echo "Running FNIRT -level 1"

${FNIRTDIR}/fnirt --in=$myscan --ref=$MNI152 --config=${CONFDIR}/T1_2_MNI152_2mm.cnf --aff=$mymat --cout=${out}_warp1 --intout=${out}_intensities --iout=${out}_warped1

if [ $FINE = 1 ] ; then 

echo "Running FNIRT -level 2"

${FNIRTDIR}/fnirt --in=$myscan --ref=$MNI152 --config=${CONFDIR}/T1_2_MNI152_level2.cnf --inwarp=${out}_warp1 --intin=${out}_intensities --cout=${out}_warp2 --iout=${out}_warped2
echo "Running FNIRT -level 3"

#where T1_2_MNI152_level2.cnf can be found below. You can also daisychain it further with e.g. 

${FNIRTDIR}/fnirt --in=$myscan --ref=$MNI152 --config=${CONFDIR}/T1_2_MNI152_level3.cnf --inwarp=${out}_warp2 --intin=${out}_intensities --cout=${out}_warp3 --iout=${out}_warped3

${FSLDIR}/bin/immv ${out}_warped3 ${out}_warped
${FSLDIR}/bin/immv ${out}_warp3 ${out}_warp

else 
#rename last 
${FSLDIR}/bin/immv ${out}_warped1 ${out}_warped
${FSLDIR}/bin/immv ${out}_warp1 ${out}_warp

fi



if [ $DEBUG = 0 ] ; then 
${FSLDIR}/bin/imrm ${out}_warp2 ${out}_warped2 ${out}_warp2 ${out}_intensities ${out}_warp1 ${out}_warped1
fi