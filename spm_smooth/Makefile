# $Id: Makefile,v 1.1.1.1 2010/08/18 16:44:15 brian Exp $
include ${FSLCONFDIR}/default.mk

#CC = llvm-gcc
#CXX = llvm-g++
#ARCHFLAGS = -arch x86_64
#ARCHLDFLAGS = -arch x86_64


PROJNAME = etkin_graph_theory



USRINCFLAGS = -I ./utils -I${INC_NEWMAT} -I${INC_ZLIB} -I${INC_PROB} -I${INC_BOOST} 
USRLDFLAGS = -L${LIB_NEWMAT} -L${LIB_PROB}  -L${LIB_ZLIB} -L./ -L./utils

LIBS+=-lnewimage -lmiscmaths -lprob -lfslio -lniftiio -lznz -lutils -lnewmat   -lutils -lz

XFILES=spm_smooth


all:  ${XFILES}


spm_smooth: spm_smooth.o
	${CXX} ${CXXFLAGS} ${LDFLAGS} -o $@ spm_smooth.o ${LIBS}
