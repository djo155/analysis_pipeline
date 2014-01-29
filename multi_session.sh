#!/bin/sh 
#output name
#inout #of sessions files
#input 4D time series
#input regressers
function Usage(){
        echo "\n\n"
        echo "multi_session.sh [ppi options] [--ppi_only] [--appendToExisting ] [-func_mask mask.nii.gz] <output_dir> <NumberOfVolumesToDelete> <TR> <struct_only dir> <SPM_contrast_file> <use_motion_in_model> <N_Sessions> <images> <regressors>"
echo "***Use full paths"
echo "-modelName <modelName>"
echo "--nopreproc"
echo "PPI options : "
echo "-ppi_masks"
echo "--ppi_cons"
echo "--ppi_only : don't run models just ppi"
        echo "\n\n"
        exit 1
}
PPI_CONS=""
PPIOPT=1
DOPPI=0
PPIONLY=0
APPEND=0;
  NOPREPROC=0
modelName=multi_session
#this is above ancd below as a quick fix so it doesnt matter if before or after ppi toions
if [ $1 = "--ppi_only" ] ; then
    PPIONLY=1
    shift 1
fi

if [ $1 = "--appendToExisting" ] ; then
    APPEND=1
    shift 1
fi


while [ $PPIOPT = 1 ] ; do 
    PPIOPT=0
    echo PPI OPTIONS $1
    if [ ${1} = -ppi_masks ] ; then 
        PPIOPT=1

        shift 1
	
        #read all mask to sue for PPI
        DOPPI=1
        while [ ! ${1:0:1} = - ] ; do 
            im=`readlink -f $1`
            if [ `${FSLDIR}/bin/imtest $im` = 0 ] ; then 
                echo "Invalid PPI mask : $im"
                exit 1
            fi
            im=`${FSLDIR}/bin/remove_ext $im`
            PPI_MASKS="${PPI_MASKS} ${im}"
            PPI_MASKS_HIGHRES="${PPI_MASKS_HIGHRES} 0"
            shift
            if [ $# -eq 0 ] ; then 
                break;
            fi
        done
        echo "PPI mask list : " $PPI_MASKS
        let PPI_COUNT+=1
    elif [ ${1} = -ppi_cons ] ; then 
        PPIOPT=1
        PPI_CONS=`echo $2 | sed 's/,/ /g'`
        let PPI_COUNT+=1
        shift 2
    fi
done
if [ $1 = "--ppi_only" ] ; then
    PPIONLY=1
    shift 1
fi

if [ $1 = "--appendToExisting" ] ; then
    APPEND=1
    shift 1
fi
echo func mask $1

if [ $1 = "-func_mask" ] ; then
    MASK=$2
    shift 2
fi
if [ $1 = "-modelName" ] ; then
    modelName=$2
    shift 2
fi

if [ $1 = "--nopreproc" ] ; then
    NOPREPROC=1
    shift 1
fi

echo Non-PPI options $@

if [ $# = 0 ] || [ $# -lt 11 ] ; then
    echo "Incorrect number of inputs, $#"
    Usage
fi

OUTPUT=$1
if [ $APPEND = 0 ]; then
    while [ -d $OUTPUT ] ; do 
        OUTPUT=${OUTPUT}+
    done
fi
/bin/mkdir -p ${OUTPUT}
/bin/mkdir ${OUTPUT}/logs

echo OUTPUT $OUTPUT

OUTPUT=`readlink -f $OUTPUT`

shift 1
DVOLS=$1
shift 1
TR=$1
shift 
echo $1
if [ ! -d $T1DIR ] ; then 
    echo "$T1DIR is not a directory"
    Usage
fi
T1DIR=`readlink -f $1`
echo t1dir ${T1DIR}
shift 1
SPM_CON_FILE=`readlink -f $1`
shift


USE_MOTION=$1
shift 1


N_SESSIONS=$1
shift 1
echo "Output Directory : ${OUTPUT}"
echo "Number of Sessions : ${N_SESSIONS}"
echo "analysis_pipeline.sh options : $@"
SERIAL=0

#read images
count=0
while [ $count -lt $N_SESSIONS ] ; do
    fim=`readlink -f $1`
    func_ims="$func_ims $fim"
    if [ `${FSLDIR}/bin/imtest $fim` = 0 ] ; then
        echo "Invalid image $fim"
        exit 1
    fi
    shift 1
    let count+=1
done
echo Sessions Images : $func_ims

#read regressors
count=0
while [ $count -lt $N_SESSIONS ] ; do 
    regs="$regs $1"
    shift 1
    let count+=1
done
echo "done reading regressors"

PIPE_CMDS=$@
#the rest are analysis pipeline options.
echo "PIPE_CMDS ${PIPE_CMDS}"

#set up sess dirs 
SESSDIRS=""
count=1
for i in $func_ims ; do
    fbase=`basename $i`
    fbase=`${FSLDIR}/bin/remove_ext $fbase`
    SESSDIRS="${SESSDIRS} ${OUTPUT}/${fbase}.sess${count}"
    let count+=1

done

if [ $PPIONLY = 0 ] ; then
    echo "Run multi-session model..."
    count=1
    MATS=""
    for i in $func_ims ; do 
            echo $count
            echo $regs
            echo $regs | awk "{ print \$$count }" > ${OUTPUT}/grot_regs
            DESIGN=`cat ${OUTPUT}/grot_regs`
            echo $DESIGN
            fbase=`basename $i`
            fbase=`${FSLDIR}/bin/remove_ext $fbase`
	    
            echo FBASE $fbase $i
            echo "$i -> ${OUTPUT}/${fbase}.sess${count} " >> ${OUTPUT}/sessions_naming.log
            if [ $SERIAL = 1 ] ; then 
                echo   ${ANALYSIS_PIPE_DIR}/analysis_pipeline.sh  -t1 ${T1DIR}/struct/orig -reg_info $T1DIR -deleteVolumes ${DVOLS} -tr ${TR} -no_model -no_contrast -func_data $i -design ${DESIGN} -outdir ${OUTPUT} -output_extension sess${count} $PIPE_CMDS
                fD=`basename $DESIGN .mat`
                
                cp $DESIGN ${OUTPUT}/${fD}.sess${count}.mat 
                MATS="${MATS} ${OUTPUT}/${fD}.sess${count}.mat"
                SESSDIRS="${SESSDIRS} ${OUTPUT}/${fbase}.sess${count}"
            else
		
		fD=`basename $DESIGN .mat`
		echo "cp $DESIGN ${OUTPUT}/${fD}.sess${count}.mat "
		cp $DESIGN ${OUTPUT}/${fD}.sess${count}.mat 
	
		echo "${ANALYSIS_PIPE_DIR}/analysis_pipeline.sh  -t1 ${T1DIR}/struct/orig -reg_info $T1DIR -deleteVolumes ${DVOLS} -tr ${TR} -no_model -no_contrast -func_data $i -design ${DESIGN} -outdir ${OUTPUT} -output_extension sess${count} $PIPE_CMDS" >> ${OUTPUT}/pre_proc.cmds
                MATS="${MATS} ${OUTPUT}/${fD}.sess${count}.mat"
#        SESSDIRS="${SESSDIRS} ${OUTPUT}/${fbase}.sess${count}"
		
            fi
	    
            let count+=1
    done    
    
    echo Session Directories $SESSDIRS
    
    
    if [ ! -d ${OUTPUT}/${modelName}.spm ] ; then 
        /bin/mkdir ${OUTPUT}/${modelName}.spm
    fi
fi
    if [ $SERIAL = 0 ] ; then
        if [ $PPIONLY = 0 ] ; then

            if [ ! -d ${OUTPUT}/${modelName}.spm/spm_jobs ] ; then
            mkdir ${OUTPUT}/${modelName}.spm/spm_jobs
            fi
            if [ ! -d ${OUTPUT}/${modelName}.spm/reg ] ; then
            mkdir ${OUTPUT}/${modelName}.spm/reg
            fi

if [ $NOPREPROC = 0 ]; then
            PREPROC_ID=`fsl_sub -l ${OUTPUT}/logs -N pre_proc_multiSess -q spm.q -t ${OUTPUT}/pre_proc.cmds`
            #xfm to common space
            XFM_CMDS1=${OUTPUT}/${modelName}.spm/xfm1.cmds
            XFM_CMDS2=${OUTPUT}/${modelName}.spm/xfm2.cmds
            XFM_CMDS3=${OUTPUT}/${modelName}.spm/xfm3.cmds
            MASK_CMD=${OUTPUT}/${modelName}.spm/func_mask.sh
            echo '#!/bin/sh' > $MASK_CMD
            chmod a+x $MASK_CMD
            echo hostname >> $MASK_CMD

            s=1
            for i in $SESSDIRS ; do
            if [ $s -ne 1 ] ; then
            echo "Not first session : $i "
            echo "convert_xfm -omat ${OUTPUT}/${modelName}.spm/reg/sess${s}_2_sess1.mat  -concat ${ref}/reg/highres2example_func.mat ${i}/reg/example_func2highres.mat" >> $XFM_CMDS1
            echo "flirt -in ${i}/prefiltered_func_data  -out ${i}/prefiltered_func_data_2_sess1 -ref ${ref}/prefiltered_func_data_2_sess1 -applyxfm -init ${OUTPUT}/${modelName}.spm/reg/sess${s}_2_sess1.mat" >> $XFM_CMDS2
            echo "imrm ${i}/prefiltered_func_data" >> $XFM_CMDS3


            else
            ref=$i
            echo "${FSLDIR}/bin/flirt -in ${i}/struct/brain_fnirt_mask -ref ${i}/example_func.nii.gz  -applyxfm -init ${i}/reg/highres2example_func.mat -out ${OUTPUT}/${modelName}.spm/brain_fnirt_mask_func -datatype float" >> $MASK_CMD
            #                ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/${MODEL_NAME}.spm/brain_fnirt_mask_func -bin ${OUTPUTDIR}/${MODEL_NAME}.spm/brain_fnirt_mask_func -odt short
            echo "${FSLDIR}/bin/fslchfiletype NIFTI ${OUTPUT}/${modelName}.spm/brain_fnirt_mask_func" >> $MASK_CMD
            if [ ! _$MASK = "_" ] ; then
            MASK="${OUTPUT}/${modelName}.spm/brain_fnirt_mask_func.nii"
            fi
            echo "immv ${i}/prefiltered_func_data ${i}/prefiltered_func_data_2_sess1">>$XFM_CMDS1
            fi
            let s+=1
            done
            #do models
            #${ANALYSIS_PIPE_DIR}/multi_session_createSPMjob.sh ${OUTPUT}/${modelName}.spm  spm_model ${N_SESSIONS} ${SESSDIRS} ${MATS}


            MASKID=`$FSLDIR/bin/fsl_sub -q short.q -l ${OUTPUT}/logs -T 10 -N createFuncMask -j $PREPROC_ID $MASK_CMD`

            XFMID1=`$FSLDIR/bin/fsl_sub -q short.q -l ${OUTPUT}/logs -T 10 -N xfm2s1-1 -j $MASKID -t $XFM_CMDS1`
            XFMID2=`$FSLDIR/bin/fsl_sub -q short.q -l ${OUTPUT}/logs -T 10 -N xfm2s1-2 -j $XFMID1 -t $XFM_CMDS2`
            XFMID3=`$FSLDIR/bin/fsl_sub -q short.q -l ${OUTPUT}/logs -T 10 -N xfm2s1-3 -j $XFMID2 -t $XFM_CMDS3`
else

        MASK_CMD=${OUTPUT}/${modelName}.spm/func_mask.sh
        echo '#!/bin/sh' > $MASK_CMD
        chmod a+x $MASK_CMD
        echo hostname >> $MASK_CMD

        s=1
        for i in $SESSDIRS ; do
        if [ $s -ne 1 ] ; then
            echo "Not first session : $i "


        else
        ref=$i
        echo "${FSLDIR}/bin/flirt -in ${i}/struct/brain_fnirt_mask -ref ${i}/example_func.nii.gz  -applyxfm -init ${i}/reg/highres2example_func.mat -out ${OUTPUT}/${modelName}.spm/brain_fnirt_mask_func -datatype float" >> $MASK_CMD
        #                ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/${MODEL_NAME}.spm/brain_fnirt_mask_func -bin ${OUTPUTDIR}/${MODEL_NAME}.spm/brain_fnirt_mask_func -odt short
        echo "${FSLDIR}/bin/fslchfiletype NIFTI ${OUTPUT}/${modelName}.spm/brain_fnirt_mask_func" >> $MASK_CMD
        if [ ! _$MASK = "_" ] ; then
            MASK="${OUTPUT}/${modelName}.spm/brain_fnirt_mask_func.nii"
        fi
            echo "immv ${i}/prefiltered_func_data ${i}/prefiltered_func_data_2_sess1">>$XFM_CMDS1
        fi
        let s+=1
        done
        #do models
        #${ANALYSIS_PIPE_DIR}/multi_session_createSPMjob.sh ${OUTPUT}/${modelName}.spm  spm_model ${N_SESSIONS} ${SESSDIRS} ${MATS}


        XFMID3=`$FSLDIR/bin/fsl_sub -q short.q -l ${OUTPUT}/logs -T 10 -N createFuncMask $MASK_CMD`

fi

            echo Run model
if [ `imtest $MASK` = 0 ]; then
    MASK="${OUTPUT}/${modelName}.spm/brain_fnirt_mask_func"
fi

            echo ${ANALYSIS_PIPE_DIR}/multi_session_createSPMjob.sh ${OUTPUT}/${modelName}.spm  spm_model ${N_SESSIONS} ${SESSDIRS} ${MATS} $USE_MOTION ${MASK}


            MODELID=`$FSLDIR/bin/fsl_sub -q spm.q -l ${OUTPUT}/logs -T 10 -N model -j $XFMID3 ${ANALYSIS_PIPE_DIR}/multi_session_createSPMjob.sh ${OUTPUT}/${modelName}.spm  spm_model ${N_SESSIONS} ${SESSDIRS} ${MATS} $USE_MOTION ${MASK}`


            echo "RUN CONTRAST $OUTPUT"
            readlink -f ${OUTPUT} | sed 's/\//\\\//g' >  ${OUTPUT}/${modelName}.spm/spm_jobs/grot
            full_out=`cat ${OUTPUT}/${modelName}.spm/spm_jobs/grot`
            /bin/rm ${OUTPUT}/${modelName}.spm/spm_jobs/grot
        
            echo FULL OUT $full_out
            cat ${SPM_CON_FILE}  | sed "s/'<UNDEFINED>'/{'${full_out}\/${modelName}.spm\/SPM.mat'}/g"
            cat ${SPM_CON_FILE}  | sed "s/'<UNDEFINED>'/{'${full_out}\/${modelName}.spm\/SPM.mat'}/g" > ${OUTPUT}/${modelName}.spm/spm_jobs/job_contrast.m
            echo "create run"
            ${ANALYSIS_PIPE_DIR}/analysis_pipeline_createSPM_batch_script.sh ${OUTPUT}/${modelName}.spm/spm_jobs/run_job_contrast.m ${OUTPUT}/${modelName}.spm/spm_jobs/job_contrast.m
            echo "echo \"cd ${OUTPUT}/${modelName}.spm/spm_jobs ; run_job_contrast\" | matlab -nodesktop -nodisplay -nosplash" > ${OUTPUT}/${modelName}.spm/spm_jobs/run_job_contrast.sh
        
            #input directory, func->struct, struct->mni warp
            if [ ! -d ${OUTPUT}/reg_standard/${modelName}.spm ] ; then 
                mkdir -p ${OUTPUT}/reg_standard/${modelName}.spm
            fi
            echo "multi_session_xfmCons.sh ${OUTPUT}/${modelName}.spm ${ref}/reg/example_func2highres.mat  ${ref}/reg/highres2standard_warp ${OUTPUT}/reg_standard/${modelName}.spm" > ${OUTPUT}/run_xfm_contrast.cmds
        

            # CONID=`$FSLDIR/bin/fsl_sub -q spm.q -l ${OUTPUT}/logs -T 10 -N contrast -j $MODELID echo "cd ${OUTPUT}/${modelName}.spm/spm_jobs ; run_job_contrast" | matlab -nodesktop -nosplash`
            run=`readlink -f ${OUTPUT}/${modelName}.spm/spm_jobs/run_job_contrast.sh`
            chmod a+x $run
            CONID=`${FSLDIR}/bin/fsl_sub -q spm.q -l ${OUTPUT}/logs -T 10 -N contrast -j $MODELID $run`
            XFMID4=`${FSLDIR}/bin/fsl_sub -q short.q -l ${OUTPUT}/logs -T 10 -N xfm_contrast -j $CONID -t ${OUTPUT}/run_xfm_contrast.cmds`


            echo "DONE CONTRAST"
        
            for i in $SESSDIRS ; do 
                echo "${FSLDIR}/bin/imrm ${i}/grot*.nii" >> ${OUTPUT}/cleanup.cmds
            done
            echo "submit cleanup"
            CLEANID=`$FSLDIR/bin/fsl_sub -l ${OUTPUT}/logs -T 10 -N cleanup -j $XFMID4 -t ${OUTPUT}/cleanup.cmds`
        fi
    echo "DO PPI NOW?"
    if [ $DOPPI = 1 ]; then 

        echo "DOING PPI "

   
        for MASK in $PPI_MASKS ; do
            echo PPI_MASKS $MASK
        #need to write over the split data so for timeseries extraction
        # I trick SPM here by changing the time-series data
            
            MASK=`readlink -f $MASK`
            fmask=`basename $MASK`
            fmask=`remove_ext $fmask`
            
            echo fmaks  $fmask
            
    #do VOI extraction for each session
            for con in $PPI_CONS ; do
                if [ ! -d  ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con} ] ; then
                    echo "Creating Driectory ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con} ..."
                            mkdir -p ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}
                fi


                PPICMDS1=${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/ppi1.cmds
                PPICMDS2=${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/ppi2.cmds
                PPICMDS3=${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/ppi3.cmds
                PPICMDS4=${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/ppi4.cmds
                PPICMDS5=${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/ppi5.cmds
                PPICMDS6=${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/ppi6.cmds
                PPICMDS_CLEANUP=${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/ppi_cleanup.cmds
                rm $PPICMDS1 $PPICMDS2 $PPICMDS3 $PPICMDS4 $PPICMDS5 $PPICMDS6 $PPICMDS_CLEANUP


                sess1dir=`echo $SESSDIRS | awk '{ print $1 }'`
                echo  "${FSLDIR}/bin/applywarp -i $MASK -r ${sess1dir}/example_func.nii.gz -o ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/${fmask}_native --postmat=${sess1dir}/reg/highres2example_func.mat -w ${sess1dir}/reg/standard2highres_warp"
                echo  "${FSLDIR}/bin/applywarp -i $MASK -r ${sess1dir}/example_func.nii.gz -o ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/${fmask}_native --postmat=${sess1dir}/reg/highres2example_func.mat -w ${sess1dir}/reg/standard2highres_warp" >> $PPICMDS1
                echo  "${FSLDIR}/bin/fslmaths ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/${fmask}_native -bin ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/${fmask}_native_bin" >> $PPICMDS2


                sess_count=1
                SESSIMS=""
                for sess in $SESSDIRS ; do
                    echo sessions $sess
                    echo con $con
                    echo "${FSLDIR}/bin/fslmaths ${sess}/prefiltered_func_data_2_sess1 -mul ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/${fmask}_native ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/prefiltered_func_data_ppi_sess${sess_count}" >> $PPICMDS3
                    SESSIMS="${SESSIMS} ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/prefiltered_func_data_ppi_sess${sess_count}"
                    let sess_count+=1
                done
                echo "cp ${OUTPUT}/${modelName}.spm/SPM.mat ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/ " >> $PPICMDS3
                #    fmask_ppi=`imglob -extension ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/${fmask}_native_bin`
                fmask_ppi="${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/${fmask}_native_bin.nii"

                echo "${ANALYSIS_PIPE_DIR}/analysis_pipeline_SPM_VOI.sh ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/run_voi.m ${fmask_ppi} ${con} ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/ ${fmask}_con_${con} ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/SPM.mat ${SESSIMS} ">> $PPICMDS4
                echo "cd ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/ ; echo run_voi | matlab -nodesktop -nosplash">> $PPICMDS4
                echo "rm ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/SPM.mat " >> $PPICMDS5
                echo "${ANALYSIS_PIPE_DIR}/analysis_pipeline_SPM_PPI.sh ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/run_ppi.m ${MASK}  ${con} ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/ ${fmask}_con_${con} ${OUTPUT}/${modelName}.spm/SPM.mat"  >> $PPICMDS5
                echo "cd ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/ ; echo run_ppi | matlab -nodesktop -nosplash">> $PPICMDS5
            
                if [ ! -d ${OUTPUT}/reg_standard/${modelName}.ppi/${fmask}_con_${con}/  ]; then
                    mkdir -p  ${OUTPUT}/reg_standard/${modelName}.ppi/${fmask}_con_${con}/
                fi
                echo  "${FSLDIR}/bin/applywarp -i ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/con_0001 -r ${FSLDIR}/data/standard/MNI152_T1_2mm -o ${OUTPUT}/reg_standard/${modelName}.ppi/${fmask}_con_${con}/con_0001_mni --premat=${sess1dir}/reg/example_func2highres.mat -w ${sess1dir}/reg/highres2standard_warp" >> $PPICMDS6
                echo  "${FSLDIR}/bin/applywarp -i ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/con_0002 -r ${FSLDIR}/data/standard/MNI152_T1_2mm -o ${OUTPUT}/reg_standard/${modelName}.ppi/${fmask}_con_${con}/con_0002_mni --premat=${sess1dir}/reg/example_func2highres.mat -w ${sess1dir}/reg/highres2standard_warp" >> $PPICMDS6


                export FSLOUTPUTTYPE=NIFTI
                if [ $PPIONLY = 0 ] ; then
                PPI1ID=`fsl_sub -q spm.q -l ${OUTPUT}/logs -N ppi1 -j $CLEANID -t $PPICMDS1`
                else
                PPI1ID=`fsl_sub -q spm.q -l ${OUTPUT}/logs -N ppi1 -t $PPICMDS1`

                fi
                PPI2ID=`fsl_sub -q spm.q -l ${OUTPUT}/logs -N ppi2 -j $PPI1ID -t $PPICMDS2`
                PPI3ID=`fsl_sub -q spm.q -l ${OUTPUT}/logs -N ppi3 -j $PPI2ID -t $PPICMDS3`
                PPI4ID=`fsl_sub -q spm.q -l ${OUTPUT}/logs -N ppi4 -j $PPI3ID bash $PPICMDS4`
                PPI5ID=`fsl_sub -q spm.q -l ${OUTPUT}/logs -N ppi5 -j $PPI4ID bash $PPICMDS5`
                PPI6ID=`fsl_sub -q spm.q -l ${OUTPUT}/logs -N ppi6 -j $PPI5ID -t $PPICMDS6`

                PPI7ID=`fsl_sub -q spm.q -l ${OUTPUT}/logs -N cleanup -j $PPI6ID -t $PPICMDS_CLEANUP`

                export FSLOUTPUTTYPE=NIFTI_GZ


#end CON
            done
        # echo "${FSLDIR}/bin/fslsplit ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/prefiltered_func_data_ppi ${sess}/sfmri_grot" >> PPICMDS1
        #echo "rm ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/SPM.mat " >> $PPICMDS_CLEANUP
               echo "${FSLDIR}/bin/imrm ${OUTPUT}/${modelName}.ppi/${fmask}_con_${con}/prefiltered_func_data_ppi_sess${sess_count}" >> $PPICMDS_CLEANUP
                echo "Done session"
#end mask
        done

      
    fi


else
    echo "Other run multisssesion"
    ${ANALYSIS_PIPE_DIR}/multi_session_createSPMjob.sh ${OUTPUT}/${modelName}.spm  run_models ${N_SESSIONS} ${SESSDIRS} $USE_MOTION ${MATS}
fi

