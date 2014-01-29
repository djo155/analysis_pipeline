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
	echo "Fourth : SPM.mat files"
	echo "***TR is assumed to be in seconds and is extracted form SPM.mat file"
	exit

}
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
shift
VOIPPI_NAME=$1
shift 
#SPMMAT=`readlink -f $1`
#SPMMAT=`readlink -f '${1}' | sed 's/${1}//g'`
SPMMAT=`echo ${1} | sed 's/${1}//g'`
shift
echo SPMMAT $SPMMAT
#separate jobs into N_scripts m-files
#lets leave this constant at 1, aimed at using on single user
N_scripts=1

#read in name of mask and use this to name VOI and PPI analysis 
VOI_NAME=$VOIPPI_NAME
PPI_NAME=$VOIPPI_NAME

shift


if [ -f $matlab_script ] ; then 
	echo "File: $matlab_script already exists, removing"
    rm $matlab_script
# exit 1
fi



#input common setup variable for each m-file to run 
	echo "clear"								>> $matlab_script
echo "addpath '${SPM8DIR}'"				>> ${matlab_script}

    echo "addpath '${ANALYSIS_PIPE_DIR}/ppi_matlab_scripts'" >> $matlab_script
	echo "%set up PPI parameters "				>> $matlab_script
	echo "TYPE_OF_ANALYSIS='ppi'"				>> $matlab_script
	echo "output_dir='';"						>> $matlab_script
	echo "">> $matlab_script
	echo "">> $matlab_script
	echo "%Run subjects ">> $matlab_script
	echo "">> $matlab_script
    echo "VOI_name='${VOIPPI_NAME}'" >> $matlab_script
#	data_path=`dirname $SPMMAT`
data_path=`echo $SPMMAT | sed 's/SPM.mat//g'`

    echo "ppi_dir='${OUTPUTDIR}'"                 >> $matlab_script
    echo  "contrast_number=${contrast_number}" >> $matlab_script
	echo "">>$matlab_script
	echo "">>$matlab_script
	echo "">>$matlab_script
	echo "ppi_name='${PPI_NAME}';"				>> $matlab_script

echo "data_path='${data_path}'; "		>> $matlab_script
#    data_path=`echo $SPMMAT | sed 's/SPM.mat//g'`

    echo "spmmat='SPM.mat'"					>> $matlab_script
	
	echo "etkinlab_ppi"						>> $matlab_script

