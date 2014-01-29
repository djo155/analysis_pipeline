#!/bin/sh

#take in list of output directories...
out=$1
shift 1
for i in $@ ; do 

    echo $i `${ETKINLAB_DIR}/bin/interpret_motion_parameters ${i}/mc/prefiltered_func_data_mcf.par.txt ${i}/struct/*_brain.nii.gz ` 
echo $i `${ETKINLAB_DIR}/bin/interpret_motion_parameters ${i}/mc/prefiltered_func_data_mcf.par.txt ${i}/struct/*_brain.nii.gz ` >> ${out}

done

