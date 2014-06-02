
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
count=0
con_ims=""
for i in `${FSLDIR}/bin/imglob ${1}/reg_standard/${MODEL}.spm/con*` ; do 

   echo "Found : $i "
   con_ims="${con_ims} `basename $i`"
   let count+=1
done 
echo $con_ims 

if [ $count = 0 ] ; then 
    echo "Did not find any valid contrasts. "
else
    echo "Found $count contrasts"
fi 

echo "Searching for missing models."
missing=0
for i in $@ ; do 
    if [ -d ${i}/${MODEL}.spm ] ; then 
	echo "${i}/${MODEL}.spm is missing."
	let missing+=1
    fi
done 

if [ $missing -gt 0 ] ; then 
    echo "There were $missing missing folders. Exiting..."
    exit 1
fi 



#find all the images
#images=""
#for i in $@ ; do 
#    f=`${FSLDIR}/bin/imglob -extension ${i}/reg/



#done
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
