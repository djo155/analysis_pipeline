#!/bin/sh

Usage(){
    echo ""
    echo "average_warped_image.sh <output> <analysis directories....>"
    echo ""
    exit 1
}


if [ $# -le 1 ] ; then 
    Usage
fi

output=$1 
shift 1
${FSLDIR}/bin/fslmaths ${1}/reg/highres2standard_warped -mul 0 $output -odt float 

N=0
for i in $@ ; do 
    if [ `${FSLDIR}/bin/imtest ${i}/reg/highres2standard_warped` = 0 ] ; then 
        echo "Invalid image : ${i}/reg/highres2standard_warped"
    fi
    ${FSLDIR}/bin/fslmaths $output -add ${i}/reg/highres2standard_warped $output
    let N+=1
done

${FSLDIR}/bin/fslmaths $output -div $N $output