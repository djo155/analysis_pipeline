
Usage(){
echo ""
echo "check_highres2standard.sh <output> <modelname> <analysis directories....>"
echo ""
exit 1
}


if [ $# -le 1 ] ; then 
Usage
fi

output=$1 
shift 1
MODEL=$1
shift 



if [ ! -d ${output} ] ; then 
    /bin/mkdir $output
fi

#find contrast to run 
echo "Searching for available contrast based on those found in ${1}..."
for i in `${FSLDIR}/bin/imglob -extension  ${1}/reg_standard/${MODEL}.spm/con*` ; do 

   echo "Found : $i "

done 


#find all the images
images=""
for i in $@ ; do 
    f=`${FSLDIR}/bin/imglob -extension ${i}/reg/



done
#    if [ `${FSLDIR}/bin/imtest ${i}/reg/highres2standard_warped` = 0 ] ; then 
#        echo "Invalid image : ${i}/reg/highres2standard_warped"
#    fi
#    f=`${FSLDIR}/bin/imglob -extension ${i}/reg/highres2standard_warped`
#echo $i $f
#    f=`readlink -f $f`
#    images="${images} $f"
#done
if [ 0 = 1 ] ; then 
#switch to desired output directory (allows concurrent slicesdir)
cd $output  

slicesdir -p ${FSLDIR}/data/standard/MNI152_T1_2mm $

mv slicesdir/* ./
/bin/rmdir slicesdir
f=`readlink -f index.html`
echo "Ignore FSL's link"
echo "Finished. To view, point your web browser at"
echo "file:${f}"
fi
