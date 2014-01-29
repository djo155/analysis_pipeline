#!/bin/sh
#this script creates and runs spm jobs
#beware this will rmeove SPM.mats

###################################################################################################################
#######################HERE ARE THE FUNCTIONS USED BY THIS SCRIPT#####################################
###################################################################################################################
Usage() {
echo ""
echo "Usage:   analysis_pipeline_slice_timing_mc.sh -func_data <functional_data> -outdir <output_directory> -jobname <jobfile> -tr <tr> -ta <ta>"
echo ""
echo ""
echo "-func_data : 4D functional data "
echo "-jobname : name of spm job file"
echo "-outdir : output directort"
echo "-tr : TR for functional data"
echo "-v : verbose "
echo ""
echo "***There is less error checking for exosting files in this script, leaving it up to parent script"
exit 1
}

function func_createSPM_JobFile_slicetiming_mc {

    JOBFILE=$1			#name of job file
    echo "jobfile " $JOBFILE
    shift
    TR=$1 #2
    shift 
    TA=$1
    shift
    #get number of slices
    #$1 if first input image
    Nz=`fslinfo $1 | grep -m 1 dim3 | awk '{ print $2 }'`
    #--calculate tA : TR - (TR/Nslices)
#if it is zero it has not been set, otherwise its been explictkly set'
	echo "Slicetiming $TR $TA $Nz"
    if [ $TA = 0 ] ; then 
		echo $TA
        TA=`echo "${TR} - (${TR}/${Nz})" | bc -l`
    fi

    echo "TA is set to ${TA}"
    echo "%-----------------------------------------------------------------------" >> ${JOBFILE}
    echo "% Job configuration created by analysis_pipeline          "				>> ${JOBFILE}
    echo "%-----------------------------------------------------------------------" >> ${JOBFILE}

    echo "matlabbatch{1}.spm.temporal.st.scans = { {"									>> ${JOBFILE}

    #input data here 
    #make sure there's at least time point
    if [ $# -gt 0 ] ;then 
        #  echo "matlabbatch{${BATCH_IND}}.spm.stats.fmri_spec.sess.scans = {">> ${JOBFILE}
        for image in $@ ; do 
            echo $image
            echo "'${image},1'"                           >> ${JOBFILE}
        done
    fi
    echo "}' };"																		>> ${JOBFILE}

    echo "%%"																		>> ${JOBFILE}

    echo "matlabbatch{1}.spm.temporal.st.nslices = ${Nz};"								>> ${JOBFILE}
    echo "matlabbatch{1}.spm.temporal.st.tr = ${TR};"									>> ${JOBFILE}
    echo "matlabbatch{1}.spm.temporal.st.ta = ${TA};"					>> ${JOBFILE}
#lets make this generic and for down-up timing correction
    SLICE_ORDER="["
    z=1;
    while [ $z -le $Nz ] ; do 
        SLICE_ORDER="${SLICE_ORDER} $z"
        let z+=1
    done
     SLICE_ORDER="${SLICE_ORDER} ]"
    echo "matlabbatch{1}.spm.temporal.st.so = ${SLICE_ORDER};"					>> ${JOBFILE}
    echo "matlabbatch{1}.spm.temporal.st.refslice = 1;"								>> ${JOBFILE}
    echo "matlabbatch{1}.spm.temporal.st.prefix = 'a';"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.data{1}(1) = cfg_dep;"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.data{1}(1).tname = 'Session';"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.data{1}(1).tgt_spec{1}(1).name = 'filter';"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.data{1}(1).tgt_spec{1}(1).value = 'image';"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.data{1}(1).tgt_spec{1}(2).name = 'strtype';"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.data{1}(1).tgt_spec{1}(2).value = 'e';"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.data{1}(1).sname = 'Slice Timing: Slice Timing Corr. Images (Sess 1)';"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.data{1}(1).src_exbranch = substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1});"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.data{1}(1).src_output = substruct('()',{1}, '.','files');"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.sep = 4;"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.rtm = 1;"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.interp = 2;"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.weight = {''};"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.roptions.which = [2 1];"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.roptions.interp = 4;"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.roptions.mask = 1;"								>> ${JOBFILE}
    echo "matlabbatch{2}.spm.spatial.realign.estwrite.roptions.prefix = 'r';"								>> ${JOBFILE}


}

###################################################################################################################
##############################END OF FUNCTIONS ############################################
###################################################################################################################





#all input options need to start with "-"

#These variables store IO options
jobname=""
OUTPUTDIR=""
TR=0
TA=0
VERBOSE=0
#TA=1.93103448275862

while [ _${1:0:1} = _- ] ; do 
    if [ ${1} = -jobname ] ; then
        jobname=$2
        shift 2
   elif [ ${1} = -outdir ] ; then 
       OUTPUTDIR=`readlink -f $2`
        shift 2
    elif [ ${1} = -outname ] ; then 
        OUTPUTNAME=`readlink -f $2`
        shift 2
    elif [ ${1} = -func_data ] ; then 
        FUNC_DATA=`readlink -f $2`
        FUNC_DATA=`remove_ext $FUNC_DATA`
        shift 2
    elif [ ${1} = -tr ] ; then 
        TR=$2
		echo "set TR $TR"
        shift 2
	elif [ ${1} = -ta ] ; then 
        TA=$2
		echo "Set TA $TA"
        shift 2
    elif [ ${1} = -v ] ; then          
        VERBOSE=1
       shift 1
    else
        echo "Unrecognized option: ${1}"
        exit 1
    fi
done

#----------do some directory management stuff-------//

# OUTPUTDIR=${FUNC_DATA}.spm
if [ ! -d $OUTPUTDIR ] ; then 
    /bin/mkdir $OUTPUTDIR
fi

if [ -f ${jobname} ] ;then 
    echo "Job, ${jobname}, file already exists. Removing..."
    /bin/rm ${jobname}
fi
#-----------done dir/file management--------------/

#----------let convert 4D data to -> 3D for SPM -------//

    export FSLOUTPUTTYPE=NIFTI
    #--remove any prevous existing images
    existing_ims=`imglob ${OUTPUTDIR}/fmri_grot*`
    Nims=`echo $existing_ims | wc | awk '{ print $2 }'`
    if [ $Nims -gt 0 ] ; then
        if [ $VERBOSE = 1 ] ; then 
            echo ""
            echo "Removing existing files"
        fi
        ${FSLDIR}/bin/imrm $existing_ims
    fi
    #--break up 4D file for spm processing
    if [ $VERBOSE = 1 ] ; then 
        echo ""
        echo "Splitting 4D NIFTI for SPM processing"
    fi
    fslsplit $FUNC_DATA ${OUTPUTDIR}/fmri_grot
    #--need to include extension to process with spm
    FUNC_DATA_3D=`imglob -extensions ${OUTPUTDIR}/fmri_grot*`

    #---Keeping track of stuff to clean as I go 
    IMS_TO_CLEANUP="${IMS_TO_CLEANUP} ${FUNC_DATA_3D}"

    func_createSPM_JobFile_slicetiming_mc $jobname $TR  $TA $FUNC_DATA_3D

    dirj=`dirname $jobname` 
    fj=`basename $jobname`
    fj_run=${dirj}/run_${fj}
    ${ANALYSIS_PIPE_DIR}/analysis_pipeline_createSPM_batch_script.sh ${fj_run} $jobname

    #--run the matlab script
    CURDIR=`pwd`
    cd $dirj
    echo "run_${fj}" | matlab  -nodesktop  -nodisplay -nosplash
    cd $CURDIR
    

    #--clean up 3D files
    if [ $VERBOSE = 1 ] ; then 
        echo ""  
        echo "Cleaning up files..."
    fi

    ${FSLDIR}/bin/imrm $IMS_TO_CLEANUP
    for i in $FUNC_DATA_3D ; do
        dmc=`dirname $i`
        fmc=`basename $i` 
        #remove ims for just slicetiming
        ${FSLDIR}/bin/imrm ${dmc}/a${fmc}
        mc_ims="$mc_ims ${dmc}/ra${fmc}"
    done

    if [ $VERBOSE = 1 ] ; then 
        echo ""
        echo "Merging data into 4D NIFTI"
    fi


    #--Merge data into single 4D image
    export FSLOUTPUTTYPE=NIFTI_GZ
    ${FSLDIR}/bin/fslmerge -t $OUTPUTNAME $mc_ims

#uses output name to name the motion parameters
    fout=`basename $OUTPUTNAME`
    fout=`${FSLDIR}/bin/remove_ext $fout`
    #rename motion parameters, I like FSL names
    /bin/mv ${OUTPUTDIR}/rp_afmri_grot0000.txt ${OUTPUTDIR}/${fout}_mcf.par.txt

    if [ $VERBOSE = 1 ] ; then 
        echo ""
        echo "Removing 3D NIFTIs from ${OUTPUTDIR}/..."
    fi
    ${FSLDIR}/bin/imrm $mc_ims ${OUTPUTDIR}/meanafmri_grot0000 
    






