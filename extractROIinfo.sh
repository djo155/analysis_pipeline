#!/bin/sh
function Usage(){   
        echo "***********************************\n\n"
        echo "Usage: \n\n"
        echo "extractROIinfo.sh <output.csv> -c <con1,con2,con3,...> [-cname <conName1,conName2,conName3,...>] [-ppi <seeds> ] <analysis_dirs> <masks> "
        echo "\n\n ***********************************"
}
# Fir
#input desired masks 
#
contrasts=""
contrasts_names=""
PPI=0
SEEDS=""
masks=""
analysis_dirs=""


if [ $# -lt 3 ] ; then 
    Usage  
    exit 1
fi
output=$1
d=`date "+%Y-%m-%d"`
output=${output}-${d}.csv
shift 1

if [ -f $output ] ;then
    echo "File exists (${output}), overwrite (y/n)?"
    overwrite="n"
    read overwrite
    if [ $overwrite = y ] ; then 
        rm $output  
    else
        exit 1
    fi
fi

echo $1
#separate analysis directories and masks
#for im in $@ ; do 
while [ $# -gt 0 ] ; do 
    echo "input $1"
    if [ $1 = -c  ] ; then 

# echo $1 | sed 's/,/ /g' > grot_${output}
        contrasts=`echo $2 | sed 's/,/ /g'`
#contrasts=`echo $2 | sed 's/,/ /g'`
        echo "Contrasts : $contrasts"
        shift 2
    elif [ $1 = -cname  ] ; then 

        # echo $1 | sed 's/,/ /g' > grot_${output}
        contrasts_names=`echo $2 | sed 's/,/ /g'`
        #contrasts=`echo $2 | sed 's/,/ /g'`
        echo "Contrasts Names : $contrasts_names"
        shift 2

    elif [ $1 = -ppi ] ; then 
        PPI=1
        SEEDStemp=`echo $2 | sed 's/,/ /g'`
        for i in $SEEDStemp ; do 
            grot=`basename $i`
            grot=`${FSLDIR}/bin/remove_ext $grot`
            SEEDS="${SEEDS} $grot" 
        done
        echo PPI_SEEDS $SEEDS
        shift 2
    elif [ `${FSLDIR}/bin/imtest $1` = 1 ] ; then 
        masks="${masks} $1"
        shift 1
    elif [ -d $1 ] ; then 
        analysis_dirs="${analysis_dirs} $1"
        shift 1
    else
        echo "Unknown input $1"
        exit 1
    fi 
done
echo next

#find model names
    Nm=0
    modelNames=""
    sub0=`echo $analysis_dirs | awk '{ print $1 }'`
    echo "First subject : $sub0"

    #whether to extract for PPI or SPM models
    if [ $PPI = 0 ]; then 

        for i in ${sub0}/reg_standard/*.spm ; do 
            modelNames="${modelNames} $i"
            let Nm+=1
        done
    else
        for i in ${sub0}/reg_standard/*.ppi ; do 
            modelNames="${modelNames} $i"
            let Nm+=1
        done

    fi


    model=""
    if [ $Nm = 0 ] ; then 
        echo "Could not find any analysis directories for $i"
        exit 1
    elif [ $Nm -gt 1 ] ; then 

        echo "found multple models run:"
    for i in $modelNames ; do 
        basename $i .spm
    done
        echo "please choose one: "
        input model
    else
        if [ $PPI = 0 ]; then 
            model=`basename $modelNames .spm`
        else
            model=`basename $modelNames .ppi`
        fi
    fi

echo "Extracting Data for model $model ..."
#------------------------------------------MNI SPACE PROCESSING---------------------------------------
labels="ImageName"
count=0
for dir in $analysis_dirs ; do
    image_name=`echo $dir | awk -F . '{ print $1 }'`
    line=`basename $image_name`
    echo "Subject : $dir "
    Ccount=1
    for C in $contrasts ; do 
        Cname=""    
        if [ ! "_${contrasts_names}" = "_" ]; then 
#Cname=`
            echo $contrasts_names | awk "{ print \$$Ccount }" > ${output}_grot
            Cname=`cat ${output}_grot`
            rm ${output}_grot
            Cname="_$Cname"
          
            echo Cname $Cname
        fi
        echo ".....Contrast $C"   

        if [ $PPI = 0 ] ; then 

            for i in $masks ; do
                                echo ".........${dir}/reg_standard/${model}.spm/con_000${C}_mni"
                    val=`${FSLDIR}/bin/fslstats ${dir}/reg_standard/${model}.spm/con_000${C}_mni -n -k $i -M`
                    line="${line},${val}" 
                    i=`remove_ext $i`
                    i=`basename $i`           
                    labels="${labels},SPM_Mask_${i}_Con_${C}${Cname}"
             done
        else
            for seed in $SEEDS ; do 
            for i in $masks ; do
                echo ".........${dir}/reg_standard/${model}.ppi/${seed}_con_${C}/con_0001_mni"
                val=`${FSLDIR}/bin/fslstats ${dir}/reg_standard/${model}.ppi/${seed}_con_${C}/con_0001_mni -n -k $i -M`
                line="${line},${val}" 
                i=`remove_ext $i`
                i=`basename $i`    
                labels="${labels},PPI_Seed_${seed}_Mask_${i}_Con_${C}${Cname}"
            done
            done
        fi

        let Ccount+=1
    done
    if [ $count = 0 ] ;then 
        echo $labels >> $output
    fi
    echo $line >> $output

    let count+=1
done
#------------------------------------------------------------------------------------------------------------

