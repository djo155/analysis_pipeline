Usage(){
echo ""
echo "check_example_func2highres.sh <output> <analysis directories....>"
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
echo output : $output

#find all the images
images=""
for i in $@ ; do 
    if [ `${FSLDIR}/bin/imtest ${i}/reg/example_func2highres` = 0 ] ; then 
        echo "Invalid image : ${i}/reg/example_func2highres"
    fi
    f=`${FSLDIR}/bin/imglob -extension ${i}/reg/example_func2highres`
#   f=`readlink -f $f`
    f2=`${FSLDIR}/bin/imglob -extension ${i}/struct/brain.nii.gz`
# f2=`readlink -f $f2`

    images="${images} $f $f2"
done

#switch to desired output directory (allows concurrent slicesdir)
#cd $output  

slicesdir -o $images

mv slicesdir/*  ${output}
/bin/rmdir slicesdir
echo "moving ouput"
f=`readlink -f index.html`
echo "Ignore FSL's link"
echo "Finished. To view, point your web browser at"
echo "file:${f}"

