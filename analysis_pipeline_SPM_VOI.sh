#!/bin/sh
function Usage {
			
	echo "Expected 4 inputs. $# were given."
	echo ""
	echo "Usage: "
	echo ""
	echo "First  : Name of matlab script to run all subjects and sessions  "
	echo "Second : Name of the mask to be used for the VOI"
    echo "Third : Contrast Number"
    echo "Fourth : Ouput directory"
    echo "Fifth : VOI/PPI name"
	echo "Sixth : SPM.mat files"
	echo "***TR is assumed to be in seconds and is extracted form SPM.mat file"
	exit

}
VERBOSE=0
if [ $1 == -v ]; then
    VERBOSE=$2
    shift 2
fi



if [  $1 == '-h' ] ; then 
    Usage 
fi 

if [ ! ${#} -ne 4 ] ; then 

    Usage
fi

#name of matlab script to run 
matlab_script=`readlink -f $1`;
shift
mask_name=`readlink -f $1`
shift
contrast_number=$1
shift
OUTPUTDIR=`readlink -f $1`
echo OUTPUTDIR $OUTPUTDIR
shift
VOIPPI_NAME=$1
echo name $VOIPPI_NAME
shift 
#this is the help handle blank spaces
#remove readlink to allow link paths without breakign due to space
SPMMAT=`readlink -f ${1} | sed 's/${1}//g'`
SPMMAT=`echo ${1} | sed 's/${1}//g'`

readlink -f ${1}
echo SPMMAT $1 $SPMMAT

shift
#separate jobs into N_scripts m-files
#lets leave this constant at 1, aimed at using on single user
N_scripts=1

#read in name of mask and use this to name VOI and PPI analysis 
VOI_NAME=$VOIPPI_NAME
PPI_NAME=$VOIPPI_NAME

IMAGE=`readlink -f $1`
IMAGE=`${FSLDIR}/bin/imglob -extension $IMAGE`
echo IMAGE $IMAGE
NVOLS=`${FSLDIR}/bin/fslnvols $IMAGE`
shift
echo NVOLS $NVOLS

if [ -f $matlab_script ] ; then 
	echo "File: $matlab_script already exists, removing"
    rm $matlab_script
# exit 1
fi


if [ $VERBOSE = 1 ]; then
    echo "Setting up VOI extraction for PPI..."
fi
#input common setup variable for each m-file to run
	echo "clear all"								>> $matlab_script
    echo "addpath '${SPM8DIR}';"				>> ${matlab_script}
    echo "addpath '${ANALYSIS_PIPE_DIR}/ppi_matlab_scripts';" >> $matlab_script
	echo "%set up PPI parameters "				>> $matlab_script
	echo "TYPE_OF_ANALYSIS='ppi';"				>> $matlab_script
	echo "multiple_comparison_method='none';"	>> $matlab_script
	echo "threshold=1;"							>> $matlab_script
	echo "output_dir='';"						>> $matlab_script
	echo "cluster_extent=0;"					>> $matlab_script
	echo "VOI_type='mask';"					>> $matlab_script
	echo "VOI_spec ='${mask_name}';"						>> $matlab_script
	echo "VOI_contrast_adjust = 0 ; "			>> $matlab_script
	echo "">> $matlab_script
	echo "">> $matlab_script
	echo "%Run subjects ">> $matlab_script
	echo "">> $matlab_script

if [ $VERBOSE = 1 ]; then
    echo "...SPMMAT : $SPMMAT"
    echo "...Ouput Directory : $OUTPUTDIR"
    echo "...Contrast Number : $contrast_number"
    echo "...VOI name : $VOI_NAME"
    echo "...PPI name : $PPI_NAME"
fi

#	data_path=`dirname $SPMMAT`
    data_path=`echo $SPMMAT | sed 's/SPM.mat//g'`
    echo "ppi_dir='${OUTPUTDIR}';"                 >> $matlab_script

    echo "load('${SPMMAT}');" >> $matlab_script
    echo "SPM.swd='${OUTPUTDIR}';"  >> $matlab_script
count=1;
while [ $count -le $NVOLS ]; do
    echo "SPM.xY.VY(${count}).fname='${IMAGE}';" >> $matlab_script
    let count+=1
done
#do multi-sesssion portion
sess=2
index=$count
for im in $@ ; do
    IMAGE=`readlink -f $im`
    IMAGE=`${FSLDIR}/bin/imglob -extension $im`
    echo IMAGE $sess $IMAGE
    NVOLS=`${FSLDIR}/bin/fslnvols $IMAGE`
    count=1
    while [ $count -le $NVOLS ]; do
        echo "SPM.xY.VY(${index}).fname='${IMAGE}';" >> $matlab_script
        let count+=1
        let index+=1
    done

let sess+=1
done
    echo "save('${SPMMAT}','SPM'); ">> $matlab_script
    echo "clear SPM ; " >> $matlab_script

    echo  "contrast_number=${contrast_number};" >> $matlab_script
	echo "">>$matlab_script
	echo "">>$matlab_script
	echo "">>$matlab_script
	echo "VOI_name = '${VOI_NAME}';"			>> $matlab_script
	echo "ppi_name='${PPI_NAME}';"				>> $matlab_script

	echo "data_path='${data_path}'; "		>> $matlab_script
    echo "spmmat='SPM.mat'"					>> $matlab_script
	
	echo "etkinlab_voi"						>> $matlab_script

if [ $VERBOSE = 1 ]; then
    echo "...done"
fi

