#!/bin/sh 

FIRSTSEG=$1
shift 
#GMMASK-=output
GMMASK=$1
shift 

${FSLDIR}/bin/fslmaths $FIRSTSEG -thr 5 -uthr 43 ${GMMASK}_left
${FSLDIR}/bin/fslmaths $FIRSTSEG -thr 44 -uthr 59 ${GMMASK}_right
${FSLDIR}/bin/fslmaths ${GMMASK}_left -add ${GMMASK}_right -bin ${GMMASK}

${FSLDIR}/bin/imrm ${GMMASK}_left ${GMMASK}_right