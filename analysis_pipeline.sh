#!/bin/bash 
#
#!/bin/sh
#input 1: JObdirectory
#input 2: jobname
#input 3: Output directory, needs to be full path
#input 4...: Images to run on =
if [ "_${ANALYSIS_PIPE_DIR}" = "_" ] ; then
    echo "Please set environment variable ANALYSIS_PIPE_DIR before running this script"
    exit 1
fi





###################################################################################################################
#######################HERE ARE THE FUNCTIONS USED BY THIS SCRIPT#####################################
###################################################################################################################
Usage() {
    echo ""
    echo "Usage:   analysis_pipeline -func_data <func_data.nii.gz> [ options ] "
    echo ""
    echo "-func_data : 4D functional data to run SPM models on "
    echo "-func_data_mask : mask for 4D functional data to run SPM models on "

    echo "-deleteVolumes <Nvolumes> :  number of volumes"
    echo "-tr : TR of functional data (default = 2 seconds). "
    echo "-ta : Specifes TA for slice timing correction, if not specifed will use TR-TR/Nslices. "

    echo "-t1 <image.nii.gz> : T1-weighted structural image."
    echo "-outdir <output_directour> : Directory where to stick output"
    echo "-brain_extract_only   : Only do brain extraction. Useful for optimizing bet parameters"
    echo "-bet_opts   : Options to pass into FSL's BET. Must be in quotation (e.g. -bet_opts \"-f 0.1 -g 0.2\"). "
    echo "-bet_mask   : input mask instead of BET."
    echo "-bet_edit_mask   : input mask for bad BETting (masks bet output)."

    echo "-appendToAnalysis <directory>  : Do brain extraction. This needs to be run as a first step."
    echo "-output_extension <name> : Output directory extension for analysis. "
    echo "-spm_contrast : A contrast script from SPM. You can use their GUI, the save script."
    echo "-bet_only   : turn off BET (assume it has already been done)."
    echo "-glm_only   : turn off all other preprocessing"
    echo "-ppi_only   : turn off all other preprocessing"
    echo "-ppi_and_reg_only   : turn off all other preprocessing except registration steps (normally used to copy in existing stuctural processing)"
    echo "-ppi_first_masks : SPecify FIRST structures. e.g. L_Amyg R_Amyg"
    echo "-ppi_masks : Specify mask images (MNI)."
    echo "-ppi_cons : Comma separated contrast numbers"
    echo "-no_bbr   : turn off BBR EPI->highres"
    echo "-xfmUsingLinear : Use FLIRT instead of FNIRT for highres-> mni transform. FNIRT will still be used for global signal."
    echo "-reg_info <directory> : use previous directory to pull out structual info "
    echo "-no_bet   : turn off BET (assume it has already been done)."
    echo "-no_delvols   : Overides -deleteVolumes, needed to prevent writing over the processed data."
    echo "-no_motion_correction   : turn off slice timing and motion correction."
    echo "-no_reg   : turn off REG (assume it has already been done)."
    echo "-no_reg_func2highres   : turn off REG (assume it has already been done)."
    echo "-no_global_sig   : turn off global signal removal (can run whole pipeline without this on)."
    echo "-no_smooth   : turn off smoothing."
    echo "-no_model   : turn off model fit."
    echo "-no_applyreg   : turn off applyr egistration to contrast."
    echo "-no_ppi   : turn off PPI"
    echo "-no_clean_mcresiduals " 
    echo "-resting : run using resting state mode (difference in filtering)."
    echo "-resting_vols : Number of Volumes to Keep. Trim remaing from end."

    echo "-resting_first_regions : Specify FIRST structures for resting connectivity. e.g. L_Amyg R_Amyg"
    echo "-seedtarget : filename of text file containing 0s and 1s representing seeds and targets."
    echo "-smooth_mm : FWHM of smooth kernel (default is 6 mm)"
    echo "-filter_cutoffs <high-pass cutoff_freq(Hz)> <low-pass cutoff_freq(Hz)>: Low-pass filter cutoff. Only used for resting state analysis"
    echo "-no_resting_gm_mask : omit gm masking prior to connectviity estimations " 
    echo "-atlas_conn_opts : options to pass into atlas_connectivity ; comma separated"
    echo "-no_filtering : No filtering for resting data"
    echo "-save_global_sig : save the 4D time series. "
    echo "-rest_conn_only : only do retsing state connectivity"
    echo "-ppi_subcort <struct1,struct2,...> "
    echo "-no_fast " 
    echo "-do_first" 
    echo "-do_first_only"
    echo "-temp_deriv"
    echo "-deleteMaskOrient: Delete orientation info from the brain mask for SPM models."
    #echo "-jobdir   : Directory where SPM job files and bash scripts will be stored. "
    #echo "-jobname : basename for job file names"
    #echo "-outdir   : parent directory for output data (USE FULL PATH)"
    #echo "-outname : additional text added to some output directories (currently only the spm models run"
    #echo "-nomotion   :omit motion parameters"
    #echo "-fnirtWarp : Warp field from struct to MNI"
    #echo "-design : Design Files "
    #echo "-motion : Motion file "
    #echo "-smooth_mm : FWHM of smooth kernel (default is 6 mm)"
    #echo "-force_redoFEAT : Removes old FEAT directory and reruns the preprocessing."

    #echo "-stage6   : Create master run script for smoothing and models."
    #echo "-stage7   : Clean up date from smoothing and models. Convert analyze to NIFTI"
    echo "-v    : Verbose mode"
    echo ""
    echo "***This script loosely adopts FSL's directory structure"
    echo ""

    exit 1
}


function func_check_param {
    #input number of parameters to shift 
    #pass in all input arguments left in calling script
    num=$1
    shift
    if [ $# -lt $num ] ; then 
        echo "Failed to provide argument for an option. $# arguments left."
        exit 1
    fi

}

#shows what machien ran, handy for debugging grid
hostname >> ${OUTPUTDIR}/log.txt 

NSESSIONS=0
#all input options need to start with "-"
FIRST_PPI_REGIONS=""
NOBBR=0
#These variables store IO options
#jobdir=""
#JOBNAME=""
#OUTPUTNAME=""
#FNIRTWARP=""
BRAIN_MASK_MNI=${ANALYSIS_PIPE_DIR}/mni_bet_1mm_mask
SMOOTH_MM=6 
#Specify processing portions
BRAINEXTRACT_ONLY=1
BET_ONLY=0
NEWBET=0
delVols=0
setDelVols=0
setTR=0
#BET parameters
BET_OPTS=""
BETMASK=""
BETEDITMASK=""
MOTION_FILE=""
SEEDS_TARGETS=""
USE_MOTION=0
USE_DERIV=0;
#Processing options
APPEND_ANALYSIS=0
VEROSE==0
TR=2;
TA=0;
STANDARD_BRAIN=${FSLDIR}/data/standard/MNI152_T1_2mm_brain
PPI_MASKS=""
PPI_MASKS_HIGHRES="" # contain whether or not this is highres or standard space
PPI_CONS=-1
#ON/OF for various parts of the pipeline
REG_EXISTS=0
REG_ETKIN_DIR=""
DO_BET=1
DO_REGISTRATION=1
DO_REGISTRATION_FUNC=1
DO_FAST=1
DO_FIRST=1
DO_DELVOLS=1
DO_GLOBAL_SIG=1
DO_SMOOTH=1
DO_MODEL=1
DO_CONTRAST=1
DO_MC=1
DO_APPLYREG=1
DO_PPI=0
DO_FILTERING=1
PPI_COUNT=0
DO_RESTING=0
DO_FC=1
VERBOSE=0
SAVE_GLB_SIG=0
DO_DEL_MC_RES=1
DO_DEL_FILTFUNC_RES=1
DELETE_MASK_ORIENT=0
XFMFLIRT=0
#-----ONLY USED FOR RESTING STATE ANLYSIS-----/
LP_FREQ_CUTOFF_HZ=0.1
HP_FREQ_CUTOFF_HZ=0.008
DO_ATLAS_CONN=0
RESTING_GM_MASK=1
ATLAS_CONN_OPTS="--useAllLabels"
GM_ONLY=1
RESTING_VOLS=0;
#-----------------------
#Output Appendage
OUT_EXT=emoconflict
OUTPUTDIR=""
OUTPUTDIR_BASE=""

MODEL_NAME=model
VERBOSE_PARAM=""

if [ $# = 0 ] ; then
    Usage
    exit 1
fi
#while [ _${1:0:1} = _- ] ; do
echo "---------------------Specified Options: -------------------"

while [ $# != 0 ] ; do
    echo "processing $1..."
    #The function func_check_param checks to ensure that enough arguments remain for the option

    if [ ${1} = -func_data ] ; then
	func_check_param 2 $@
	shift 1
	#echo func $1
	FUNC_DATA=`readlink -f $1`
	FUNC_DATA=`remove_ext $FUNC_DATA`
	nonetest=`basename $FUNC_DATA`
	echo nonetest $nonetest
        if [ ! $nonetest = none ]; then
            if [ `${FSLDIR}/bin/imtest $FUNC_DATA` = 0 ] ; then
                echo "functional $FUNC_DATA is not a valid image."
                exit 1
            fi
        fi
        shift 1
    elif [ ${1} = -func_data_mask ] ; then
        BRAIN_FUNC_MASK=`readlink -f $2`
	echo BRAIN_FUNC_MASK $BRAIN_FUNC_MASK
        shift 2
    elif [ ${1} = -deleteVolumes ] ; then
        delVols=$2
        setDelVols=1
        shift 2
    elif [ ${1} = -brain_extract_only ] ; then
        BRAINEXTRACT_ONLY=0
        shift 1
    elif [ ${1} = -tr ] ; then 
        TR=$2
	setTR=1
        func_check_param 2 $@
        shift 2
    elif [ ${1} = -outdir ] ; then 

        OUTPUTDIR_BASE=$2
        func_check_param 2 $@

        shift 2
    elif [ ${1} = -xfmUsingLinear ] ; then
	XFMFLIRT=1
	shift 1
    elif [ ${1} = -ta ] ; then 
        TA=$2
        func_check_param 2 $@
        shift 2
    elif [ ${1} = -bet_opts ] ; then 
        BET_OPTS=$2
        func_check_param 2 $@
        shift 2
    elif [ ${1} = -bet_mask ] ; then 
        BETMASK=$2
        shift 2
    elif [ ${1} = -bet_edit_mask ] ; then 
        BETEDITMASK=$2
        shift 2
    elif [ ${1} = -t1 ] ; then 
        IM_T1=`readlink -f $2`
        IM_T1=`remove_ext $IM_T1`
	# echo IMT1 $1 $2 $IM_T1

        func_check_param 2 $@
        shift 2
        if [ `${FSLDIR}/bin/imtest $IM_T1` = 0 ] ; then 
            echo "T1: $IM_T1 is not a valid image."
            exit 1
        fi
    elif [ ${1} = -appendToAnalysis ] ; then 
        APPEND_ANALYSIS=1
        OUTPUTDIR=`readlink -f $2`
        func_check_param 2 $@

        echo "----------  $OUTPUTDIR"
        shift 2
	#echo $#
    elif [ ${1} = -output_extension ] ; then 
        OUT_EXT=$2
        func_check_param 2 $@
        shift 2
    elif [ ${1} = -model_name ] ; then 
        MODEL_NAME=$2
        func_check_param 2 $@
        shift 2
    elif [  ${1} = -temp_deriv ] ; then
        USE_DERIV=1
        shift 1
    elif [ ${1} = -v ] ; then
        VERBOSE=1
        VERBOSE_PARAM="-v"
        shift 1
    elif [ ${1} = -design ] ; then 
        DESIGN_FILE=`readlink -f $2`
        func_check_param 2 $@
        shift 2
    elif [ ${1} = -spm_contrast ] ; then 
        SPM_CON_FILE=`readlink -f $2`
        func_check_param 2 $@
        shift 2
    elif [ ${1} = -resting ] ; then 
        DO_RESTING=1
        DO_MODEL=0
        shift 1
    elif [ ${1} = -seedtarget ] ; then 
        file=`readlink -f $2`
        SEEDS_TARGETS="--seedtarget=${file}"
        shift 2
    elif [ ${1} = -filter_cutoffs ] ; then
        HP_FREQ_CUTOFF_HZ=$2
        LP_FREQ_CUTOFF_HZ=$3
        shift 3
    elif [ ${1} = -smooth_mm ] ; then 
	SMOOTH_MM=$2
	shift 2
    elif [ ${1} = -motion ] ; then 
	#  MOTION_FILE=`readlin -f $2`
	#        MOTION_FILE="-motion ${MOTION_FILE}"
	#      func_check_param 2 $@
        USE_MOTION=1
        shift 1
	#turn off options for pipeline
    elif [ ${1} = -reg_info ]; then 
        REG_ETKIN_DIR=${2}
        REG_EXISTS=1;
        shift 2
    elif [ ${1} = -fc_rois_native ] ; then 
        DO_ATLAS_CONN=1
	#echo "read atlas" `readlink -f $2`
        ATLAS_CONN=`readlink -f $2`
        shift 2
    elif [ ${1} = -fc_rois_mni ] ; then 
        DO_ATLAS_CONN=2
        ATLAS_CONN=`readlink -f $2`
        shift 2
    elif [ ${1} = -no_bet ] ; then 
        DO_BET=0
        shift 1
    elif [ ${1} = -no_bbr ] ; then
        NOBBR=1
        shift 1
    elif [ ${1} = -do_first ] ; then
        DO_FIRST=1
        shift 1 
    elif [ ${1} = -do_first_only ] ; then 
        DO_FIRST=1
        DO_BET=0
        BET_ONLY=0
        DO_DELVOLS=0
        DO_MC=0
        DO_REGISTRATION=0
        DO_REGISTRATION_FUNC=0
        DO_FIRST=1
        DO_FAST=0
        DO_GLOBAL_SIG=0
        DO_SMOOTH=0
        DO_MODEL=0
        DO_CONTRAST=0
        DO_APPLYREG=0
        shift 1 
    elif [ ${1} = -no_fast ] ; then 
        DO_FAST=0
        shift 1
    elif [ ${1} = -do_fast_only ] ; then 
        DO_FAST=1
        DO_BET=0
        BET_ONLY=0
        DO_DELVOLS=0
        DO_MC=0
        DO_REGISTRATION=0
	DO_REGISTRATION_FUNC=0
        DO_FIRST=0
        DO_FAST=1
        DO_GLOBAL_SIG=0
        DO_SMOOTH=0
        DO_MODEL=0
        DO_CONTRAST=0
        DO_APPLYREG=0
        shift 1
    elif [ ${1} = -struct_only ] ; then
        BET_ONLY=1
	DO_DELVOLS=0
        DO_MC=0
        DO_REGISTRATION=1
        DO_REGISTRATION_FUNC=0
        DO_FIRST=1
        DO_FAST=1
        DO_GLOBAL_SIG=0
        DO_SMOOTH=0
        DO_MODEL=0
        DO_CONTRAST=0
        DO_APPLYREG=0
        shift 1

    elif [ ${1} = -bet_only ] ; then
        BET_ONLY=1
	DO_DELVOLS=0
        DO_MC=0
        DO_REGISTRATION=0
        DO_FIRST=0
        DO_FAST=0
        DO_GLOBAL_SIG=0
        DO_SMOOTH=0
        DO_MODEL=0
        DO_CONTRAST=0
        DO_APPLYREG=0
        shift 1
    elif [ ${1} = -rest_conn_only ] ; then 
        DO_BET=0
        DO_DELVOLS=0
        DO_MC=0
        DO_REGISTRATION=0
	DO_REGISTRATION_FUNC=0
        DO_FIRST=0
        DO_FAST=0

        DO_GLOBAL_SIG=0
        DO_SMOOTH=0
        DO_MODEL=0
        DO_CONTRAST=0
        DO_APPLYREG=0
        DO_RESTING=1
	shift 1
    elif [ ${1} = -no_resting_gm_mask ] ; then 
        RESTING_GM_MASK=0
        shift 1
    elif [ ${1} = -ppi_only ] ; then
        DO_BET=0
	DO_DELVOLS=0
        DO_MC=0
        DO_REGISTRATION=0
	DO_REGISTRATION_FUNC=0
        DO_FIRST=0
        DO_FAST=0
        DO_GLOBAL_SIG=0
        DO_SMOOTH=0
        DO_MODEL=0
        DO_CONTRAST=0
        DO_APPLYREG=0
	shift 1
    elif [ ${1} = -ppi_and_reg_only ] ; then
        DO_BET=0
        DO_DELVOLS=0
        DO_MC=0
        DO_REGISTRATION=1
	DO_REGISTRATION_FUNC=1
        DO_FIRST=0
        DO_FAST=0
        DO_GLOBAL_SIG=0
        DO_SMOOTH=0
        DO_MODEL=0
        DO_CONTRAST=0
        DO_APPLYREG=0
        shift 1
    elif [ ${1} = -glm_only ] ; then
        DO_BET=0
	DO_DELVOLS=0
        DO_MC=0
        DO_REGISTRATION=0
	DO_REGISTRATION_FUNC=0
        DO_FIRST=0
        DO_FAST=0
        DO_GLOBAL_SIG=0
        DO_SMOOTH=0
        DO_MODEL=1
        DO_CONTRAST=1
        DO_APPLYREG=1
	shift 1
    elif [ $1 = -deleteMaskOrient ] ; then
        DELETE_MASK_ORIENT=1
        shift 1
    elif [ ${1} = -no_motion_correction ] ; then
        DO_MC=0
        shift 1
    elif [ ${1} = -noreg_func2highres ] ; then 
        DO_REGISTRATION_FUNC=0 
        shift 1

    elif [ ${1} = -no_reg ] ; then 
        DO_REGISTRATION=0
        shift 1 
    elif [ ${1} = -no_delvols ] ; then 
        DO_DELVOLS=0
        shift 1
    elif [ ${1} = -no_global_sig ] ; then 
        DO_GLOBAL_SIG=0
        shift 1
    elif [ ${1} = -no_smooth ] ; then 
        DO_SMOOTH=0
        shift 1
    elif [ ${1} = -no_model ] ; then 
        DO_MODEL=0
        shift 1
    elif [ ${1} = -no_fc ] ; then 
        DO_FC=0
        shift 1
    elif [ ${1} = -no_contrast ] ; then 
        DO_CONTRAST=0
        shift 1
    elif [ ${1} = -no_applyreg ] ; then 
        DO_APPLYREG=0
        shift 1
    elif [ ${1} = -no_clean_mcresiduals ] ; then 
        DO_DEL_MC_RES=0
        shift 1
    elif [ ${1} = -no_clean_resting ] ; then
	DO_DEL_FILTFUNC_RES=0
        shift 1
    elif [ ${1} = -no_filtering ] ; then 
        DO_FILTERING=0
        shift 1
    elif [ ${1} = -atlas_conn_opts ] ; then 
        ATLAS_CONN_OPTS=`echo $2 | sed 's/,/ /g'`
        shift 2
    elif [ ${1} = -resting_vols ] ; then
	RESTING_VOLS=$2
	shift 2

    elif [ ${1} = -resting_first_regions ] ; then 
	DO_ATLAS_CONN=1
	shift 1
	while [ ! ${1:0:1} = - ] ; do
	    FIRST_CONN_REGIONS="${FIRST_CONN_REGIONS} ${1}" 
	    # echo "Connectivity first mask list : " $FIRST_CONN_REGIONS
	    shift
	    #   echo "# $#"           
	    if [ $# -eq 0 ] ; then 
		break;
	    fi
	done
    elif [ ${1} = -ppi_first_masks ] ; then 
        DO_PPI=1
        shift 1
        while [ ! ${1:0:1} = - ] ; do 
            FIRST_PPI_REGIONS="${FIRST_PPI_REGIONS} ${1}" 
	    #           echo "PPI first mask list : " $FIRST_PPI_REGIONS
            shift
	    #           echo "# $#"           
            if [ $# -eq 0 ] ; then 
                break;
            fi
        done
	#echo "DONE PPI FIRST"
    elif [ ${1} = -ppi_masks ] ; then 
        shift 1
	#read all mask to sue for PPI
        DO_PPI=1
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
	    #            echo "# $#"           
            if [ $# -eq 0 ] ; then 
                break;
            fi

        done
        #echo "PPI mask list : " $PPI_MASKS
        let PPI_COUNT+=1
    elif [ ${1} = -ppi_cons ] ; then 
        PPI_CONS=`echo $2 | sed 's/,/ /g'`
        let PPI_COUNT+=1
        shift 2
    elif [ ${1} = -save_global_sig ] ; then
        SAVE_GLB_SIG=1
        shift 1
    else
        echo "Unrecognized option: ${1}"
        Usage
        exit 1
    fi


done

echo "----------------done parsing options---------------"


#-----FIRST THING TO DO IS MAKE SURE A FUCNTIONAL IMAGE WAS INPUT
#checks on functional data and input if processing
if [ $BET_ONLY = 0 ] ; then 
    nonetest=`basename $FUNC_DATA`

    if [ ! $nonetest = none ]; then


	if [ `${FSLDIR}/bin/imtest $FUNC_DATA` = 0 ] ; then
            echo "FUNC_DATA : \"$FUNC_DATA\" is not a valid image."
            shift 2
	fi
    fi

    if [ $setDelVols = 0  ] ; then 
	echo "Need to explicitly set number of volumes to delete using -deleteVolumes"
	exit 1
    fi

    if [ $setTR = 0 ] ; then 
	echo "Need to explicitly set number of TR using -tr"
	exit 1
    fi

fi


#----------FIRST LETS SETUP/CREATE OUTPUT DIRECTORY-------------#
#It gives option to append to current analysis
#If not then will create a new directory with + append (as with FSL)
if [ $APPEND_ANALYSIS = 0 ] ; then
    #unless not using functional data
    if [ $BET_ONLY = 1 ] ; then
        OUTPUTDIR=`${FSLDIR}/bin/remove_ext $IM_T1`
    else    
        OUTPUTDIR=`${FSLDIR}/bin/remove_ext $FUNC_DATA`
    fi
    if [ ! "_$OUTPUTDIR_BASE" = _ ] ; then 
        temp=`basename $OUTPUTDIR`
	#echo TEMP $temp
        OUTPUTDIR=${OUTPUTDIR_BASE}/${temp}
    fi


    while [ -d ${OUTPUTDIR}.${OUT_EXT} ] ; do
        OUTPUTDIR=${OUTPUTDIR}+
    done
    OUTPUTDIR=${OUTPUTDIR}.${OUT_EXT}
    mkdir ${OUTPUTDIR}
else
    #make sure the output directory does, indeed, exist
    if [ ! -d $OUTPUTDIR ] ; then 
        echo "You have chosen to append the data to a current anaylsis, however, ${OUTPUTDIR} does not exist!"
        exit 1
    fi
    
fi


if [ $DO_MODEL = 1 ]; then
    while [ -d ${OUTPUTDIR}/${MODEL_NAME}.spm ]; do
	MODEL_NAME=${MODEL_NAME}+
    done
    echo Model Directory : ${OUTPUTDIR}/${MODEL_NAME}.spm
fi
#Create subdirectories
#I've added glb_sig and struct on top of current FSL structure
for d in mc mc/spm_jobs reg reg_standard glb_sig struct spm_jobs; do
    if [ ! -d ${OUTPUTDIR}/${d} ] ; then 
        mkdir -p ${OUTPUTDIR}/${d}
    fi
done

if [ $VERBOSE ] ; then 
    echo "\n ---------------------------Running EtkinLab Analysis Pipeline-------------------------------- \n"
    echo "Output Directory : $OUTPUTDIR \n"
fi
#----------------------------------------STARTING ANALYSIS---------------------------------------------#

echo "----------Start Structural Processing-------------"


#------------------RUN BRAIN EXTRACTION-----------------------------------//


if [ $DO_BET = 1 ] ; then 
    if [ `${FSLDIR}/bin/imtest $IM_T1` = 0 ] ; then 
        echo "Inlaid structural image or not set : $IM_T1"
        exit 1
    fi

    fout=`basename $IM_T1`
    fout=`${FSLDIR}/bin/remove_ext ${fout}`
    #if structural registtration already exists, just copy data over
    #I've now changed it to just link the folders, the memory burden is large
    if [ $REG_EXISTS = 0 ]; then
        if [ $VERBOSE ] ; then
            echo " "
            echo "Running brain extraction (BET) ..."
        fi;

        ${FSLDIR}/bin/imcp ${IM_T1} ${OUTPUTDIR}/struct/orig
        #set to local copy
        IM_T1=${OUTPUTDIR}/struct/orig

        if [ ! "_$BETMASK" = "_" ] ; then 
            ${FSLDIR}/bin/fslmaths ${IM_T1} -mas ${BETMASK}  ${OUTPUTDIR}/struct/brain
        else
            ${FSLDIR}/bin/first_flirt ${IM_T1} ${OUTPUTDIR}/struct/first_flirt -cort 
            ${FSLDIR}/bin/imrm ${OUTPUTDIR}/struct/first_flirt*stage*
            ${FSLDIR}/bin/convert_xfm -omat ${OUTPUTDIR}/struct/first_flirt_cort_inv.mat -inverse ${OUTPUTDIR}/struct/first_flirt_cort.mat
            flirt -in ${BRAIN_MASK_MNI} -ref ${IM_T1} -out ${OUTPUTDIR}/struct/brain_mask -applyxfm -init ${OUTPUTDIR}/struct/first_flirt_cort_inv.mat
            ${FSLDIR}/bin/fslmaths ${IM_T1} -mas ${OUTPUTDIR}/struct/brain_mask ${OUTPUTDIR}/struct/brain
        fi
        if [ $VERBOSE ] ; then
            echo "...done \n"
        fi

    else
        if [ $VERBOSE ] ; then
            echo ""
            echo "Copying structural data from an existing analysis..."
        fi

	# ${FSLDIR}/bin/imcp ${REG_ETKIN_DIR}/struct/* ${OUTPUTDIR}/struct/
	ln -s ${REG_ETKIN_DIR}/struct/* ${OUTPUTDIR}/struct
        if [ $VERBOSE ] ; then
            echo "...done \n"
        fi
    fi
fi

#set to local copy
IM_T1=${OUTPUTDIR}/struct/orig


#------------------END RUN BRAIN EXTRACTION-----------------------------------//
#if [ $BRAINEXTRACT_ONLY = 0 ] ; then
if [ $DO_FIRST = 1 ] ; then
    if [ `${FSLDIR}/bin/imtest ${OUTPUTDIR}/struct/first_all_fast_firstseg` = 0 ] ; then
        if [ $VERBOSE ] ; then
            echo "Running FIRST subcortical segmentation... "
        fi
        /bin/mkdir ${OUTPUTDIR}/struct/first
        #disable FIRST grid engine parallelization
        SGE_ROOT_PREV=${SGE_ROOT}
        SGE_ROOT=""

        ${FSLDIR}/bin/run_first_all -v -a ${OUTPUTDIR}/struct/first_flirt.mat -i ${IM_T1} -o ${OUTPUTDIR}/struct/first/first -s L_Accu,L_Amyg,L_Caud,L_Hipp,L_Pall,L_Puta,L_Thal,R_Accu,R_Caud,R_Hipp,R_Pall,R_Puta,R_Thal,R_Amyg -m auto

        SGE_ROOT=$SGE_ROOT_PREV
        ${FSLDIR}/bin/immv ${OUTPUTDIR}/struct/first/first_all_fast_firstseg ${OUTPUTDIR}/struct/
        if [ $VERBOSE ] ; then
            echo "...done \n"
        fi
    fi
fi

#-----------------------------------------------------------------------------//
#BETONLY variable serves as a way to mask out fuinctional part for sturctural only processing

#only structural regsitartion
if [ $DO_REGISTRATION = 1 ] ; then
    #-----------------------REGISTRATION--------------------//

    #if structural registtration already exists, just copy data over
    if [ $REG_EXISTS = 0 ]; then
        if [ $VERBOSE ] ; then
            echo "Running FLIRT : highres -> $STANDARD_BRAIN... "
        fi

        ${FSLDIR}/bin/flirt -ref $STANDARD_BRAIN -in ${OUTPUTDIR}/struct/brain -out ${OUTPUTDIR}/reg/highres2standard -omat ${OUTPUTDIR}/reg/highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear
        convert_xfm -omat ${OUTPUTDIR}/reg/standard2highres.mat -inverse ${OUTPUTDIR}/reg/highres2standard.mat

        if [ $VERBOSE ] ; then
            echo "...Running FNIRT "
        fi
	${ANALYSIS_PIPE_DIR}/run_fnirt_fine.sh $IM_T1 ${OUTPUTDIR}/reg/highres2standard.mat ${OUTPUTDIR}/reg/highres2standard

	if [ $VERBOSE ] ; then

            echo "...Inverting Warp Field"
	fi

        {
            echo "${FSLDIR}/bin/invwarp -w ${OUTPUTDIR}/reg/highres2standard_warp -r ${OUTPUTDIR}/struct/brain -o ${OUTPUTDIR}/reg/standard2highres_warp"
            echo "${FSLDIR}/bin/convert_xfm -omat ${OUTPUTDIR}/reg/standard2highres.mat -inverse ${OUTPUTDIR}/reg/highres2standard.mat"
	    echo "${FSLDIR}/bin/applywarp -w ${OUTPUTDIR}/reg/standard2highres_warp -i ${BRAIN_MASK_MNI} -r ${IM_T1} -o ${OUTPUTDIR}/struct/brain_fnirt_mask -d float"
            echo "${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/struct/brain_fnirt_mask -thr 0.0 -bin ${OUTPUTDIR}/struct/brain_fnirt_mask -odt short"
            echo "${FSLDIR}/bin/fslmaths ${IM_T1} -mas ${OUTPUTDIR}/struct/brain_fnirt_mask ${OUTPUTDIR}/struct/brain_fnirt"
            }>> ${OUTPUTDIR}/log.txt

        ${FSLDIR}/bin/invwarp -w ${OUTPUTDIR}/reg/highres2standard_warp -r ${OUTPUTDIR}/struct/brain -o ${OUTPUTDIR}/reg/standard2highres_warp
        ${FSLDIR}/bin/convert_xfm -omat ${OUTPUTDIR}/reg/standard2highres.mat -inverse ${OUTPUTDIR}/reg/highres2standard.mat

        ${FSLDIR}/bin/applywarp -w ${OUTPUTDIR}/reg/standard2highres_warp -i ${BRAIN_MASK_MNI} -r ${IM_T1} -o ${OUTPUTDIR}/struct/brain_fnirt_mask -d float
        ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/struct/brain_fnirt_mask -thr 0.0 -bin ${OUTPUTDIR}/struct/brain_fnirt_mask -odt short
        ${FSLDIR}/bin/fslmaths ${IM_T1} -mas ${OUTPUTDIR}/struct/brain_fnirt_mask ${OUTPUTDIR}/struct/brain_fnirt
	if [ $VERBOSE ] ; then
	    echo "...done \n"
	fi
    else
        if [ $VERBOSE ] ; then
            echo "Copying structural registration data from existing directory"
        fi
	#  ${FSLDIR}/bin/imcp ${REG_ETKIN_DIR}/reg/standard2highres_warp ${OUTPUTDIR}/reg/standard2highres_warp
	#       ${FSLDIR}/bin/imcp ${REG_ETKIN_DIR}/reg/highres2standard_warp ${OUTPUTDIR}/reg/highres2standard_warp
	#       /bin/cp  ${REG_ETKIN_DIR}/reg/highres2standard.mat  ${OUTPUTDIR}/reg/highres2standard.mat
        im_ext=`imglob -extension ${REG_ETKIN_DIR}/reg/standard2highres_warp`
        fim_ext=`basename $im_ext`
        ln -s  $im_ext ${OUTPUTDIR}/reg/${fim_ext}

        im_ext=`imglob -extension ${REG_ETKIN_DIR}/reg/highres2standard_warp`
        fim_ext=`basename $im_ext`
        ln -s  $im_ext ${OUTPUTDIR}/reg/${fim_ext}


        ln -s ${REG_ETKIN_DIR}/reg/highres2standard.mat  ${OUTPUTDIR}/reg/highres2standard.mat

        if [ $VERBOSE ] ; then
            echo "...done \n"
        fi


	#       Nfiles=`ls ${OUTPUTDIR}/struct/ | wc | awk '{ print $1 }'`
	#       if [ $Nfiles = 0 ] ; then
	#           if [ $VERBOSE ] ; then
	#               echo "...copying structural data from existing directory..."
	#           fi
	#           #do fnirt bet
	#           #this may be performened twice
	#           ${FSLDIR}/bin/imcp ${REG_ETKIN_DIR}/struct/* ${OUTPUTDIR}/struct/
	#           /bin/cp  ${REG_ETKIN_DIR}/struct/*.mat ${OUTPUTDIR}/struct/
	#           if [ $VERBOSE ] ; then
	#               echo "...done \n"
	#           fi
	#     fi

    fi





fi

if [ $DO_FAST = 1 ] ; then 
    if [ `${FSLDIR}/bin/imtest ${OUTPUTDIR}/struct/brain_fnirt_pve_2` = 0 ] ; then 
        echo "Running FAST... "

	${FSLDIR}/bin/fast -b ${OUTPUTDIR}/struct/brain_fnirt 
        ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/struct/brain_fnirt_pve_2 -thr 0.5 -bin ${OUTPUTDIR}/struct/brain_fnirt_wmseg
	echo "...Done running FAST"
    fi
fi

echo "\n----------Done Structural Processing-------------\n"

#ALL FUNCTIONAL STUFF STARTS HERE
#------------------DO SPM MOTION Correction-----------------------------//
echo "\n----------Start Functional Processing-------------\n"
if [ $RESTING_VOLS -gt 0 ]; then
    echo " ${FSLDIR}/bin/fslroi $FUNC_DATA ${OUTPUTDIR}/prefiltered_func_data 0 $RESTING_VOLS" >>${OUTPUTDIR}/log.txt
    ${FSLDIR}/bin/fslroi $FUNC_DATA ${OUTPUTDIR}/prefiltered_func_data 0 $RESTING_VOLS
    FUNC_DATA=${OUTPUTDIR}/prefiltered_func_data
fi


if [ $DO_DELVOLS = 1 ] ; then
    if [ $VERBOSE ] ; then
	echo "Deleting first ${delVols} volumes from time series..."
    fi
    if [ `${FSLDIR}/bin/imtest ${OUTPUTDIR}/prefiltered_func_data` = 0 ] || [ $RESTING_VOLS -gt 0 ]; then
        if [ $delVols -gt 0 ] ; then 
            Npts=`${FSLDIR}/bin/fslnvols $FUNC_DATA`
            size=`echo "${Npts} - ${delVols}" | bc`
	    echo "${FSLDIR}/bin/fslroi $FUNC_DATA ${OUTPUTDIR}/prefiltered_func_data $delVols $size" >>${OUTPUTDIR}/log.txt

            ${FSLDIR}/bin/fslroi $FUNC_DATA ${OUTPUTDIR}/prefiltered_func_data $delVols $size

        else
            #Bet only is also set for struct only
            if [ $BET_ONLY = 0 ] ; then
		echo "${FSLDIR}/bin/imcp $FUNC_DATA ${OUTPUTDIR}/prefiltered_func_data" >>${OUTPUTDIR}/log.txt

                ${FSLDIR}/bin/imcp $FUNC_DATA ${OUTPUTDIR}/prefiltered_func_data
            fi
        fi
    else
        echo "WARNING: Using already processed prefiltered_func_data. I wont write over processed prefiltered_func_data at this stage"
    fi
    if [ $VERBOSE ] ; then
	echo "...done \n"

    fi
fi


#if [ $DO_MC = 1 ] ; then 
#use first images instead of middle to match SPM motions correction
if [ `${FSLDIR}/bin/imtest  ${OUTPUTDIR}/prefiltered_func_data` = 1 ] && [ `${FSLDIR}/bin/imtest ${OUTPUTDIR}/example_func` = 0 ]; then

    if [ $VERBOSE ] ; then 
        echo "Extracting Reference Volume (example_func) for Motion Correction and Registration..."
    fi
    Nvols=`${FSLDIR}/bin/fslnvols $FUNC_DATA`
    #use middle volume
    REFVOL=`echo "$Nvols / 2" | bc`
    echo "...Total Number of Volumes : $Nvols, Reference Volume : "$REFVOL
    #motion_File parameter also conatins the -motion
    echo "${FSLDIR}/bin/fslroi ${OUTPUTDIR}/prefiltered_func_data ${OUTPUTDIR}/example_func $REFVOL 1">>${OUTPUTDIR}/log.txt
    ${FSLDIR}/bin/fslroi ${OUTPUTDIR}/prefiltered_func_data ${OUTPUTDIR}/example_func $REFVOL 1


    if [ $VERBOSE ] ; then
	echo "...done \n"
    fi
fi
#Do functional to structural registration

if [ $DO_REGISTRATION_FUNC = 1 ] ; then
    if [ $VERBOSE ] ; then
        echo "Doing BBR Registration..."
    fi
    #-----------------------REGISTRATION--------------------//
    if [ $NOBBR = 0 ]; then
	brain=`imglob -extension ${OUTPUTDIR}/struct/brain_fnirt`
	fbrain=`readlink -f $brain`
	t1_bbr=`imglob -extension ${OUTPUTDIR}/struct/orig`
	ft1_bbr=`readlink -f $t1_bbr`

	echo  "${FSLDIR}/bin/epi_reg --epi=${OUTPUTDIR}/example_func --t1=$ft1_bbr --t1brain=$fbrain --out=${OUTPUTDIR}/reg/example_func2highres" >>${OUTPUTDIR}/log.txt
	${FSLDIR}/bin/epi_reg --epi=${OUTPUTDIR}/example_func --t1=$ft1_bbr --t1brain=$fbrain --out=${OUTPUTDIR}/reg/example_func2highres

    else
	echo "${FSLDIR}/bin/flirt -in ${OUTPUTDIR}/example_func -ref ${OUTPUTDIR}/struct/brain_fnirt -dof 6 -out ${OUTPUTDIR}/reg/example_func2highres -omat ${OUTPUTDIR}/reg/example_func2highres.mat" >> ${OUTPUTDIR}/log.txt
	${FSLDIR}/bin/flirt -in ${OUTPUTDIR}/example_func -ref ${OUTPUTDIR}/struct/brain_fnirt -dof 6 -out ${OUTPUTDIR}/reg/example_func2highres -omat ${OUTPUTDIR}/reg/example_func2highres.mat
    fi

    echo "${FSLDIR}/bin/convert_xfm  -omat ${OUTPUTDIR}/reg/highres2example_func.mat -inverse ${OUTPUTDIR}/reg/example_func2highres.mat" >>${OUTPUTDIR}/log.txt
    ${FSLDIR}/bin/convert_xfm  -omat ${OUTPUTDIR}/reg/highres2example_func.mat -inverse ${OUTPUTDIR}/reg/example_func2highres.mat
    if [ $VERBOSE ] ; then
        echo "...done \n"
    fi
fi
#-----------------------------------------------------------------------------//

#-----------------------------------------------------------------------------//
if [ $DO_MC = 1 ] ; then

    if [ $VERBOSE ] ; then
        echo "Do motion correction (mcflirt)..."
    fi
    #motion correction
    ${FSLDIR}/bin/mcflirt -in ${OUTPUTDIR}/prefiltered_func_data -out ${OUTPUTDIR}/prefiltered_func_data_mcf -mats -plots -refvol $REFVOL -rmsrel -rmsabs

    /bin/mv -f ${OUTPUTDIR}/prefiltered_func_data_mcf.mat  ${OUTPUTDIR}/prefiltered_func_data_mcf_abs.rms ${OUTPUTDIR}/prefiltered_func_data_mcf_abs_mean.rms ${OUTPUTDIR}/prefiltered_func_data_mcf_rel.rms ${OUTPUTDIR}/prefiltered_func_data_mcf_rel_mean.rms ${OUTPUTDIR}/mc
    /bin/mv -f ${OUTPUTDIR}/prefiltered_func_data_mcf.par ${OUTPUTDIR}/mc/prefiltered_func_data_mcf.par.txt

    ${FSLDIR}/bin/fsl_tsplot -i ${OUTPUTDIR}/mc/prefiltered_func_data_mcf.par.txt -t 'MCFLIRT estimated rotations (radians)' -u 1 --start=1 --finish=3 -a x,y,z -w 640 -h 144 -o ${OUTPUTDIR}/mc/rot.png 
    ${FSLDIR}/bin/fsl_tsplot -i ${OUTPUTDIR}/mc/prefiltered_func_data_mcf.par.txt -t 'MCFLIRT estimated translations (mm)' -u 1 --start=4 --finish=6 -a x,y,z -w 640 -h 144 -o ${OUTPUTDIR}/mc/trans.png 
    ${FSLDIR}/bin/fsl_tsplot -i ${OUTPUTDIR}/mc/prefiltered_func_data_mcf_abs.rms,${OUTPUTDIR}/mc/prefiltered_func_data_mcf_rel.rms -t 'MCFLIRT estimated mean displacement (mm)' -u 1 -w 640 -h 144 -a absolute,relative -o ${OUTPUTDIR}/mc/disp.png 
    if [ $VERBOSE ] ; then
        echo "...done \n"
    fi
    #-----------------------------------------------------------------------------//
    if [ $VERBOSE ] ; then
	echo "Create a functional brain mask and apply..."
    fi
    #create a brian mask
    ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/prefiltered_func_data_mcf -Tmean ${OUTPUTDIR}/mean_func

    ${FSLDIR}/bin/bet2 ${OUTPUTDIR}/mean_func ${OUTPUTDIR}/mask -f 0.3 -n -m; 
    ${FSLDIR}/bin/immv ${OUTPUTDIR}/mask_mask ${OUTPUTDIR}/mask

    ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/prefiltered_func_data_mcf -mas ${OUTPUTDIR}/mask ${OUTPUTDIR}/prefiltered_func_data_bet

    upper_thresh=`${FSLDIR}/bin/fslstats ${OUTPUTDIR}/prefiltered_func_data_bet -p 2 -p 98 | awk '{ print $2 }'`
    upper_thresh=`echo "scale=7; ${upper_thresh}*0.1" | bc -l`


    ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/prefiltered_func_data_bet -thr $upper_thresh -Tmin -bin ${OUTPUTDIR}/mask -odt char

    ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/mask -dilF ${OUTPUTDIR}/mask
    ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/prefiltered_func_data_mcf -mas ${OUTPUTDIR}/mask ${OUTPUTDIR}/prefiltered_func_data -odt float

    ${FSLDIR}/bin/imrm ${OUTPUTDIR}/prefiltered_func_data_bet ${OUTPUTDIR}/prefiltered_func_data_mcf

    if [ $VERBOSE ] ; then
	echo "...done \n"
    fi
fi

#------------Remove Gloval Signal------------------------------//
if [ $DO_GLOBAL_SIG = 1 ] ; then 
    if [ $VERBOSE ] ; then
        echo "Regressing out global signal (OLS using fsl_glm)..."
    fi
    ${FSLDIR}/bin/applywarp -i ${ANALYSIS_PIPE_DIR}/white_0.9_csf_0.5_mask.nii.gz -r ${OUTPUTDIR}/example_func -w ${OUTPUTDIR}/reg/standard2highres_warp --postmat=${OUTPUTDIR}/reg/highres2example_func.mat -o  ${OUTPUTDIR}/glb_sig/wm_csf_mask

    ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/glb_sig/wm_csf_mask -thr 1 ${OUTPUTDIR}/glb_sig/wm_csf_mask
    #-m ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil

    ${ANALYSIS_PIPE_DIR}/analysis_pipeline_rm_glb_sig.sh -func_data ${OUTPUTDIR}/prefiltered_func_data -ref_data ${OUTPUTDIR}/prefiltered_func_data -mask ${OUTPUTDIR}/glb_sig/wm_csf_mask -outname ${OUTPUTDIR}/glb_sig/prefiltered_func_data_glb
    if [ $SAVE_GLB_SIG = 0 ] ; then 
        ${FSLDIR}/bin/immv ${OUTPUTDIR}/glb_sig/prefiltered_func_data_glb ${OUTPUTDIR}/prefiltered_func_data
    else
        ${FSLDIR}/bin/imcp ${OUTPUTDIR}/glb_sig/prefiltered_func_data_glb ${OUTPUTDIR}/prefiltered_func_data
    fi
    echo "...done \n"
fi

#------------Smooth Image------------------------------//
if [ $DO_SMOOTH = 1 ] ; then 
    if [ $VERBOSE = 1 ] ; then 
        echo "Spatially Smoothing Functional Data (${SMOOTH_MM} mm )..."
    fi
    #I'm separating the image smoothing from the model, to add flexibility
    #switch to NIFTI in order to be compatible with SPM.
    ${FSLDIR}/bin/fslchfiletype NIFTI ${OUTPUTDIR}/prefiltered_func_data
    ${ANALYSIS_PIPE_DIR}/analysis_pipeline_SPMsmooth.sh -v $VERBOSE -smooth_mm ${SMOOTH_MM} -jobname ${OUTPUTDIR}/spm_jobs/job_smooth.m -outdir ${OUTPUTDIR} -func_data  ${OUTPUTDIR}/prefiltered_func_data

    if [ $VERBOSE = 1 ] ; then 
	echo "Done Smoothing, write over prefiltered_func_data"
	echo "${FSLDIR}/bin/immv ${OUTPUTDIR}/sprefiltered_func_data ${OUTPUTDIR}/prefiltered_func_data"
    fi
    if [ `${FSLDIR}/bin/imtest ${OUTPUTDIR}/sprefiltered_func_data` = 0  ] ; then
	echo "ERROR: Smoothing using SPM failed."
	exit 1
    fi

    ${FSLDIR}/bin/immv ${OUTPUTDIR}/sprefiltered_func_data ${OUTPUTDIR}/prefiltered_func_data

    

    #clean up 3D smoothed files only if not proceeding to model

    #well merge regardless, 3D files will be removed eventually
    #  ${FSLDIR}/bin/fslmerge -t ${OUTPUTDIR}/prefiltered_func_data `cat ${OUTPUTDIR}/spm_jobs/job_smooth.m_ims3d.txt`

    #check again after the models is done
    
    #   if [ $DO_MODEL = 0 ] ;then
    #merge into a single 4D time series 
    #        ${FSLDIR}/bin/imrm `cat ${OUTPUTDIR}/spm_jobs/job_smooth.m_ims3d.txt`
    #   fi
    if [ $VERBOSE ] ; then
        echo "...done \n"
    fi

fi
#-------------------Apply low-pass filter---------------//
#resting flag trumps others
if [ $DO_RESTING = 0 ] ; then 

    #------------------------------------------------------//
    #-----------------------DOING MODEL-------------------------------//
    if [ $DO_MODEL = 1 ] ; then 

        if [ -f ${OUTPUTDIR}/prefiltered_func_data.nii.gz ] ; then
            ${FSLDIR}/bin/fslchfiletype NIFTI ${OUTPUTDIR}/prefiltered_func_data
        fi



        if [ $VERBOSE = 1 ] ; then
            echo ""
            echo "Running Model..."
        fi
        #lets figure oput what's been run already
	#    DO_4D=0
	#             if [ -f ${OUTPUTDIR}/spm_jobs/job_smooth.m_ims3d.txt ] ; then
	#                   for i in `cat ${OUTPUTDIR}/spm_jobs/job_smooth.m_ims3d.txt` ; do
        #chekc to see if the image files are all there. Leave it up to script to tell if its a valid image
	#                       if [ ! -f $i ] ; then
	#                           DO_4D=1
	#                           break
	#                       fi
	#                   done
	#               else
	#                   echo " ${OUTPUTDIR}/spm_jobs/job_smooth.m_ims3d.txt does not exist. Please run smoothing."
	#                  exit 1
	#               fi
        
        if [ "_$DESIGN_FILE" = "_" ] ; then 
            echo "Missing design file, it has not been set. "
            exit 1
        fi

	if [ ! -d ${OUTPUTDIR}/${MODEL_NAME}.spm/spm_jobs ] ; then 
	    mkdir -p ${OUTPUTDIR}/${MODEL_NAME}.spm/spm_jobs
	fi
        #copy in brain mask
	#${FSLDIR}/bin/fslchfiletype NIFTI ${OUTPUTDIR}/struct/brain_fnirt_mask ${OUTPUTDIR}/${MODEL_NAME}.spm/brain_fnirt_mask
        #set motion file if going to inlcude
        if [ $USE_MOTION = 1 ] ; then 
            MOTION_FILE="-motion ${OUTPUTDIR}/mc/prefiltered_func_data_mcf.par.txt"
        fi


        ${FSLDIR}/bin/flirt -in ${OUTPUTDIR}/struct/brain_fnirt_mask -ref ${OUTPUTDIR}/example_func.nii.gz  -applyxfm -init ${OUTPUTDIR}/reg/highres2example_func.mat -out ${OUTPUTDIR}/${MODEL_NAME}.spm/brain_fnirt_mask_func -datatype float

        if [ $DELETE_MASK_ORIENT = 1 ]; then
            ${FSLDIR}/bin/fslorient -deleteorient ${OUTPUTDIR}/${MODEL_NAME}.spm/brain_fnirt_mask_func
        fi
	echo  ${FSLDIR}/bin/fslchfiletype NIFTI ${OUTPUTDIR}/${MODEL_NAME}.spm/brain_fnirt_mask_func
        ${FSLDIR}/bin/fslchfiletype NIFTI ${OUTPUTDIR}/${MODEL_NAME}.spm/brain_fnirt_mask_func
	#  ${FSLDIR}/bin/fslorient -deleteorient  ${OUTPUTDIR}/${MODEL_NAME}.spm/brain_fnirt_mask_func

	ls ${OUTPUTDIR}/${MODEL_NAME}.spm/
	#    if [ $DO_4D = 0 ] ; then
	#                   echo "...3D expansion already exists...proceeding..."
	
	#                    ${ANALYSIS_PIPE_DIR}/analysis_pipeline_SPMmodel.sh -v $VERBOSE -tr $TR -jobname ${OUTPUTDIR}/${MODEL_NAME}.spm/spm_jobs/job_model.m  -outdir ${OUTPUTDIR}/${MODEL_NAME}.spm -func_data ${OUTPUTDIR}/spm_jobs/job_smooth.m_ims3d.txt -design $DESIGN_FILE ${MOTION_FILE} -mask ${OUTPUTDIR}/${MODEL_NAME}.spm/brain_fnirt_mask_func.nii

        #               else
        #   echo "...Need to split the time series"
        if [ _$BRAIN_FUNC_MASK = "_" ] ; then
            BRAIN_FUNC_MASK=${OUTPUTDIR}/${MODEL_NAME}.spm/brain_fnirt_mask_func.nii
        fi


        ${ANALYSIS_PIPE_DIR}/analysis_pipeline_SPMmodel.sh -v $VERBOSE -tr $TR -jobname ${OUTPUTDIR}/${MODEL_NAME}.spm/spm_jobs/job_model.m -outdir ${OUTPUTDIR}/${MODEL_NAME}.spm -func_data ${OUTPUTDIR}/prefiltered_func_data -design $DESIGN_FILE  ${MOTION_FILE} -mask $BRAIN_FUNC_MASK -temp_deriv $USE_DERIV

	#               fi
        
	#if [ -f ${OUTPUTDIR}/prefiltered_func_data.nii ] ; then
	#    ${FSLDIR}/bin/fslchfiletype NIFTI_GZ ${OUTPUTDIR}/prefiltered_func_data
	#fi


        #clean 3D datat
	#                if [ $DO_PPI = 0 ] ; then
	#                   if [ $PPI_COUNT -lt 2 ] ; then
	#                       ${FSLDIR}/bin/imrm `cat ${OUTPUTDIR}/spm_jobs/job_smooth.m_ims3d.txt`
	#
	#                   fi
	#               fi

        echo "...done \n"
    fi
    #------------------------------------------------------//
    #---------------------------DOING CONTRAST---------------------------//
    if [ $DO_CONTRAST = 1 ] ; then 
        echo "Run contrast..."
        if [ $VERBOSE = 1 ] ; then 
            echo ""
            echo "Running contrast"
        fi
        if [ ! -f $SPM_CON_FILE ] ; then 
            echo "$SPM_CON_FILE  does not exist."
            Usage
            exit 1
        fi
        if [ "_$SPM_CON_FILE" = _ ] ; then 
            echo "SPM contrast file was not entered."
            Usage
            exit 1
        fi

        #substitue in appropriate SPMDIR
        if [ ! -f ${OUTPUTDIR}/${MODEL_NAME}.spm/SPM.mat ] ; then 
            echo "Trying to run contrast but ${OUTPUTDIR}/${MODEL_NAME}.spm/SPM.mat does not exist"
            exit 1
        fi

        #not so elelgant way to get said to work 
        #need \/ in variable
        echo ${OUTPUTDIR}  | sed 's/\//\\\//g' >  ${OUTPUTDIR}/${MODEL_NAME}.spm/spm_jobs/grot
        foutdir=`cat ${OUTPUTDIR}/${MODEL_NAME}.spm/spm_jobs/grot`
        /bin/rm ${OUTPUTDIR}/${MODEL_NAME}.spm/spm_jobs/grot


        cat ${SPM_CON_FILE}  | sed "s/'<UNDEFINED>'/{'${foutdir}\/${MODEL_NAME}.spm\/SPM.mat'}/g" > ${OUTPUTDIR}/${MODEL_NAME}.spm/spm_jobs/job_contrast.m

        #create run script and call with matlab

        ${ANALYSIS_PIPE_DIR}/analysis_pipeline_createSPM_batch_script.sh ${OUTPUTDIR}/${MODEL_NAME}.spm/spm_jobs/run_job_contrast.m ${OUTPUTDIR}/${MODEL_NAME}.spm/spm_jobs/job_contrast.m

	#run brians contrast function
	#	echo "${ANALYSIS_PIPE_DIR}/bin/osx/spm_contrast -c $SPM_CON_FILE -o  ${OUTPUTDIR}/${MODEL_NAME}.spm">> ${OUTPUTDIR}/log.txt
	#${ANALYSIS_PIPE_DIR}/bin/osx/spm_contrast -c $SPM_CON_FILE -o  ${OUTPUTDIR}/${MODEL_NAME}.spm/


        #--run the matlab script
        CURDIR=`pwd`
        cd ${OUTPUTDIR}/${MODEL_NAME}.spm/spm_jobs
        echo "cd ${OUTPUTDIR}/${MODEL_NAME}.spm/spm_jobs ; run_job_contrast" | matlab -nodesktop -nodisplay -nosplash
        cd $CURDIR

        echo "...done"
    fi

    #------------------------------------------------------//
    if [ $DO_APPLYREG = 1 ] ; then 
        echo "Apply MNI space transformation to contrasts... "

        if [ $VERBOSE = 1 ] ; then 
            echo ""
            echo "Apply MNI space transformation to contrasts "
        fi
        if [ ! -d {OUTPUTDIR}/reg_standard/${MODEL_NAME}.spm ] ; then 
            /bin/mkdir ${OUTPUTDIR}/reg_standard/${MODEL_NAME}.spm
        fi

        for i in `${FSLDIR}/bin/imglob ${OUTPUTDIR}/${MODEL_NAME}.spm/con_0*` ; do
            f=`basename $i`

	    if [ $XFMFLIRT = 0 ]; then
                echo "${FSLDIR}/bin/applywarp -i $i  -w ${OUTPUTDIR}/reg/highres2standard_warp --premat=${OUTPUTDIR}/reg/example_func2highres.mat -r $STANDARD_BRAIN -o ${OUTPUTDIR}/reg_standard/${MODEL_NAME}.spm/${f}_mni  -m ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil" >> ${OUTPUTDIR}/log.txt
                ${FSLDIR}/bin/applywarp -i $i  -w ${OUTPUTDIR}/reg/highres2standard_warp --premat=${OUTPUTDIR}/reg/example_func2highres.mat -r $STANDARD_BRAIN -o ${OUTPUTDIR}/reg_standard/${MODEL_NAME}.spm/${f}_mni  -m ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil
	    else
		{
		    echo "convert_xfm -omat ${OUTPUTDIR}/reg/example_func2standard.mat -concat ${OUTPUTDIR}/reg/highres2standard.mat ${OUTPUTDIR}/reg/example_func2highres.mat"
		    echo "${FSLDIR}/bin/flirt -in $i -ref $STANDARD_BRAIN -applyxfm -init ${OUTPUTDIR}/reg/highres2standard.mat -out ${OUTPUTDIR}/reg_standard/${MODEL_NAME}.spm/${f}_mni_lin"
		    }>> ${OUTPUTDIR}/log.txt

		convert_xfm -omat ${OUTPUTDIR}/reg/example_func2standard.mat -concat ${OUTPUTDIR}/reg/highres2standard.mat ${OUTPUTDIR}/reg/example_func2highres.mat

		${FSLDIR}/bin/flirt -in $i -ref $STANDARD_BRAIN -applyxfm -init ${OUTPUTDIR}/reg/example_func2standard.mat -out ${OUTPUTDIR}/reg_standard/${MODEL_NAME}.spm/${f}_mni_lin
	    fi

	done
        echo "...done"

    fi
    #------------------------------------------------------//
    if [ $DO_PPI = 1 ] ; then 
        echo "Run PPI..."



        if [ $VERBOSE = 1 ] ; then
            echo ""
            echo "Running PPIs... "
        fi
        #need to re-split the functional data
        NEED_SPLIT=0
        for i in `cat ${OUTPUTDIR}/spm_jobs/job_smooth.m_ims3d.txt` ; do 
            if [ ! -f $i ] ; then 
                echo "Couldn't find $i"
                NEED_SPLIT=1;
                break
            fi
        done
	#               echo "NEED_SPLIT? $NEED_SPLIT"
        #want split to output nifti
        export FSLOUTPUTTYPE=NIFTI
	#have moved this in the loop because im going to edit the split files by the mask 
	if [ $NEED_SPLIT = 1 ] ; then
	    echo "Split filtered func data for PPI"
	    ${FSLDIR}/bin/fslsplit ${OUTPUTDIR}/prefiltered_func_data ${OUTPUTDIR}/sfmri_grot
	else 
	    echo "Split data already exists"
	fi
        #This portion uses FIRST segmentation and creates masks for PPI in native space
	if [ ! -d ${OUTPUTDIR}/struct/ppi_masks_highres ] ; then 
            /bin/mkdir ${OUTPUTDIR}/struct/ppi_masks_highres
	fi
	if [ ! -d ${OUTPUTDIR}/struct/ppi_masks_standard ] ; then 
            /bin/mkdir ${OUTPUTDIR}/struct/ppi_masks_standard
	fi
        echo "...extracting FIRST regions"
        for i_f in $FIRST_PPI_REGIONS ; do 
            
            lt=0;
            ut=0;
            if [ $i_f = L_Amyg ] ; then
                lt=17.5
                ut=18.5
            elif [ $i_f = R_Amyg ] ; then
                lt=53.5
                ut=54.5
            elif [ $i_f = L_Thal ] ; then
                lt=9.5
                ut=10.5
            elif [ $i_f = R_Thal ] ; then
                lt=48.5
                ut=49.5
            elif [ $i_f = L_Caud ] ; then
                lt=10.5
                ut=11.5
            elif [ $i_f = R_Caud ] ; then
                lt=49.5
                ut=50.5
            elif [ $i_f = L_Puta ] ; then
                lt=11.5
                ut=12.5
            elif [ $i_f = R_Puta ] ; then
                lt=50.5
                ut=51.5
            elif [ $i_f = L_Pall ] ; then
                lt=12.5
                ut=13.5
            elif [ $i_f = R_Pall ] ; then
                lt=51.5
                ut=52.5
            elif [ $i_f = L_Hipp ] ; then
                lt=16.5
                ut=17.5
            elif [ $i_f = R_Hipp ] ; then
                lt=52.5
                ut=53.5
            elif [ $i_f = L_Accu ] ; then
                lt=25.5
                ut=26.5
            elif [ $i_f = R_Accu ] ; then
                lt=57.5
                ut=58.5
            else
                echo "invalid FIRST region selected : $i_f"
                exit 1
            fi

            #extract region

            if [ `${FSLDIR}/bin/imtest ${OUTPUTDIR}/struct/first_all_fast_firstseg` = 0 ] ; then 
                echo "Subcortical segmentation:${OUTPUTDIR}/struct/first_all_fast_firstseg, not found "
                exit 1
            fi
            ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/struct/first_all_fast_firstseg -thr $lt -uthr $ut -bin ${OUTPUTDIR}/struct/ppi_masks_highres/${i_f}_first_highres
            PPI_MASKS="${OUTPUTDIR}/struct/ppi_masks_highres/${i_f}_first_highres ${PPI_MASKS}"
            PPI_MASKS_HIGHRES="1 ${PPI_MASKS_HIGHRES}"

        done
        echo "...processing PPI masks"

        mask_count=0
        for mask in ${PPI_MASKS} ; do
            echo "...mask...$mask"
            let mask_count+=1 #start index is 0   
            if [ ! -d ${OUTPUTDIR}/${MODEL_NAME}.ppi ] ; then 
                /bin/mkdir ${OUTPUTDIR}/${MODEL_NAME}.ppi
            fi

            echo $PPI_MASKS_HIGHRES | awk "{ print \$${mask_count} }" > ${OUTPUTDIR}/${MODEL_NAME}.ppi/ppi_grot
            cat ${OUTPUTDIR}/${MODEL_NAME}.ppi/ppi_grot
            isHIGHRES=`cat ${OUTPUTDIR}/${MODEL_NAME}.ppi/ppi_grot`
            /bin/rm ${OUTPUTDIR}/${MODEL_NAME}.ppi/ppi_grot
	    # echo "mask $mask is highh $isHIGHRES"
            
            fmask=`basename $mask`
            fmask=`${FSLDIR}/bin/remove_ext $fmask`
            for con in ${PPI_CONS} ; do 
                if [ ! -d ${OUTPUTDIR}/${MODEL_NAME}.ppi/${mask}_con_${con} ] ; then 
                    /bin/mkdir -p ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}
                fi


                #copy in ppi mask and make sure its in nifti
		# ${FSLDIR}/bin/fslchfiletype NIFTI $mask ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}
		#                       echo "Transform PPI masks into native space"
		# ${FSLDIR}/bin/imcp $mask ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}
		#  fm=`basename $mask`
		#                        fm=`${FSLDIR}/bin/remove_ext $fm`
		#check if file already existst in ppi_masks_highres directory
                mbase=`basename $mask`
                mbase=`${FSLDIR}/bin/remove_ext $mbase`
                if [ $isHIGHRES = 1 ] ; then
                    if [ `${FSLDIR}/bin/imtest ${OUTPUTDIR}/struct/ppi_masks_highres/${mbase}` = 0 ] ; then
                        ${FSLDIR}/bin/imcp $mask ${OUTPUTDIR}/struct/ppi_masks_highres/
                    fi
                    ${FSLDIR}/bin/flirt -in ${OUTPUTDIR}/struct/ppi_masks_highres/${fmask}  -applyxfm -init ${OUTPUTDIR}/reg/highres2example_func.mat -ref ${OUTPUTDIR}/example_func -o ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}_native -datatype float

                else
                    
                    if [ `${FSLDIR}/bin/imtest ${OUTPUTDIR}/struct/ppi_masks_standard/${mbase}` = 0 ] ; then
                        ${FSLDIR}/bin/imcp $mask ${OUTPUTDIR}/struct/ppi_masks_standard/
                    fi
                    #need extension for SPM

		    if [ $XFMFLIRT = 0 ]; then
			echo   "${FSLDIR}/bin/applywarp -i ${OUTPUTDIR}/struct/ppi_masks_standard/${fmask}  -w ${OUTPUTDIR}/reg/standard2highres_warp --postmat=${OUTPUTDIR}/reg/highres2example_func.mat -r ${OUTPUTDIR}/example_func -o ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}_native -d float" >> ${OUTPUTDIR}/log.txt

			${FSLDIR}/bin/applywarp -i ${OUTPUTDIR}/struct/ppi_masks_standard/${fmask}  -w ${OUTPUTDIR}/reg/standard2highres_warp --postmat=${OUTPUTDIR}/reg/highres2example_func.mat -r ${OUTPUTDIR}/example_func -o ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}_native -d float

		    else
			{
			    echo "convert_xfm ${OUTPUTDIR}/reg/standard2highres.mat -inverse ${OUTPUTDIR}/reg/highres2standard.mat"
			    echo "convert_xfm -omat ${OUTPUTDIR}/reg/standard2example_func.mat -concat ${OUTPUTDIR}/reg/highres2example_func.mat ${OUTPUTDIR}/reg/standard2highres.mat"
			    echo "${FSLDIR}/bin/flirt -in  ${OUTPUTDIR}/struct/ppi_masks_standard/${fmask} -ref ${OUTPUTDIR}/example_func -out ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}_native -applyxfm -init ${OUTPUTDIR}/reg/standard2example_func.mat"

			    }>> ${OUTPUTDIR}/log.txt
			convert_xfm ${OUTPUTDIR}/reg/standard2highres.mat -inverse ${OUTPUTDIR}/reg/highres2standard.mat
			convert_xfm -omat ${OUTPUTDIR}/reg/standard2example_func.mat -concat ${OUTPUTDIR}/reg/highres2example_func.mat ${OUTPUTDIR}/reg/standard2highres.mat
			${FSLDIR}/bin/flirt -in  ${OUTPUTDIR}/struct/ppi_masks_standard/${fmask} -ref ${OUTPUTDIR}/example_func -out ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}_native -applyxfm -init ${OUTPUTDIR}/reg/standard2example_func.mat

		    fi




                fi

		#       ${FSLDIR}/bin/fslorient -deleteorient ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}_native

		#  ${FSLDIR}/bin/fslmaths  ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}_native -thr 0.5 -bin  ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}_native
		${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}_native -bin ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}_native_bin -odt short

                
                ${FSLDIR}/bin/fslchfiletype NIFTI ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}_native_bin
                MASK=`${FSLDIR}/bin/imglob -extensions ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}_native_bin`



                #need to write over the split data so for timeseries extraction
		# I trick SPM here by changing the time-series data

		if [ $VERBOSE = 1 ] ; then
		    echo "Weighting time sereis to get PVE weighted series..."
		fi

		#this part is used to weight ppi by PVE
		#${FSLDIR}/bin/imcp ${OUTPUTDIR}/prefiltered_func_data ${OUTPUTDIR}/prefiltered_func_data_orig
		#export FSLOUTPUTTYPE
                ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/prefiltered_func_data -mul ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/${fmask}_native ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/prefiltered_func_data_ppi

		#this is not original prefiltered func ..BEWARE!!!
                ${FSLDIR}/bin/fslchfiletype NIFTI ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/prefiltered_func_data_ppi

		#                        ${FSLDIR}/bin/fslsplit ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/prefiltered_func_data_ppi ${OUTPUTDIR}/sfmri_grot

		#                       ${FSLDIR}/bin/imrm ${OUTPUTDIR}/prefiltered_func_data_ppi

		if [ $VERBOSE = 1 ] ; then
		    echo "done"
		fi

		if [ $VERBOSE = 1 ] ; then
		    echo "Extraxting ROI time-series...."
		fi

		#copy SPM.mat
		cp ${OUTPUTDIR}/${MODEL_NAME}.spm/SPM.mat ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/

                #EXTRACT TIME SERIES FROM ROI (1st eigenvariate)
		#  ${ANALYSIS_PIPE_DIR}/analysis_pipeline_SPM_VOI.sh ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/run_voi.m ${MASK}  ${con} ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/ ${fmask}_con_${con} ${OUTPUTDIR}/${MODEL_NAME}.spm/SPM.mat
		${ANALYSIS_PIPE_DIR}/analysis_pipeline_SPM_VOI.sh ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/run_voi.m ${MASK}  ${con} ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/ ${fmask}_con_${con} ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/SPM.mat ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/prefiltered_func_data_ppi

		#run time series extraction
                CURDIR=`pwd`
                cd ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/
                echo "cd ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/ ; run_voi" | matlab -nodesktop -nosplash
                cd $CURDIR

                ${FSLDIR}/bin/imrm ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/prefiltered_func_data_ppi

		if [ $VERBOSE = 1 ] ; then
		    echo "done"

		fi
		if [ $VERBOSE = 1 ] ; then
		    echo "Reset time-series data and moving VOI_${fmask}_con_${con}_session_*.mat files..."
		fi
		#                        ${FSLDIR}/bin/imrm ${OUTPUTDIR}/prefiltered_func_data
                #    ${FSLDIR}/bin/immv ${OUTPUTDIR}/prefiltered_func_data_orig   ${FSLDIR}/bin/imrm ${OUTPUTDIR}/prefiltered_func_data

                /bin/mv ${OUTPUTDIR}/${MODEL_NAME}.spm/VOI_${fmask}_con_${con}_session_*.mat ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/


		if [ $VERBOSE = 1 ] ; then
		    echo "done"
		fi
		if [ $VERBOSE = 1 ] ; then
		    echo "Doing PPI "
		fi


		#move VOI  files into PPI directory
		#                       echo "move VOI file"

		#DO PPI MODELS
echo "${ANALYSIS_PIPE_DIR}/analysis_pipeline_SPM_PPI.sh ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/run_ppi.m ${MASK}  ${con} ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/ ${fmask}_con_${con} ${OUTPUTDIR}/${MODEL_NAME}.spm/SPM.mat"  >> ${OUTPUTDIR}/log.txt
                ${ANALYSIS_PIPE_DIR}/analysis_pipeline_SPM_PPI.sh ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/run_ppi.m ${MASK}  ${con} ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/ ${fmask}_con_${con} ${OUTPUTDIR}/${MODEL_NAME}.spm/SPM.mat

		#run PPI using matlab
		#but first remove existing SPM.mat if exists
                if [ -f ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/SPM.mat ] ; then 
                    /bin/rm ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/SPM.mat 
                fi
		#run PPI
		#split to write over the pve weighted time series
		#                        ${FSLDIR}/bin/fslsplit ${OUTPUTDIR}/prefiltered_func_data ${OUTPUTDIR}/sfmri_grot

                CURDIR=`pwd`
                cd ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/
                echo "cd ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/ ; run_ppi" | matlab -nodesktop -nosplash
                cd $CURDIR

                /bin/mv ${OUTPUTDIR}/${MODEL_NAME}.spm/PPI_${fmask}_con_${con}.mat ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/


		if [ $VERBOSE = 1 ] ; then
		    echo "done"
		fi

		#apply regsitration to PPI contrast 

                for im in `${FSLDIR}/bin/imglob  ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/con_0*.hdr  ${OUTPUTDIR}/${MODEL_NAME}.ppi/${fmask}_con_${con}/spmT_0*.hdr` ; do 
                    f=`basename $im`
                    f=`${FSLDIR}/bin/remove_ext $f`
		    #place in the reg_standard directory 
                    if [ ! -d ${OUTPUTDIR}/reg_standard/${MODEL_NAME}.ppi/${fmask}_con_${con} ] ; then
                        /bin/mkdir -p ${OUTPUTDIR}/reg_standard/${MODEL_NAME}.ppi/${fmask}_con_${con}
                    fi


                    if [ $XFMFLIRT = 0 ]; then
                        echo   "${FSLDIR}/bin/applywarp -i $im  -w ${OUTPUTDIR}/reg/highres2standard_warp --premat=${OUTPUTDIR}/reg/example_func2highres.mat -r $STANDARD_BRAIN -o ${OUTPUTDIR}/reg_standard/${MODEL_NAME}.ppi/${fmask}_con_${con}/${f}_mni -m ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil" >> ${OUTPUTDIR}/log.txt
                        ${FSLDIR}/bin/applywarp -i $im  -w ${OUTPUTDIR}/reg/highres2standard_warp --premat=${OUTPUTDIR}/reg/example_func2highres.mat -r $STANDARD_BRAIN -o ${OUTPUTDIR}/reg_standard/${MODEL_NAME}.ppi/${fmask}_con_${con}/${f}_mni -m ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil
                    else
                        {
                            if [ ! -f ${OUTPUTDIR}/reg/example_func2standard.mat ] ; then
                                echo "convert_xfm -omat ${OUTPUTDIR}/reg/example_func2standard.mat -concat ${OUTPUTDIR}/reg/highres2standard.mat ${OUTPUTDIR}/reg/example_func2highres.mat"
                                convert_xfm -omat ${OUTPUTDIR}/reg/example_func2standard.mat -concat ${OUTPUTDIR}/reg/highres2standard.mat ${OUTPUTDIR}/reg/example_func2highres.mat
                            fi
                            echo "${FSLDIR}/bin/flirt -in $im -ref $STANDARD_BRAIN -applyxfm -init ${OUTPUTDIR}/reg/highres2standard.mat -out ${OUTPUTDIR}/reg_standard/${MODEL_NAME}.ppi/${fmask}_con_${con}/${f}_mni_lin"
                            }>> ${OUTPUTDIR}/log.txt


                        ${FSLDIR}/bin/flirt -in $im -ref $STANDARD_BRAIN -applyxfm -init ${OUTPUTDIR}/reg/highres2standard.mat -out ${OUTPUTDIR}/reg_standard/${MODEL_NAME}.ppi/${fmask}_con_${con}/${f}_mni_lin

                    fi

                done

            done


        done

	${FSLDIR}/bin/imrm `cat ${OUTPUTDIR}/spm_jobs/job_smooth.m_ims3d.txt`

    fi
elif [ $DO_RESTING = 1 ] ; then
    ${FSLDIR}/bin/fslchfiletype NIFTI_GZ ${OUTPUTDIR}/prefiltered_func_data


    #first convert FWHM (HZ) to sigma (seconds)
    #NEED TO DIVIDE BY 2 cutoff_hz_hp is FWHM (Hz) = 1/2sigma
    LP_SIGMA_CUTOFF_SEC=`echo "scale=11;1.0 / $LP_FREQ_CUTOFF_HZ "  | bc `
    LP_SIGMA_CUTOFF_VOL=`echo "scale=11;$LP_SIGMA_CUTOFF_SEC / $TR / 2.355" | bc `
    echo $LP_FREQ_CUTOFF_HZ $LP_SIGMA_CUTOFF_SEC $LP_SIGMA_CUTOFF_VOL
    HP_SIGMA_CUTOFF_SEC=`echo "scale=11;1.0 / $HP_FREQ_CUTOFF_HZ "  | bc `
    HP_SIGMA_CUTOFF_VOL=`echo "scale=11;$HP_SIGMA_CUTOFF_SEC / $TR / 2.355" | bc `
    # echo $HP_FREQ_CUTOFF_HZ $HP_SIGMA_CUTOFF_SEC $HP_SIGMA_CUTOFF_VOL
    INPUT_DATA=${OUTPUTDIR}/prefiltered_func_data


    #add pluses
    if [ $DO_FILTERING = 1 ] ; then 
        # INPUT_DATA=${OUTPUTDIR}/filtered_func_data
        
        #if giving atlas will put fileterd func in .fc folder
        if [ ! $DO_ATLAS_CONN = 0 ] ; then
            atlas_name=""
            #if [ "_" = "_${FIRST_CONN_REGIONS}" ] ; then 
            if [ `${FSLDIR}/bin/imtest $ATLAS_CONN` = 0 ] ; then 
                echo "FC ROIs,$ATLAS_CONN ,  is not a valid image"
                exit 1
            fi
            atlas_name=`basename $ATLAS_CONN`
            atlas_name=`${FSLDIR}/bin/remove_ext $atlas_name`
            Nvols=`${FSLDIR}/bin/fslnvols $ATLAS_CONN`

            #else
	    if [ ! "_" = "_${FIRST_CONN_REGIONS}" ] ; then               

		#for individualized connecitivity ROIs
		#		    if [ ${MODEL_NAME} = model ]; then
		atlas_name=${atlas_name}_wfirst
		#		    else
		#			atlas_name=${atlas_name}_w$MODEL_NAME
		#		    fi

		NvolsFIRST=`echo $FIRST_CONN_REGIONS | wc | awk '{ print $2 }'`
                Nvols=`echo "$Nvols + $NvolsFIRST " | bc` 
		echo "NVOLS : $Nvols"
		echo $FIRST_CONN_REGIONS | wc 
	    fi
	     if [ $DO_ATLAS_CONN = 2 ] ; then 
		   while [ -d ${OUTPUTDIR}/${atlas_name}.fc_mni ] ;do 
                atlas_name="${atlas_name}+"
            done


            if [ ! -d ${OUTPUTDIR}/${atlas_name}.fc_mni ] ; then
                /bin/mkdir ${OUTPUTDIR}/${atlas_name}.fc_mni
            fi
            # if [ $Nvols -le 1 ] ; then
            #     echo "currecntly only support 4D FC rois in this script"
            #     exit 1
            # fi
            INPUT_DATA=${OUTPUTDIR}/${atlas_name}.fc_mni/filtered_func_data

		 
		 else
            while [ -d ${OUTPUTDIR}/${atlas_name}.fc_mni ] ;do 
                atlas_name="${atlas_name}+"
            done


            if [ ! -d ${OUTPUTDIR}/${atlas_name}.fc ] ; then
                /bin/mkdir ${OUTPUTDIR}/${atlas_name}.fc
            fi
            # if [ $Nvols -le 1 ] ; then
            #     echo "currecntly only support 4D FC rois in this script"
            #     exit 1
            # fi
            INPUT_DATA=${OUTPUTDIR}/${atlas_name}.fc/filtered_func_data
			fi

        else
            INPUT_DATA=${OUTPUTDIR}/filtered_func_data
        fi

        

	#re-filetring now
	#  if [ `${FSLDIR}/bin/imtest ${OUTPUTDIR}/filtered_func_data` = 0 ] ; then 
        echo "filter data"
        #imcp ${OUTPUTDIR}/prefiltered_func_data ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/filtered_func_data_bu
        echo "Bandpass filtering the data between $HP_SIGMA_CUTOFF_VOL - $LP_SIGMA_CUTOFF_VOL (volumes)"
        
	echo " ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/prefiltered_func_data -bptf $HP_SIGMA_CUTOFF_VOL $LP_SIGMA_CUTOFF_VOL $INPUT_DATA -odt float"

	${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/prefiltered_func_data -bptf $HP_SIGMA_CUTOFF_VOL $LP_SIGMA_CUTOFF_VOL $INPUT_DATA -odt float
        echo LOWPASS $LP_FREQ_CUTOFF_HZ $LP_SIGMA_CUTOFF_SEC $LP_SIGMA_CUTOFF_VOL > ${INPUT_DATA}_freq_range.txt 
        echo HIGHPASS $HP_FREQ_CUTOFF_HZ $HP_SIGMA_CUTOFF_SEC $HP_SIGMA_CUTOFF_VOL >> ${INPUT_DATA}_freq_range.txt
        

	#allows you to filter data without connectiviuty
        if [ $DO_ATLAS_CONN = 0 ] ; then
            ${FSLDIR}/bin/imrm ${OUTPUTDIR}/prefiltered_func_data
        fi
	#               else 
	#                   echo "Use already filtered data"

	#               fi
    else 
        if [ ! $DO_ATLAS_CONN = 0 ] ; then
            if [ `${FSLDIR}/bin/imtest $ATLAS_CONN` = 0 ] ; then 
                echo "FC ROIs,$ATLAS_CONN ,  is not a valid image"
                exit 1
            fi
            atlas_name=`basename $ATLAS_CONN`
            atlas_name=`${FSLDIR}/bin/remove_ext $atlas_name`
            atlas_name="noFilt_${atlas_name}"
            
			  if [ $DO_ATLAS_CONN = 2 ] ; then
			while [ -d ${OUTPUTDIR}/${atlas_name}.fc_mni ] ; do 
					atlas_name="${atlas_name}+"
				done


				if [ ! -d ${OUTPUTDIR}/${atlas_name}.fc_mni ] ; then
					/bin/mkdir ${OUTPUTDIR}/${atlas_name}.fc_mni
				fi
				
			
			else
				while [ -d ${OUTPUTDIR}/${atlas_name}.fc_mni ] ; do 
					atlas_name="${atlas_name}+"
				done


				if [ ! -d ${OUTPUTDIR}/${atlas_name}.fc_mni ] ; then
					/bin/mkdir ${OUTPUTDIR}/${atlas_name}.fc_mni
				fi
				
			fi
			
			
            Nvols=`${FSLDIR}/bin/fslnvols $ATLAS_CONN`
            if [ $Nvols -le 1 ] ; then
                echo "currecntly only support 4D FC rois in this script"
                exit 1
            fi
        fi

        echo "Not filtering Data ${atlas_name}"

    fi
    #ATLAS CONN =1 - Native space stream
    #atals conn = 2 - mni space stream

    if [ $DO_ATLAS_CONN = 1 ] ; then #native space stream
	
	#to do native space FIRST mask for connectivity, lets xfm surfaces to native space, then fill them, then run connectivity, other wise use specified atlas
	USED_ATLAS=0
	if [ `${FSLDIR}/bin/imtest ${ATLAS_CONN}` = 1 ] ; then #make sure atlasexistst
            echo "Found $Nvols number of parcels"
            #Register atlas to native space
	    USED_ATLAS=1
	    

	    
	    if [ $XFMFLIRT = 0 ]; then
		echo   " ${FSLDIR}/bin/applywarp -i ${ATLAS_CONN} -r  ${OUTPUTDIR}/example_func -w ${OUTPUTDIR}/reg/standard2highres_warp --postmat=${OUTPUTDIR}/reg/highres2example_func.mat -o  ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_native  -d float" >> ${OUTPUTDIR}/log.txt
		${FSLDIR}/bin/applywarp -i ${ATLAS_CONN} -r  ${OUTPUTDIR}/example_func -w ${OUTPUTDIR}/reg/standard2highres_warp --postmat=${OUTPUTDIR}/reg/highres2example_func.mat -o  ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_native  -d float
	    else
		{
		    echo "${FSLDIR}/bin/convert_xfm -omat ${OUTPUTDIR}/reg/standard2example_func.mat -concat ${OUTPUTDIR}/reg/highres2example_func.mat ${OUTPUTDIR}/reg/standard2highres.mat"
		    echo "${FSLDIR}/bin/flirt -in ${ATLAS_CONN} -ref ${OUTPUTDIR}/example_func -applyxfm -init ${OUTPUTDIR}/reg/standard2example_func.mat -out ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_native"
		    if [ ! -f ${OUTPUTDIR}/reg/standard2highres.mat ] ;then
			echo "${FSLDIR}/bin/convert_xfm -omat ${OUTPUTDIR}/reg/standard2highres.mat -inverse ${OUTPUTDIR}/reg/highres2standard.mat"
		    fi
		    
		    }>> ${OUTPUTDIR}/log.txt
		
		if [ ! -f ${OUTPUTDIR}/reg/standard2highres.mat ] ; then
                    ${FSLDIR}/bin/convert_xfm -omat ${OUTPUTDIR}/reg/standard2highres.mat -inverse ${OUTPUTDIR}/reg/highres2standard.mat
		fi 
		
		${FSLDIR}/bin/convert_xfm -omat ${OUTPUTDIR}/reg/standard2example_func.mat -concat ${OUTPUTDIR}/reg/highres2example_func.mat ${OUTPUTDIR}/reg/standard2highres.mat
		${FSLDIR}/bin/flirt -in ${ATLAS_CONN} -ref ${OUTPUTDIR}/example_func -applyxfm -init ${OUTPUTDIR}/reg/standard2example_func.mat -out ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_native
		
	    fi
	fi
	
	if [ ! "_" = "_${FIRST_CONN_REGIONS}" ] ; then    # FIRST DEFINED REGIONS
	    #serves as label in atlas
	    AT_IMS=""
	    count=1

	    for i_f in $FIRST_CONN_REGIONS ; do
		lt=0;
		ut=0;
		if [ $i_f = L_Amyg ] ; then
		    lt=17.5
		    ut=18.5
		elif [ $i_f = R_Amyg ] ; then
		    lt=53.5
		    ut=54.5
		elif [ $i_f = L_Thal ] ; then
		    lt=9.5
		    ut=10.5
		elif [ $i_f = R_Thal ] ; then
		    lt=48.5
		    ut=49.5
		elif [ $i_f = L_Caud ] ; then
		    lt=10.5
		    ut=11.5
		elif [ $i_f = R_Caud ] ; then
		    lt=49.5
		    ut=50.5
		elif [ $i_f = L_Puta ] ; then
		    lt=11.5
		    ut=12.5
		elif [ $i_f = R_Puta ] ; then
		    lt=50.5
		    ut=51.5
		elif [ $i_f = L_Pall ] ; then
		    lt=12.5
		    ut=13.5
		elif [ $i_f = R_Pall ] ; then
		    lt=51.5
		    ut=52.5
		elif [ $i_f = L_Hipp ] ; then
		    lt=16.5
		    ut=17.5
		elif [ $i_f = R_Hipp ] ; then
		    lt=52.5
		    ut=53.5
		elif [ $i_f = L_Accu ] ; then
		    lt=25.5
		    ut=26.5
		elif [ $i_f = R_Accu ] ; then
		    lt=57.5
		    ut=58.5
		else
		    echo "invalid FIRST region selected : $i_f"
		    exit 1
		fi

		#make sure that structure is valid
		if [ $i_f = L_Amyg ] ; then
		    junk=""
		elif [ $i_f = R_Amyg ] ; then
		    junk=""
		elif [ $i_f = L_Thal ] ; then
		    junk=""
		elif [ $i_f = R_Thal ] ; then
		    junk=""
		elif [ $i_f = L_Caud ] ; then
		    junk=""
		elif [ $i_f = R_Caud ] ; then
		    junk=""
		elif [ $i_f = L_Puta ] ; then
		    junk=""
		elif [ $i_f = R_Puta ] ; then
		    junk=""
		elif [ $i_f = L_Pall ] ; then
		    junk=""
		elif [ $i_f = R_Pall ] ; then
		    junk=""
		elif [ $i_f = L_Hipp ] ; then
		    junk=""
		elif [ $i_f = R_Hipp ] ; then
		    junk=""
		elif [ $i_f = L_Accu ] ; then
		    junk=""
		elif [ $i_f = R_Accu ] ; then
		    junk=""
		else
		    echo "invalid FIRST region selected : $i_f"
		    exit 1
		fi

		#extract region
		if [ ! -f ${REG_ETKIN_DIR}/struct/first/first-${i_f}_first.vtk ] ; then 
		    echo "Subcortical segmentation:${REG_ETKIN_DIR}/struct/first/first-${i_f}_first.vtk, not found "
		    exit 1
		fi
		#		fslsurfacemaths ${REG_ETKIN_DIR}/struct/first/first-${i_f}_first.vtk -applyxfm ${OUTPUTDIR}/reg/highres2example_func.mat -fillMesh ${OUTPUTDIR}/example_func $count  ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_${i_f} ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_${i_f}.gii
		#include entire mesh?
		#        fslmaths ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_${i_f} -bin ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_${i_f}

		if [ `imtest ${OUTPUTDIR}/struct/${i_f}_first_highres` = 0  ] ; then
		    echo " ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/struct/first_all_fast_firstseg -thr $lt -uthr $ut -bin ${OUTPUTDIR}/struct/${i_f}_first_highres" >> ${OUTPUTDIR}/log.txt
		    ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/struct/first_all_fast_firstseg -thr $lt -uthr $ut -bin ${OUTPUTDIR}/struct/${i_f}_first_highres
		fi
		echo "flirt -in ${OUTPUTDIR}/struct/${i_f}_first_highres -applyxfm -init ${OUTPUTDIR}/reg/highres2example_func.mat -ref ${OUTPUTDIR}/example_func -out ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_${i_f}" >> ${OUTPUTDIR}/log.txt
		flirt -in ${OUTPUTDIR}/struct/${i_f}_first_highres -applyxfm -init ${OUTPUTDIR}/reg/highres2example_func.mat -ref ${OUTPUTDIR}/example_func -out ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_${i_f}

		AT_IMS="${AT_IMS} ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_${i_f}"
		let count+=1

	    done
	    echo "Native space images : $AT_IMS "
	    if [ `imtest ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_native` = 1 ] ; then
		fslmerge -t ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_native ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_native $AT_IMS
		#		atlas_name="${atlas_name}_wfirst"
	    else
		fslmerge -t ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_native  $AT_IMS
	    fi

	    #        fslmerge -t  ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_native
	    echo "Mering into single atlas : ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_native"

	fi
        #need to create label text file
	#incorporate FAST results
	#fslmaths ${i}/struct/pve_1_2_example_func -mul ${i}/atlas_122_4D.fc/atlas_122_4D_native  -thr 0.5 -bin ${i}/atlas_122_4D.fc/atlas_122_4D_native_gm  -odt short
        label=1
        if [ -f ${OUTPUTDIR}/${atlas_name}.fc/labels.txt ] ; then 
            /bin/rm ${OUTPUTDIR}/${atlas_name}.fc/labels.txt
        fi

        while [ $label -le $Nvols ] ; do
            echo "Creating labels.txt : $label : ${OUTPUTDIR}/${atlas_name}.fc/labels.txt "
            echo $label >> ${OUTPUTDIR}/${atlas_name}.fc/labels.txt 
            let label+=1
        done
        echo "Do atlas connectivity ${OUTPUTDIR}/${atlas_name}.fc"
        if [ $GM_ONLY = 1 ] ; then
            
            echo "Transform pve_1 to native functional space"
            ${FSLDIR}/bin/flirt -in ${OUTPUTDIR}/struct/brain_fnirt_pve_1 -ref ${OUTPUTDIR}/example_func -applyxfm -init ${OUTPUTDIR}/reg/highres2example_func.mat -out  ${OUTPUTDIR}/struct/brain_fnirt_pve_1_2_example_func -datatype float

            echo "threshold pve_1"
	    #                ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/struct/brain_fnirt_pve_1_2_example_func -thr 0.5  -bin ${OUTPUTDIR}/struct/brain_fnirt_gmseg_2_example_func

            ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/struct/brain_fnirt_pve_1_2_example_func -thr 0.25 -bin ${OUTPUTDIR}/struct/brain_fnirt_gmseg_2_example_func
	    #${FSLDIR}/bin/imrm  ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/struct/brain_fnirt_pve_1_2_example_func
            #also add in subcortical segmentation
            echo "trasnform firstseg"

            ${FSLDIR}/bin/flirt -in ${OUTPUTDIR}/struct/first_all_fast_firstseg -ref  ${OUTPUTDIR}/example_func -applyxfm -init ${OUTPUTDIR}/reg/highres2example_func.mat -out ${OUTPUTDIR}/struct/first_all_fast_firstseg_2_example_func  -datatype float

            ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/struct/first_all_fast_firstseg_2_example_func -thr 0.5 -add ${OUTPUTDIR}/struct/brain_fnirt_gmseg_2_example_func  -bin ${OUTPUTDIR}/struct/brain_fnirt_gmseg_2_example_func 

	    ${FSLDIR}/bin/applywarp -i ${FSLDIR}/data/atlases/Cerebellum/Cerebellum-MNIfnirt-maxprob-thr0-2mm.nii.gz  -w ${OUTPUTDIR}/reg/standard2highres_warp --postmat=${OUTPUTDIR}/reg/highres2example_func.mat -r ${OUTPUTDIR}/example_func  -o  ${OUTPUTDIR}/struct/brain_fnirt_cerebellum_2_example_func

	    ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/struct/brain_fnirt_cerebellum_2_example_func -thr 0.5 -add ${OUTPUTDIR}/struct/brain_fnirt_gmseg_2_example_func -bin  ${OUTPUTDIR}/struct/brain_fnirt_gmseg_2_example_func 


	    #do all processing for GM mask except masking
	    if [ $RESTING_GM_MASK = 1 ] ; then


                ${FSLDIR}/bin/fslmaths ${INPUT_DATA} -mas ${OUTPUTDIR}/struct/brain_fnirt_gmseg_2_example_func ${INPUT_DATA}
		
            fi
        fi

        if [ $USE_MOTION = 1 ] ; then               

            if [ ! -d ${OUTPUTDIR}/${atlas_name}.fc/mc ] ; then 
		echo "/bin/mkdir ${OUTPUTDIR}/${atlas_name}.fc/mc"  >>${OUTPUTDIR}/log.txt
                /bin/mkdir ${OUTPUTDIR}/${atlas_name}.fc/mc
            fi
            echo "${FSLDIR}/bin/fslmaths ${INPUT_DATA} -Tmean ${OUTPUTDIR}/${atlas_name}.fc/mc/avg_func"  >>${OUTPUTDIR}/log.txt
            ${FSLDIR}/bin/fslmaths ${INPUT_DATA} -Tmean ${OUTPUTDIR}/${atlas_name}.fc/mc/avg_func

            echo "${FSLDIR}/bin/fsl_glm --demean -i ${INPUT_DATA} -d ${OUTPUTDIR}/mc/prefiltered_func_data_mcf.par.txt -o ${OUTPUTDIR}/${atlas_name}.fc/mc/motion_betas --out_res=${OUTPUTDIR}/${atlas_name}.fc/mc/motion_residuals"  >>${OUTPUTDIR}/log.txt
            ${FSLDIR}/bin/fsl_glm --demean -i ${INPUT_DATA} -d ${OUTPUTDIR}/mc/prefiltered_func_data_mcf.par.txt -o ${OUTPUTDIR}/${atlas_name}.fc/mc/motion_betas --out_res=${OUTPUTDIR}/${atlas_name}.fc/mc/motion_residuals

            echo "${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/${atlas_name}.fc/mc/motion_residuals -add ${OUTPUTDIR}/${atlas_name}.fc/mc/avg_func ${OUTPUTDIR}/${atlas_name}.fc/mc/motion_residuals -odt float"  >>${OUTPUTDIR}/log.txt
            ${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/${atlas_name}.fc/mc/motion_residuals -add ${OUTPUTDIR}/${atlas_name}.fc/mc/avg_func ${OUTPUTDIR}/${atlas_name}.fc/mc/motion_residuals -odt float


            INPUT_DATA=${OUTPUTDIR}/${atlas_name}.fc/mc/motion_residuals
            MOTION_FC="/mc/"

        fi

        echo "${ETKINLAB_DIR}/bin/atlas_connectivity  -i  ${INPUT_DATA} -a ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_native --atlas4D=${OUTPUTDIR}/${atlas_name}.fc/labels.txt -m  ${OUTPUTDIR}/struct/brain_fnirt_gmseg_2_example_func -o ${OUTPUTDIR}/${atlas_name}.fc/${MOTION_FC}${atlas_name}_connectivity ${SEEDS_TARGETS} ${ATLAS_CONN_OPTS}" >>${OUTPUTDIR}/log.txt
	${ETKINLAB_DIR}/bin/atlas_connectivity  -i  ${INPUT_DATA} -a ${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_native --atlas4D=${OUTPUTDIR}/${atlas_name}.fc/labels.txt -m  ${OUTPUTDIR}/struct/brain_fnirt_gmseg_2_example_func -o ${OUTPUTDIR}/${atlas_name}.fc/${MOTION_FC}${atlas_name}_connectivity ${SEEDS_TARGETS} ${ATLAS_CONN_OPTS}

echo RUN GBC HERE 
	#run gbc
	echo "	${ETKINLAB_DIR}/bin/atlas_connectivity  -i  ${INPUT_DATA}  -m  ${OUTPUTDIR}/struct/brain_fnirt_gmseg_2_example_func -o ${OUTPUTDIR}/${atlas_name}.fc/${MOTION_FC}gmseg --doGBC"  >>${OUTPUTDIR}/log.txt
	${ETKINLAB_DIR}/bin/atlas_connectivity  -i  ${INPUT_DATA}  -m  ${OUTPUTDIR}/struct/brain_fnirt_gmseg_2_example_func -o ${OUTPUTDIR}/${atlas_name}.fc/${MOTION_FC}gmseg --doGBC

	#run_alff
	{
	    echo ${ETKINLAB_DIR}/bin/run_alff -i ${INPUT_DATA} -m ${OUTPUTDIR}/mask -o ${OUTPUTDIR}/${atlas_name}.fc/${MOTION_FC}falff --tr=${TR} -d ${delVols}
	    echo ${ETKINLAB_DIR}/bin/run_alff -i ${INPUT_DATA} -m ${OUTPUTDIR}/mask -o ${OUTPUTDIR}/${atlas_name}.fc/${MOTION_FC}falff_rms --tr=${TR} -d ${delVols}
	} >> ${OUTPUTDIR}/log.txt


	${ETKINLAB_DIR}/bin/run_alff -i ${INPUT_DATA} -m ${OUTPUTDIR}/mask -o ${OUTPUTDIR}/${atlas_name}.fc/${MOTION_FC}falff --tr=${TR} -d ${delVols}
	${ETKINLAB_DIR}/bin/run_alff -i ${INPUT_DATA} -m ${OUTPUTDIR}/mask -o ${OUTPUTDIR}/${atlas_name}.fc/${MOTION_FC}falff_rms --tr=${TR} -d ${delVols}


	#do transform to mni space 
	if [ ! -d ${OUTPUTDIR}/reg_standard/${atlas_name}.fc/ ]; then 
	    mkdir -p ${OUTPUTDIR}/reg_standard/${atlas_name}.fc
	fi
	if [ $USE_MOTION = 1 ] ; then
	    IMROI=${OUTPUTDIR}/${atlas_name}.fc/mc/${atlas_name}_connectivity_roi_z.nii.gz
	else
	    IMROI=${OUTPUTDIR}/${atlas_name}.fc/${atlas_name}_connectivity_roi_z.nii.gz

	fi

	if [ `${FSLDIR}/bin/imtest $IMROI` = 1 ] ; then #do if existst

	    if [ $XFMFLIRT = 0 ]; then
		echo "${FSLDIR}/bin/applywarp -i $IMROI  -w ${OUTPUTDIR}/reg/highres2standard_warp --premat=${OUTPUTDIR}/reg/example_func2highres.mat -r $STANDARD_BRAIN -o ${OUTPUTDIR}/reg_standard/${atlas_name}.fc/${atlas_name}_connectivity_roi_z_mni" >>${OUTPUTDIR}/log.txt

		${FSLDIR}/bin/applywarp -i $IMROI  -w ${OUTPUTDIR}/reg/highres2standard_warp --premat=${OUTPUTDIR}/reg/example_func2highres.mat -r $STANDARD_BRAIN -o ${OUTPUTDIR}/reg_standard/${atlas_name}.fc/${atlas_name}_connectivity_roi_z_mni

	    else
		{
		    echo "convert_xfm -omat ${OUTPUTDIR}/reg/example_func2standard.mat -concat ${OUTPUTDIR}/reg/highres2standard.mat ${OUTPUTDIR}/reg/example_func2highres.mat"
		    echo "${FSLDIR}/bin/flirt -in $IMROI -ref $STANDARD_BRAIN -applyxfm -init ${OUTPUTDIR}/reg/example_func2standard.mat -out ${OUTPUTDIR}/reg_standard/${atlas_name}.fc/${atlas_name}_connectivity_roi_z_mni"
		    }>> ${OUTPUTDIR}/log.txt

		convert_xfm -omat ${OUTPUTDIR}/reg/example_func2standard.mat -concat ${OUTPUTDIR}/reg/highres2standard.mat ${OUTPUTDIR}/reg/example_func2highres.mat

		${FSLDIR}/bin/flirt -in $IMROI -ref $STANDARD_BRAIN -applyxfm -init ${OUTPUTDIR}/reg/example_func2standard.mat -out ${OUTPUTDIR}/reg_standard/${atlas_name}.fc/${atlas_name}_connectivity_roi_z_mni


	    fi


	fi


	#clean up the motion residuals                                                                                                                                                   
        if [ $DO_DEL_FILTFUNC_RES = 1 ] ; then
            if [ `${FSLDIR}/bin/imtest ${OUTPUTDIR}/${atlas_name}.fc/filtered_func_data` = 1 ] ; then
                ${FSLDIR}/bin/imrm ${OUTPUTDIR}/${atlas_name}.fc/filtered_func_data
            fi

        fi



        #clean up the motion residuals  
        if [ $DO_DEL_MC_RES = 1 ] ; then
            if [ $USE_MOTION = 1 ] ; then 
                if [ `${FSLDIR}/bin/imtest ${OUTPUTDIR}/${atlas_name}.fc/mc/motion_residuals` = 1 ] ; then 
                    ${FSLDIR}/bin/imrm ${OUTPUTDIR}/${atlas_name}.fc/mc/motion_residuals
                fi
            fi
        fi

    elif [ $DO_ATLAS_CONN = 2 ] ; then 

        echo "ruin in mni space"
		USED_ATLAS=0
		if [ `${FSLDIR}/bin/imtest ${ATLAS_CONN}` = 1 ] ; then #make sure atlasexistst
            echo "Found $Nvols number of parcels"
            #Register atlas to native space
			USED_ATLAS=1
	      label=1
        if [ -f ${OUTPUTDIR}/${atlas_name}.fc_mni/labels.txt ] ; then 
            /bin/rm ${OUTPUTDIR}/${atlas_name}.fc_mni/labels.txt
        fi

        while [ $label -le $Nvols ] ; do
            echo "Creating labels.txt : $label : ${OUTPUTDIR}/${atlas_name}.fc_mni/labels.txt "
            echo $label >> ${OUTPUTDIR}/${atlas_name}.fc_mni/labels.txt 
            let label+=1
        done


			if [ $USE_MOTION = 1 ] ; then               

				if [ ! -d ${OUTPUTDIR}/${atlas_name}.fc_mni/mc ] ; then 
					echo "/bin/mkdir ${OUTPUTDIR}/${atlas_name}.fc_mni/mc"  >>${OUTPUTDIR}/log.txt
					/bin/mkdir ${OUTPUTDIR}/${atlas_name}.fc_mni/mc
				fi
				echo "${FSLDIR}/bin/fslmaths ${INPUT_DATA} -Tmean ${OUTPUTDIR}/${atlas_name}.fc_mni/mc/avg_func"  >>${OUTPUTDIR}/log.txt
				${FSLDIR}/bin/fslmaths ${INPUT_DATA} -Tmean ${OUTPUTDIR}/${atlas_name}.fc_mni/mc/avg_func

				echo "${FSLDIR}/bin/fsl_glm --demean -i ${INPUT_DATA} -d ${OUTPUTDIR}/mc/prefiltered_func_data_mcf.par.txt -o ${OUTPUTDIR}/${atlas_name}.fc_mni/mc/motion_betas --out_res=${OUTPUTDIR}/${atlas_name}.fc_mni/mc/motion_residuals"  >>${OUTPUTDIR}/log.txt
				${FSLDIR}/bin/fsl_glm --demean -i ${INPUT_DATA} -d ${OUTPUTDIR}/mc/prefiltered_func_data_mcf.par.txt -o ${OUTPUTDIR}/${atlas_name}.fc_mni/mc/motion_betas --out_res=${OUTPUTDIR}/${atlas_name}.fc_mni/mc/motion_residuals

				echo "${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/${atlas_name}.fc_mni/mc/motion_residuals -add ${OUTPUTDIR}/${atlas_name}.fc_mni/mc/avg_func ${OUTPUTDIR}/${atlas_name}.fc_mni/mc/motion_residuals -odt float"  >>${OUTPUTDIR}/log.txt
				${FSLDIR}/bin/fslmaths ${OUTPUTDIR}/${atlas_name}.fc_mni/mc/motion_residuals -add ${OUTPUTDIR}/${atlas_name}.fc_mni/mc/avg_func ${OUTPUTDIR}/${atlas_name}.fc_mni/mc/motion_residuals -odt float


				INPUT_DATA=${OUTPUTDIR}/${atlas_name}.fc_mni/mc/motion_residuals
				MOTION_FC="/mc/"

			fi
#XFM TO standard space 
echo "${FSLDIR}/bin/applywarp -i ${INPUT_DATA} -r  ${STANDARD_BRAIN} -w ${OUTPUTDIR}/reg/highres2standard_warp --postmat=${OUTPUTDIR}/reg/example_func2highres.mat -m ${BRAIN_MASK_MNI} -o  ${INPUT_DATA}_2_mni   -d float"
						${FSLDIR}/bin/applywarp -i ${INPUT_DATA} -r  ${STANDARD_BRAIN} -w ${OUTPUTDIR}/reg/highres2standard_warp --premat=${OUTPUTDIR}/reg/example_func2highres.mat -m /usr/local/fsl//data/standard/MNI152_T1_2mm_brain_mask_dil -o  ${INPUT_DATA}_2_mni   -d float 
						INPUT_DATA=${INPUT_DATA}_2_mni
						echo "Run connectivity "
						${ETKINLAB_DIR}/bin/atlas_connectivity  -i  ${INPUT_DATA} -a ${ATLAS_CONN} --atlas4D=${OUTPUTDIR}/${atlas_name}.fc_mni/labels.txt -m  /usr/local/fsl//data/standard/MNI152_T1_2mm_brain_mask_dil -o ${OUTPUTDIR}/${atlas_name}.fc_mni/${MOTION_FC}${atlas_name}_connectivity ${SEEDS_TARGETS} ${ATLAS_CONN_OPTS}

		fi
	#	echo RUN GBC 
	#	echo "	${ETKINLAB_DIR}/bin/atlas_connectivity  -i  ${INPUT_DATA}  -m  ${OUTPUTDIR}/struct/brain_fnirt_gmseg_2_example_func -o ${OUTPUTDIR}/${atlas_name}.fc/${MOTION_FC}gmseg --doGBC"  >>${OUTPUTDIR}/log.txt
	#	${ETKINLAB_DIR}/bin/atlas_connectivity  -i  ${INPUT_DATA}  -m  ${OUTPUTDIR}/struct/brain_fnirt_gmseg_2_example_func -o ${OUTPUTDIR}/${atlas_name}.fc/${MOTION_FC}gmseg --doGBC

		
	#clean up the motion residuals                                                                                                                                                   
        if [ $DO_DEL_FILTFUNC_RES = 1 ] ; then
            if [ `${FSLDIR}/bin/imtest ${OUTPUTDIR}/${atlas_name}.fc_mni/filtered_func_data` = 1 ] ; then
                ${FSLDIR}/bin/imrm ${OUTPUTDIR}/${atlas_name}.fc_mni/filtered_func_data
            fi

        fi



        #clean up the motion residuals  
        if [ $DO_DEL_MC_RES = 1 ] ; then
            if [ $USE_MOTION = 1 ] ; then 
                if [ `${FSLDIR}/bin/imtest ${OUTPUTDIR}/${atlas_name}.fc_mni/mc/motion_residuals` = 1 ] ; then 
                    ${FSLDIR}/bin/imrm ${OUTPUTDIR}/${atlas_name}.fc_mni/mc/motion_residuals
                fi
            fi
        fi
		
    fi
fi
