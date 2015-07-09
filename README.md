#Summary
This analysis pipeline is merely a bash script that bring together our structural and functional processing stream. It brings together components of FSL and SPM as well as integrates some custom code (typically implemented in C++).
#Software requirements.
This pipeline is for use on OSX or linux (tested on CentOS/RedHat). It requires the installation of FSL and SPM8. There will be some adjustments to the SPM8 configuration for our purposes. For OSX, it requires a version of readlink that is consistent with linux (i.e. has the -f option).
# Installation 
###Getting the data
If you are reading this, you should already have access to the analysis pipeline git repository that is hosted on www.bitbucket. org. The first step is to clone the repository into a local folder. The location is up to you, however, if you are planning to parallelize the jobs on a grid, it should by copied to a centralized location. The follow command will clone the repository,
         git clone https://bitbucket.org/bmpatena/analysis_pipeline
This will create a directory with an assortment of files in it needed for you to run the pipeline. Now it’s time to setup your environment variables.
The file spm defaults.m should be used instead of that distributed by spm. There is two differences: 1) disables the implicit masking (i.e. set threshold to -inf) and 2) defaults.cmdline=true which is used to disable the GUI. The latter is required in order to parallelize/run in background. This file needs to substitute that which is in SPM.
### Setting Up Environment
It is assumed at this point that FSL has been installed and you environment has been setup. I’ve set these environments computer wide by editing /etc/profile. Otherwise, you can add to you personal profile. From a lab management perspective, the former facilitate consistency across all users. Note that the variable ETKINLAB DIR is set to ANALYSIS PIPE DIR. For distribution, I’ve included builds for the necessary tools within the analysis pipeline directory
###Location of the install
export ANALYSIS PIPE DIR=/PATH TO SRC/analysis pipeline/ export PATH=${ANALYSIS_PIPE_DIR}:${PATH}
export ${ETKINLAB DIR}=${ANALYSIS PIPE DIR}
###Location of SPM install used for pipeline.
export SPM8DIR=/Applications/spm8 sge
###fink
source /sw/bin/init.sh
###Some Notes
• I use a local copy of SPM for performance issues with network copy; may not be an issue for you.
￼￼￼￼￼￼￼￼￼￼￼￼￼￼￼1
• SPM image IO is not very friendly with network file system, this may be a cause of slow down if too many parallel instances exist.
• source /sw/bin/init.sh is only need for OSX. fink is used to install a version of readlink that is consistent with linux.