#!/bin/sh

function Usage(){

    echo "Usage"
    echo "run_extract_indiFIRST.sh [--append] <output> <structure> <modelname> <con_number XX> <imaging.analysis>"

}

function xfmMask(){

    
    ANADIR=$1
    RUNFILE1=$2
    RUNFILE2=$3

    shift 3

    for i_f in $@ ; do

        lt=0;
        ut=0;
        if [ $i_f = L_Amyg ] ; then
        lt=17.5
        ut=18.5
        elif [ $i_f = R_Amyg ] ; then
        lt=53.5
        ut=54.5
        elif [ $i_f = L_Thal ] ; then
        lt=9.5
        ut=10.5
        elif [ $i_f = R_Thal ] ; then
        lt=48.5
        ut=49.5
        elif [ $i_f = L_Caud ] ; then
        lt=10.5
        ut=11.5
        elif [ $i_f = R_Caud ] ; then
        lt=49.5
        ut=50.5
        elif [ $i_f = L_Puta ] ; then
        lt=11.5
        ut=12.5
        elif [ $i_f = R_Puta ] ; then
        lt=50.5
        ut=51.5
        elif [ $i_f = L_Pall ] ; then
        lt=12.5
        ut=13.5
        elif [ $i_f = R_Pall ] ; then
        lt=51.5
        ut=52.5
        elif [ $i_f = L_Hipp ] ; then
        lt=16.5
        ut=17.5
        elif [ $i_f = R_Hipp ] ; then
        lt=52.5
        ut=53.5
        elif [ $i_f = L_Accu ] ; then
        lt=25.5
        ut=26.5
        elif [ $i_f = R_Accu ] ; then
        lt=57.5
        ut=58.5
        else
        echo "invalid FIRST region selected : $i_f"
        exit 1
        fi

        #extract region

        if [ `${FSLDIR}/bin/imtest ${ANADIR}/struct/first_all_fast_firstseg` = 0 ] ; then
            echo "Subcortical segmentation:${ANADIR}/struct/first_all_fast_firstseg, not found "
            exit 1
        fi
        if [ ! -d ${ANADIR}/reg/first2func ]; then
            mkdir ${ANADIR}/reg/first2func
        fi
        if [ `${FSLDIR}/bin/imtest  ${ANADIR}/reg/first2func/${i_f}_first_2_func` = 0  ] ; then
# echo     fslsurfacemaths ${STRUCTDIR}/struct/first/first-${i_f}_first.vtk -applyxfm ${ANADIR}/reg/highres2example_func.mat -fillMesh ${ANADIR}/example_func 1 ${ANADIR}/first2func/${i_f}_first_2_func

            echo ${FSLDIR}/bin/fslmaths ${ANADIR}/struct/first_all_fast_firstseg -thr $lt -uthr $ut -bin ${ANADIR}/reg/first2func/${i_f}_first_highres >>$RUNFILE1
           echo ${FSLDIR}/bin/flirt -in ${ANADIR}/reg/first2func/${i_f}_first_highres -ref ${ANADIR}/example_func -applyxfm -init ${ANADIR}/reg/highres2example_func.mat -out ${ANADIR}/reg/first2func/${i_f}_first_2_func  >>$RUNFILE2
        fi

    done

}


if [ $# -lt 2 ] ; then
Usage
exit 1
fi
if [ _$1 = "_--append" ] ; then 
    shift 1  
    OUTPUT=$1
else
    OUTPUT=$1
    if [ -f $OUTPUT ]; then
	rm $OUTPUT
    fi
fi


shift
STRUCT=$1
shift 1
MODEL=$1
shift 1
CON=$1
shift
FOUT=`basename $OUTPUT`

if [ ! -d job_files ]; then
    mkdir job_files
fi

RUNFIRSTEXTRACT=job_files/${FOUT}_extract_indi_1.cmds
    RUNXFM=job_files/${FOUT}_extract_indi_2.cmds
    RUNFINALEXTRACT=job_files/${FOUT}_extract_indi_3.cmds
#files=job_files/${FOUT}_files_${STRUCT}.txt


if [ -f $RUNFIRSTEXTRACT ]; then
rm $RUNFIRSTEXTRACT
fi
if [ -f $RUNXFM ]; then

rm $RUNXFM
fi


if [ -f $RUNFINALEXTRACT ]; then
    rm $RUNFINALEXTRACT
fi

#if [ -f $files ]; then
#rm $files
#fi

FC=0
FILES=""
for i in $@ ; do
        echo "Extracting from $i ..."
        if [ -d ${i}/${MODEL}.spm ] ; then
            DIR=${i}/${MODEL}.spm
        elif [ -d ${i}/${MODEL}.fc ] ; then
            DIR=${i}/${MODEL}.fc
            FC=1
        else
            echo "${i}/${MODEL}.fc or ${i}/${MODEL}.spm  do not exist !"
            exit 1
        fi
        xfmMask $i $RUNFIRSTEXTRACT $RUNXFM $STRUCT
        if [ ! -d ${DIR}/extractions ]; then
            mkdir ${DIR}/extractions
        fi

        if [ $FC = 1 ] ; then

                echo "fslmeants -i  ${i}/${MODEL}.fc/mc/${MODEL}_connectivity_roi_z  -m ${i}/reg/first2func/${STRUCT}_first_2_func --transpose | sed -n '1p' > ${DIR}/extractions/${MODEL}_${STRUCT}_r2z.txt" >> $RUNFINALEXTRACT
#               echo ${DIR}/extractions/${MODEL}_${STRUCT}_r2z.txt >> $files
            FILES="${FILES} ${DIR}/extractions/${MODEL}_${STRUCT}_r2z.txt"
        else
# echo fslstats ${i}/${MODEL}.spm/con_00${CON} -k ${i}/reg/first2func/${STRUCT}_first_2_func -M
                echo "fslmeants -i  ${i}/${MODEL}.spm/con_00${CON}  -m ${i}/reg/first2func/${STRUCT}_first_2_func --transpose | sed -n '1p' > ${DIR}/extractions/${MODEL}_${STRUCT}_con_${CON}.txt" >> $RUNFINALEXTRACT
               FILES="${FILES} ${DIR}/extractions/${MODEL}_${STRUCT}_con_${CON}.txt"
#                echo ${DIR}/extractions/${MODEL}_${STRUCT}_con_${CON}.txt >> $files
        fi

done
ID_EXTRACT=0
ID_XFM=0
ID_FINALEXTRACT=0
ID_COMP=0


if [ -f $RUNFIRSTEXTRACT ]; then
    ID_EXTRACT=`fsl_sub -q short.q -N extract_first -l logs -t $RUNFIRSTEXTRACT`
fi
if [ -f $RUNXFM ]; then
    if [   $ID_EXTRACT = 0 ]; then
        ID_XFM=`fsl_sub -q short.q -N xfm_first -l logs -t $RUNXFM`
    else
        ID_XFM=`fsl_sub -q short.q -N xfm_first -l logs -j $ID_EXTRACT -t $RUNXFM`
    fi
fi

if [ -f $RUNFINALEXTRACT ]; then
    if [   $ID_XFM = 0 ]; then
        ID_FINALEXTRACT=`fsl_sub -q short.q -N extract_first -l logs -t $RUNFINALEXTRACT`
    else
        ID_FINALEXTRACT=`fsl_sub -q short.q -N extract_first -l logs -j $ID_XFM -t $RUNFINALEXTRACT`
    fi
fi


if [ -f job_files/${FOUT}_extract_indi_4.sh ]; then
    rm job_files/${FOUT}_extract_indi_4.sh
fi


echo "for i in $FILES ; do " > job_files/${FOUT}_extract_indi_4.sh
echo "echo \$i \`cat \$i\` >> $OUTPUT" >>job_files/${FOUT}_extract_indi_4.sh
echo "done">>job_files/${FOUT}_extract_indi_4.sh
chmod a+x job_files/${FOUT}_extract_indi_4.sh

if [   $ID_FINALEXTRACT = 0 ]; then
    ID_COMP=`fsl_sub -q short.q -N extract_first -l logs job_files/${FOUT}_extract_indi_4.sh`
else
    ID_COMP=`fsl_sub -q short.q -N extract_first -l logs -j $ID_FINALEXTRACT job_files/${FOUT}_extract_indi_4.sh`
fi

echo Running jobs : $ID_EXTRACT $ID_XFM $ID_FINALEXTRACT

echo $FILES




