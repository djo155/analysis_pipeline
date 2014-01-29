#!/bin/sh

function Usage(){

    echo "\n Usage : \n\n spm_group_analysis <output_dir> <image_0.nii> <image_1.nii> ... <image_N.nii> \n\n"

}

if [ $# -le 2 ] ; then
    echo "Not enough input arguments "
    Usage
    exit 1
fi

output_dir=`echo $1 | sed 's/\.spm_group//g'`
shift 1

while [ -d $output_dir ] ; do
    output_dir=${output_dir}+
done

output_dir=${output_dir}.spm_group