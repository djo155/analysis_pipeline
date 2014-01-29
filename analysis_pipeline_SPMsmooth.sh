#!/bin/sh 
#
#!/bin/sh
#input 1: JObdirectory
#input 2: jobname 
#input 3: Output directory, needs to be full path
#input 4...: Images to run on =


#####################################################################################################
#######################HERE ARE THE FUNCTIONS USED BY THIS SCRIPT####################################
#####################################################################################################
Usage() {
    echo ""
    echo "Usage:   analysis_pipeline_SPMsmooth_SPMmodel.sh  -func_data image.nii.gz -jobname <job_basename> -outdir <output_direcotry> image_files..."
    echo ""
    echo "-jobname : basename for job file names"
    echo "-outdir   : parent directory for output data (USE FULL PATH)"
    echo "-func_data : 4D functional data to run SPM models on "
    echo "-smooth_mm : FWHM of smooth kernel (default is 6 mm)"

    echo ""
    echo ""
    exit 1
}
#######################################   Create SPM job file    #####################################
#input 1 : design file
#input 2 : contrast file

function func_createSPM_JobFile_smooth {

    SMOOTH_MM=$1
    shift
#set input as variables
    JOBFILE=$1
    shift

#create SPM job file using simple echo commands
#MODEL SMOOTHING 

    {  #redirect the block into file at the end

        BATCH_IND=1


        image=`imglob -extension $1`
        NSCANS=`${FSLDIR}/bin/fslnvols $image`
        if [ $# -gt 0 ] ;then
# echo "matlabbatch{${BATCH_IND}}.spm.stats.fmri_spec.sess.scans = {"
            echo "matlabbatch{${BATCH_IND}}.spm.spatial.smooth.data = {"
            #>> ${JOBFILE}
            time=1
            while [ $time -le $NSCANS ]; do
        echo "'${image},${time}'"                          # >> ${JOBFILE}
            let time+=1
            done
        echo "};"                           #>> ${JOBFILE}
        fi

        echo "%%"
        echo "matlabbatch{${BATCH_IND}}.spm.spatial.smooth.fwhm = [${SMOOTH_MM} ${SMOOTH_MM} ${SMOOTH_MM}];"
        echo "matlabbatch{${BATCH_IND}}.spm.spatial.smooth.dtype = 0;"
        echo "matlabbatch{${BATCH_IND}}.spm.spatial.smooth.im = 0;"
        echo "matlabbatch{${BATCH_IND}}.spm.spatial.smooth.prefix = 's';"
        
    } > ${JOBFILE}

    echo "Done writing SPM job file,${JOBFILE}, for smoothing"

    echo 0
}
###########################################################################################
##############################END OF FUNCTIONS ############################################
###########################################################################################

#all input options need to start with "-"

#These variables store IO options
jobname=""
OUTPUTDIR=""

#these variables control which portions of the pipeline to
SMOOTH_MM=6;#in mm
VERBOSE=0;
while [ _${1:0:1} = _- ] ; do 
    if [ ${1} = -jobname ] ; then
	jobname=`readlink -f $2`
	shift 2
	
    elif [ ${1} = -outdir ] ; then 
	OUTPUTDIR=`readlink -f $2`
	shift 2
	
    elif [ ${1} = -func_data ] ; then 
        FUNC_DATA=`readlink -f $2`
        FUNC_DATA=`remove_ext $FUNC_DATA`
        shift 2
        
    elif [ ${1} = -smooth_mm ] ; then 
        SMOOTH_MM=$2
        shift 2
    elif [ ${1} = -v ] ; then
        VERBOSE=$2
        shift 2
    else
	echo "Unrecognized option: ${1}"
	exit 1
    fi
done

if [ $VERBOSE = 1 ] ; then
    echo "Smoothing ${FUNC_DATA}"
fi
#create job file

        #append .spm for for spm process data
# OUTPUTDIR=${FUNC_DATA}.spm
mkdir -p $OUTPUTDIR

if [ "_${jobname}" = _ ] ; then 
    echo "Jobname cannot be blank. "
    exit 1
fi

######DONE CHECKS

IMS_TO_CLEANUP=""
    #Finally, let's do some processing
export FSLOUTPUTTYPE=NIFTI
    #remove any prevous existing images

#always doing the splitting, this is good in case something different done to prefiltered func

#clean up any existing images
#==============================================
#===== is this really needed? =================
existing_ims=`imglob ${OUTPUTDIR}/fmri_grot*`
Nims=`echo $existing_ims | wc | awk '{ print $2 }'`
if [ $Nims -gt 0 ] ; then
    if [ $VERBOSE = 1 ] ; then
        echo "Removing existing files"
    fi

    ${FSLDIR}/bin/imrm $existing_ims
fi
#==============================================
#== why not just do:
# rm -f ${OUTPUTDIR}/fmri_grot*
#==============================================


    #break up 4D file for spm processing
#if [ $VERBOSE = 1 ] ; then
#echo "Splitting 4D NIFTI for SPM processing"
#fi
#fslsplit $FUNC_DATA ${OUTPUTDIR}/fmri_grot
#    #need to include extension to process with spm
#FUNC_DATA_3D=`imglob -extensions ${OUTPUTDIR}/fmri_grot*`

    #Keeping track of stuff to clean as I go 
#IMS_TO_CLEANUP="${IMS_TO_CLEANUP} ${FUNC_DATA_3D}"
# echo $IMS_TO_CLEANUP

func_createSPM_JobFile_smooth $SMOOTH_MM ${jobname} $FUNC_DATA
#if [ $VERBOSE = 1 ] ; then
#    echo "done creating jobfile $?"
#fi

if [ $? -ne 0 ] ; then
   echo "Failed to create SPM job file"
   exit 1
fi

#create run script and call with matlab
dirj=`dirname $jobname` 
fj=`basename $jobname .m`
fj_run=${dirj}/run_${fj}
${ANALYSIS_PIPE_DIR}/analysis_pipeline_createSPM_batch_script.sh ${fj_run}.m $jobname
echo "run smoothing : cd ${dirj} ; pwd; run_${fj} | matlab  -nodesktop -nodisplay -nosplash"
    #--run the matlab script
CURDIR=`pwd`
cd $dirj
echo "cd ${dirj} ; pwd; run_${fj}" | matlab  -nodesktop -nosplash -nodisplay
cd $CURDIR

    #lets write to a file the 3D smoothed images for processing further down the pipeline
    #this will write over any existing file

#for i in $FUNC_DATA_3D ; do
#    tempd=`dirname $i`
#    tempf=`basename $i`
#    echo ${tempd}/s${tempf}
#done > ${jobname}_ims3d.txt

#remove split data, smooth data is still as 3D files

#${FSLDIR}/bin/imrm ${IMS_TO_CLEANUP}













