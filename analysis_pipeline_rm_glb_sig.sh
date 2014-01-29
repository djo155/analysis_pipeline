#!/bin/sh 
#
#!/bin/sh
#input 1: JObdirectory
#input 2: jobname 
#input 3: Output directory, needs to be full path
#input 4...: Images to run on =

Usage() {
    echo ""
    echo "Usage:   analysis_pipeline_rm_glb_sig.sh -func_data <image4D> -ref_data <image4D> -mask <image> -outname <outimage>..."
    echo ""
    echo "-outname : base output name"
    echo "-mask : native functional space wm/csf mask from which to estimate global signal from."
    echo "-func_data : functional data to remove global signal from."
    echo "-ref_data : functional data to estimate global signal from. "
    echo ""
    echo ""
    exit 1
}
############################################################################################
#######################HERE ARE THE FUNCTIONS USED BY THIS SCRIPT###########################
############################################################################################

################################  Remove Global Signal from Data (via regression)  #########

function func_remove_global_signal {

    #time-series data from which to estimated/remove global signal
    func_data=$1
    ref_data=$2
    #Global signal is defined as the mean signal with specified mask
    mask=$3
    #3rd input, ouput name, strip any image extensions from name
    #Uses output directory instead with common naming convention
    
    output=`${FSLDIR}/bin/remove_ext $4`
    OUTPUTDIR=`dirname $output`
    output=`basename $output`
    
    #Use fslstats to calculate mean signal from within mask,
    #create a constant regressor (i.e. column of ones), to be used in regression and
    #combine estimate "global signal" and columns of ones. This corresponds to the methods used in Amit's original matlab script
    fslstats -t $ref_data -k $mask -M | sed 's/^/1 /' > ${OUTPUTDIR}/${output}_global_signal_design.txt

    #perform regression and claculate output residual 
    ${FSLDIR}/bin/fsl_glm -i ${func_data} -d ${OUTPUTDIR}/${output}_global_signal_design.txt -o ${OUTPUTDIR}/${output}_betas --out_res=${OUTPUTDIR}/${output} # --out_t=${output}_t

    #add back the mean to the residual (was removed by the regression)
    fslmaths ${func_data} -Tmean -add ${OUTPUTDIR}/${output} ${OUTPUTDIR}/${output}

    #Clean up unnecessary data
    ${FSLDIR}/bin/imrm ${OUTPUTDIR}/${output}_betas

}

###########################################################################################
##############################END OF FUNCTIONS ############################################
###########################################################################################

#all input options need to start with "-"

OUTPUTDIR=""

required=0


while [ _${1:0:1} = _- ] ; do 
    if [ ${1} = -outname ] ; then 
	OUTPUTNAME=`readlink -f $2`
	shift 2
	let required+=1
    elif [ ${1} = -mask ] ; then 
        MASK=`readlink -f $2`
        MASK=`remove_ext $MASK`
        shift 2
        let required+=1
    elif [ ${1} = -func_data ] ; then 
        FUNC_DATA=`readlink -f $2`
        FUNC_DATA=`remove_ext $FUNC_DATA`
        shift 2
        let required+=1
    elif [ ${1} = -ref_data ] ; then 
        REFFUNC_DATA=`readlink -f $2`
        REFFUNC_DATA=`remove_ext $REFFUNC_DATA`
        shift 2
        let required+=1
    else
	echo "Unrecognized option: ${1}"
	exit 1
    fi
done
if [ $required -ne 4 ] ; then 
    echo "Invalid number of inputs into global signal removal script"
    exit 1
fi

######### This stage removes global signal via regression  

        #May need to add in estmation from none smoother point, then applied to smoothed data
func_remove_global_signal ${FUNC_DATA} ${REFFUNC_DATA} ${MASK} ${OUTPUTNAME}









