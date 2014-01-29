
Usage(){
echo ""
echo "check_highres2standard.sh <output> <analysis directories....>"
echo ""
exit 1
}


if [ $# -le 1 ] ; then 
Usage
fi

output=$1 
shift 1

if [ ! -d ${output} ] ; then 
    /bin/mkdir $output
fi


#find all the images
images=""
for i in $@ ; do 
    if [ `${FSLDIR}/bin/imtest ${i}/reg/highres2standard_warped` = 0 ] ; then 
        echo "Invalid image : ${i}/reg/highres2standard_warped"
    fi
    f=`${FSLDIR}/bin/imglob -extension ${i}/reg/highres2standard_warped`
echo $i $f
    f=`readlink -f $f`
    images="${images} $f"
done

#switch to desired output directory (allows concurrent slicesdir)
cd $output  

slicesdir -p ${FSLDIR}/data/standard/MNI152_T1_2mm $images

mv slicesdir/* ./
/bin/rmdir slicesdir
f=`readlink -f index.html`
echo "Ignore FSL's link"
echo "Finished. To view, point your web browser at"
echo "file:${f}"

