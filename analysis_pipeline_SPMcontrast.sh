#!/bin/sh 
#
#!/bin/sh
#input 1: JObdirectory
#input 2: jobname 
#input 3: Output directory, needs to be full path
#input 4...: Images to run on =




###################################################################################################################
#######################HERE ARE THE FUNCTIONS USED BY THIS SCRIPT#####################################
###################################################################################################################
Usage() {
echo ""
echo "Usage:   analysis_pipeline_SPMsmooth_SPMmodel.sh  -func_data image.nii.gz -jobname <job_basename> -outdir <output_direcotry> image_files..."
echo ""
echo "-jobname : basename for job file names"
echo "-outdir   : parent directory for output data (USE FULL PATH)"
echo "-spm_contrast : A contrast script from SPM. You can use their GUI, the save script."
echo "-func_data : 4D functional data to run SPM models on "
echo "-design : Design Files "
echo "-motion : Motion file "
echo "-t1_brain : driectory containing 4x4 XFM matrices from functional to structural space."
echo "-smooth_mm : FWHM of smooth kernel (default is 6 mm)"

echo ""
echo ""
exit 1
}

#######################################   Create SPM job file    ########################################
#input 1 : design file
#input 2 : contrast file

function func_createSPM_JobFile_smooth_model {
echo "Entering function to create Job file"

SMOOTH_MM=$1
shift
#set input as variables
DESIGN=$1
shift
CONTRAST=$1
shift
JOBFILE=$1
shift
SPMDIR=$1 #where to put everything
shift
if [ ! $6 = 0 ] ; then
MOTION_PARAMS=$6
shift
fi

echo "Contrast $CONTRAST"

if [ ! -f $CONTRAST ] ; then 
echo "Contrast file, $CONTRAST, does not exist...exiting"
exit 1
fi
#remove job file if it exists
if [ -f $JOBFILE ] ; then 
    rm $JOBFILE
fi

#create SPM job file using simple echo commands
#MODEL SMOOTHING 
BATCH_IND=1
#the last portion oif this is to make sure the batch index is correct
cat ${CONTRAST}  | sed "s/<UNDEFINED>/${SPMDIR}/g" > ${JOBFILE}


}



###################################################################################################################
##############################END OF FUNCTIONS ############################################
###################################################################################################################







#all input options need to start with "-"

#These variables store IO options
jobname=""
OUTPUTDIR=""
MOTION_FILE=0

#these variables control which portions of the pipeline to
required=0
SMOOTH_MM=6;#in mm
SPM_CON_FILE=""

while [ _${1:0:1} = _- ] ; do 
	if [ ${1} = -jobname ] ; then
		jobname=$2
		shift 2
		let required+=1
	elif [ ${1} = -outdir ] ; then 
		OUTPUTDIR=$2
		shift 2
		let required+=1

    elif [ ${1} = -func_data ] ; then 
        FUNC_DATA=`remove_ext $2`
        shift 2
        let required+=1
    elif [ ${1} = -design ] ; then 
        DESIGN_FILE=$2
        shift 2
        let required+=1
    elif [ ${1} = -motion ] ; then 
        MOTION_FILE=$2
        shift 2
        let required+=1
    elif [ ${1} = -spm_contrast ] ; then 
        SPM_CON_FILE=$2
        shift 2
elif [ ${1} = -smooth_mm ] ; then 
SMOOTH_MM=$2
shift 2
let required+=1
	else
		echo "Unrecognized option: ${1}"
		exit 1
	fi
done

echo "process functional data ${FUNC_DATA}"

#create job file

        #append .spm for for spm process data
# OUTPUTDIR=${FUNC_DATA}.spm
if [ ! -d $OUTPUTDIR ] ; then 
    mkdir $OUTPUTDIR
fi



#BEFORE MOVING FORWARD LETS MAKE SURE EBERYTHING EXISTS
if [ ! -f $DESIGN_FILE ] ; then 
    echo "Missing design file. "
    exit 1
fi
if [ ! -f $SPM_CON_FILE ] ; then 
    echo "Missing contrast file. $SPM_CON_FILE "
    exit 1
fi

if [  ! $MOTION_FILE = 0 ] ; then 
    if [ ! -f $MOTION_FILE ] ; then 
        echo "Missing motion file. ${MOTION_FILE}"
        exit 1
    fi
fi

if [ "_${jobname}" = _ ] ; then 
    echo "Jobname cannot be blank. "
    exit 1
fi


  

#${FSLDIR}/bin/imrm ${IMS_TO_CLEANUP}













