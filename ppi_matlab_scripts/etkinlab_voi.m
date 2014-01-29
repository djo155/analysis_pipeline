%This has been adapted from ....

% This batch script analyses the Attention to Visual Motion fMRI dataset
% available from the SPM site using PPI:
% http://www.fil.ion.ucl.ac.uk/spm/data/attention/
% as described in the SPM manual:
%  http://www.fil.ion.ucl.ac.uk/spm/doc/manual.pdf

% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Guillaume Flandin & Darren Gitelman
% $Id: ppi_spm_batch.m 17 2009-09-28 15:37:01Z guillaume $

%spm_jobman is repsonsible for runnning jobs without X11 
%jobs stores current jobs to be done
%clear jobs empties the variable. i.e. erases all jobs

% Initialise SPM
%---------------------------------------------------------------------

%clear
disp(strcat('The data path has been set to: ',data_path))

spm('Defaults','fMRI');


%replace jobman's mkdir and change directory commands because deprecated

% Working directory (useful for .ps outputs only)
%---------------------------------------------------------------------
if (~exist(data_path,'dir'))
    disp(strcat('Data Path does not exist: ', data_path))
    return
end
cd(data_path)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VOLUME OF INTERESTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

spmmat=fullfile(data_path,'SPM.mat');

voiname_org=VOI_name;
NUMBER_OF_SESSIONS = get_number_of_sessions(fullfile(data_path,'SPM.mat'));
for session_index = 1: NUMBER_OF_SESSIONS

    %-----------RUN VOI---------------------
    VOI_session=session_index;
   % VOI_name=strcat(voiname_org,strcat('_session_',num2str(session_index)));
	VOI_name=strcat(voiname_org,'_session');

    % EXTRACT THE EIGENVARIATE
    %---------------------------------------------------------------------

    model=load(spmmat);

    xSPM.swd=data_path ;
    xSPM.title=VOI_name;
    xSPM.XYZmm=VOI_spec;

    xY.name = VOI_name;
    xY.Ic   = VOI_contrast_adjust;
    xY.Sess = VOI_session;
    xY.def  = VOI_type;
    xY.spec = VOI_spec;

    [Y,xY]  = spm_regions_brian(xSPM,model.SPM,xY);
    display('done spm_regions_brian')
   % save(strcat('xSPM_',strcat(VOI_name,strcat('_session_',num2str(session_index)))))
end
display('done etkinlab_voi')



