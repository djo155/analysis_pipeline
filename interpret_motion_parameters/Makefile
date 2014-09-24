# $Id: Makefile,v 1.1.1.1 2010/08/18 16:44:15 brian Exp $
include ${FSLCONFDIR}/default.mk

CC = llvm-gcc
CXX = llvm-g++
ARCHFLAGS = -arch x86_64
ARCHLDFLAGS = -arch x86_64


PROJNAME = interpret_motion_parameters

#LD_LIBRARY_PATH=${FSLDIR}/lib

USRINCFLAGS = -I${INC_NEWMAT} -I${INC_ZLIB} -I${INC_PROB} -I${INC_BOOST}
USRLDFLAGS =  -L${LIB_PROB} -L${LIB_NEWMAT} -L${LIB_ZLIB}

SULIBS=-lmisc_utils
LIBS+=-lfirst_lib -lmeshclass -lnewimage -lmiscmaths -lprob -lfslio -lniftiio -lznz -lutils -lnewmat  -lz
FMLIBS= -lshapeModel -lfslvtkio -lmeshclass -lnewimage -lmiscmaths  -lfslio -lniftiio -lznz -lnewmat -lutils -lprob -lz

XFILES=interpret_motion_parameters


all:  ${XFILES}

interpret_motion_parameters: interpret_motion_parameters.o
	${CXX} ${CXXFLAGS} ${LDFLAGS} -o $@ interpret_motion_parameters.o ${LIBS}


