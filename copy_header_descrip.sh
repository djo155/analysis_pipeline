#!/bin/sh
im_ref=$1
im_in=$2
im_out=$3

Usage (){
    echo "copy_header_descrip.sh im_ref im_in im_out"

}

#extract header descript field
descrip_line=`${FSLDIR}/bin/fslhd -x $im_ref | grep descrip`
echo "Description $descrip_line "

${FSLDIR}/bin/fslhd -x $im_in > grot_${im_out}
N=`wc  grot_${im_out} | awk '{ print $1 }'`

if [ -f grot2_${im_out} ] ;then 
    rm grot2_${im_out}
fi
count=0
while [ $count -lt $N ] ; do 
    line=`cat grot_${im_out} | sed -n "${count}p"`
    id=`echo $line | awk '{ print $1 }'`
    echo id $id 
if [ $id = "descrip" ]; then 
        echo $descrip_line >> grot2_${im_out}
    else 
        echo $line >> grot2_${im_out}
    fi
    let count+=1
done

${FSLDIR}/bin/imcp $im_in $im_out  

#${FSLDIR}/bin/fslcreatehd grot2_${im_out} $im_out 

