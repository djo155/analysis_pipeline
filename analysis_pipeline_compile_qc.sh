#!/bin/sh

function Usage()
{
 echo "\n analysis_pipeline_compile_qc.sh <output> <ana_dir_0> ... <ana_dir_1>"
}

OUT=$1
shift 1

if [ $OUT ] ; then
    if [ -f $OUT ] || [ -d $OUT ] ; then
        echo "$OUT already exists, please remove before proceeding"
        exit 1
    fi
fi
echo "Directory,`cat ${1}/report/summaryheader.csv`" > $OUT

for i in $@ ; do
#Check existence
    if [ ! -f ${i}/report/summary.csv ] ; then
        echo MISSING $i
    else
        echo "${i},`cat ${i}/report/summary.csv`" >> $OUT
    fi
done


