#!/bin/sh

#  multi_session_createSPMjob.sh
#  
#
#  Created by Brian M. Patenaude on 2/29/12.
#  Copyright 2012 __MyCompanyName__. All rights reserved.
function Usage(){
echo "\n\n"
echo "multi_session_createSPMjob.sh <rootdir> <jobname(no path)> <TR> <N_Sessions> <session_dirs> <regressors> <use_motion> <mask>"
echo "if use_motion = 0 or 1 "
echo "\n\n"
exit 1
}

rootdir=`readlink -f $1`
shift 1
echo OUT - $OUT - $1 
OUT=`basename $1 .m`

#OUT=`echo $1 | sed 's/\.m//g'`
#remove m extension, will add back
echo OUT - $OUT - $1 

shift 1
TR=$1
shift 1
N_SESSIONS=$1
shift 1

#read images
count=0
while [ $count -lt $N_SESSIONS ] ; do 

func_ims="$func_ims `readlink -f $1`"
if [ `${FSLDIR}/bin/imtest ${1}/prefiltered_func_data_2_sess1` = 0 ] ; then
echo "Invalid image ${1}/prefiltered_func_data_2_sess1"
exit 1
else
    fslchfiletype NIFTI ${1}/prefiltered_func_data_2_sess1
fi
shift 1
let count+=1
done

#read regressors
count=0
while [ $count -lt $N_SESSIONS ] ; do 
regs="$regs `readlink -f $1`"
shift 1
let count+=1
done

USE_MOTION=$1
shift 1 

MASK=`readlink -f $1`

if [ ! -d ${rootdir}/spm_jobs ] ; then 
    /bin/mkdir -p ${rootdir}/spm_jobs
fi

JOBNAME=${rootdir}/spm_jobs/${OUT}_job.m 
RUNNAME=${rootdir}/spm_jobs/run_${OUT}_job.m

echo JOBNAME $JOBNAME


if [ -f $JOBNAME ] ; then 
    rm $JOBNAME
fi
if [ -f $RUNNAME ] ; then 
    rm $RUNNAME
fi

echo JOBRUN NAME $JOBNAME $RUNNAME

echo "%----------------------------------------------------------------------- ">>$JOBNAME
echo "% Job configuration created by cfg_util (rev $Rev: 4252 $) ">>$JOBNAME
echo "%----------------------------------------------------------------------- ">>$JOBNAME
echo "matlabbatch{1}.spm.stats.fmri_spec.dir = {'${rootdir}'}; ">>$JOBNAME
echo "matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs'; ">>$JOBNAME
echo "matlabbatch{1}.spm.stats.fmri_spec.timing.RT = ${TR}; ">>$JOBNAME
echo "matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16; ">>$JOBNAME
echo "matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1; ">>$JOBNAME
echo "%% ">>$JOBNAME
#loop aorund inputs (sessions)
export FSLOUTPUTTYPE=NIFTI
SESSION=1
echo func_ims $func_ims

for i in $func_ims ; do 
    DESIGN=`echo $regs | awk -v grot=$SESSION '{ print $grot }'`
#    echo Session $SESSION : $i : $DESIGN

    image=`imglob -extension ${i}/prefiltered_func_data_2_sess1`
    NSCANS=`${FSLDIR}/bin/fslnvols $image`
    echo "image $image $NSCANS"
#if [ $# -gt 0 ] ;then
        echo "matlabbatch{1}.spm.stats.fmri_spec.sess(${SESSION}).scans = { ">>$JOBNAME
        time=1
        while [ $time -le $NSCANS ]; do
            echo "'${image},${time}'"                           >> ${JOBNAME}
            let time+=1
        done
    echo "};"                           >> ${JOBNAME}

#fi


    echo "%% ">>$JOBNAME

    echo "matlabbatch{1}.spm.stats.fmri_spec.sess(${SESSION}).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}); ">>$JOBNAME

    echo "matlabbatch{1}.spm.stats.fmri_spec.sess(${SESSION}).multi = {'${DESIGN}'}; ">>$JOBNAME
    echo "matlabbatch{1}.spm.stats.fmri_spec.sess(${SESSION}).regress = struct('name', {}, 'val', {}); ">>$JOBNAME
if [ $USE_MOTION = 1 ]; then
    echo "matlabbatch{1}.spm.stats.fmri_spec.sess(${SESSION}).multi_reg = {'${i}/mc/prefiltered_func_data_mcf.par.txt'}; ">>$JOBNAME
else
    echo "matlabbatch{1}.spm.stats.fmri_spec.sess(${SESSION}).multi_reg = {''}; ">>$JOBNAME

fi
#    echo "matlabbatch{1}.spm.stats.fmri_spec.sess(${SESSION}).multi_reg = {'${MOTION_FILE}'}; ">>$JOBNAME
    echo "matlabbatch{1}.spm.stats.fmri_spec.sess(${SESSION}).hpf = 128; ">>$JOBNAME
    echo "%% ">>$JOBNAME

    let SESSION+=1 
done 

echo "matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {}); ">>$JOBNAME
echo "matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0]; ">>$JOBNAME
echo "matlabbatch{1}.spm.stats.fmri_spec.volt = 1; ">>$JOBNAME
echo "matlabbatch{1}.spm.stats.fmri_spec.global = 'None'; ">>$JOBNAME

if [ "_$MASK" = "_" ] ; then 
    echo "matlabbatch{1}.spm.stats.fmri_spec.mask = {''};"               >> ${JOBNAME}
else
    echo "matlabbatch{1}.spm.stats.fmri_spec.mask = {'${MASK},1'};"               >> ${JOBNAME}
fi


echo "matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)'; ">>$JOBNAME

echo "matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep;"                               >> ${JOBNAME}
echo "matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tname = 'Select SPM.mat';"					>> ${JOBNAME}
echo "matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(1).name = 'filter';"					>> ${JOBNAME}
echo "matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(1).value = 'mat';"					>> ${JOBNAME}
echo "matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(2).name = 'strtype';"					>> ${JOBNAME}
echo "matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(2).value = 'e';"					>> ${JOBNAME}
echo "matlabbatch{2}.spm.stats.fmri_est.spmmat(1).sname = 'fMRI model specification: SPM.mat File';"					>> ${JOBNAME}
echo "matlabbatch{2}.spm.stats.fmri_est.spmmat(1).src_exbranch = substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1});"					>> ${JOBNAME}
echo "matlabbatch{2}.spm.stats.fmri_est.spmmat(1).src_output = substruct('.','spmmat');"					>> ${JOBNAME}
echo "matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;"								>> ${JOBNAME}

#--run the matlab script
frun=`basename $RUNNAME .m`


analysis_pipeline_createSPM_batch_script.sh $RUNNAME $JOBNAME
hostname
echo "cd ${rootdir}/spm_jobs ; pwd ;  $frun"

echo "cd ${rootdir}/spm_jobs ; pwd ;  $frun" | matlab -nodesktop -nodisplay -nosplash

echo 

