%****etkinlab_voi scripts should be run as a prerequisite to this script 
spm('Defaults','fMRI');
spm_jobman('initcfg'); % SPM8 only (does nothing in SPM5)  % this creates the "jobs" variable which is a cell array


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PSYCHO-PHYSIOLOGIC INTERACTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% GENERATE PPI STRUCTURE
%=====================================================================



NUMBER_OF_SESSIONS = get_number_of_sessions(fullfile(data_path,'SPM.mat'));
% OUTPUT DIRECTORY
%--------------------------------------e-------------------------------

%xY come from etkinlab_voi script
% last variable says dont show graphics
%spmmat is first level model (created from first level GLM)

PPI=[];
voiname_org=VOI_name;

for session_index = 1: NUMBER_OF_SESSIONS

	%-----------RUN VOI---------------------
	VOI_session=session_index;
    %addpath
    VOI_name=strcat(strcat(ppi_dir,'/VOI_'),strcat(voiname_org,strcat('_session_',num2str(session_index))));
 
VOI_name=strcat(VOI_name,'.mat');

    VOI=load(VOI_name);
    %-----------END OF VOI ----------------

    disp('Running PPI')
data_path
    [TASK_NAME TASK_AND_CONTRAST]=get_ppi_task_matrix(fullfile(data_path,'SPM.mat'),contrast_number,NUMBER_OF_SESSIONS);

disp('got task stuff');
VOI.xY
TASK_AND_CONTRAST
ppi_name
TYPE_OF_ANALYSIS
	PPI= [ PPI spm_peb_ppi_brian(fullfile(data_path,'SPM.mat'), TYPE_OF_ANALYSIS ,VOI.xY, TASK_AND_CONTRAST, ppi_name, 0)];
disp('load SPM.mat');
    model=load(fullfile(data_path,'SPM.mat'));
	if (session_index == 1)
	  scans_per_session=length(cellstr(model.SPM.xY.P))/NUMBER_OF_SESSIONS;
    end


    disp('set PPI all');
	
end



% MODEL SPECIFICATION
%=====================================================================
clear jobs


%to be used in inference portion below
tcon_pos=[];
	
			
for session_index = 1: NUMBER_OF_SESSIONS


% High-pass filter
%---------------------------------------------------------------------

	f=cellstr(model.SPM.xY.P);
	jobs{1}.stats{1}.fmri_spec.sess(session_index).scans = f( ((session_index-1) * scans_per_session +1 ) : (session_index * scans_per_session)   )  %only input appropriate session


	jobs{1}.stats{1}.fmri_spec.sess(session_index).regress(1).name = 'PPI-interaction';
	jobs{1}.stats{1}.fmri_spec.sess(session_index).regress(1).val  = PPI(session_index).ppi;

	jobs{1}.stats{1}.fmri_spec.sess(session_index).regress(2).name = 'Signal (BOLD)';
	jobs{1}.stats{1}.fmri_spec.sess(session_index).regress(2).val  = PPI(session_index).Y;

	jobs{1}.stats{1}.fmri_spec.sess(session_index).regress(3).name = 'Task';
	jobs{1}.stats{1}.fmri_spec.sess(session_index).regress(3).val  = PPI(session_index).P;

	jobs{1}.stats{1}.fmri_spec.sess(session_index).hpf = 128;

	regressors=model.SPM.Sess(session_index).C.C;
	[r c ] = size(regressors);

	for i = 1 : c 
		jobs{1}.stats{1}.fmri_spec.sess(session_index).regress(3+i).name = strcat('Extra Regressor ',num2str(i));
		jobs{1}.stats{1}.fmri_spec.sess(session_index).regress(3+i).val  = regressors(:,i);		
	end

tcon_pos = [ tcon_pos 1 zeros(1,c+2) ];

				 
end




disp('done session PPIs')
% Directory
%---------------------------------------------------------------------
jobs{1}.stats{1}.fmri_spec.dir = cellstr(fullfile(ppi_dir));


% Timing
%---------------------------------------------------------------------
jobs{1}.stats{1}.fmri_spec.timing.units = 'scans';
jobs{1}.stats{1}.fmri_spec.timing.RT = model.SPM.xY.RT;


% MODEL ESTIMATION
%=====================================================================
jobs{1}.stats{2}.fmri_est.spmmat = cellstr(fullfile(ppi_dir,'SPM.mat'));


spm_jobman('run',jobs);




% INFERENCE & RESULTS
%=====================================================================
clear jobs

if (NUMBER_OF_SESSIONS == 2)
    tcon_dif=tcon_pos(1:length(tcon_pos)/NUMBER_OF_SESSIONS); %take first session
end


tcon_pos = [tcon_pos zeros(1,NUMBER_OF_SESSIONS) ] ;
jobs{1}.stats{1}.con.spmmat = cellstr(fullfile(ppi_dir,'SPM.mat'));
jobs{1}.stats{1}.con.consess{1}.tcon.name = 'PPI-Interaction-Positive';
jobs{1}.stats{1}.con.consess{1}.tcon.convec = tcon_pos;
spm_jobman('run',jobs);

clear jobs
tcon_neg = tcon_pos * -1;
jobs{1}.stats{1}.con.spmmat = cellstr(fullfile(ppi_dir,'SPM.mat'));
jobs{1}.stats{1}.con.consess{1}.tcon.name = 'PPI-Interaction-Negative';
jobs{1}.stats{1}.con.consess{1}.tcon.convec = tcon_neg;
spm_jobman('run',jobs);



if (NUMBER_OF_SESSIONS == 2)
tcon_dif=[ -1*tcon_dif tcon_dif 0 0 ];
jobs{1}.stats{1}.con.spmmat = cellstr(fullfile(ppi_dir,'SPM.mat'));
jobs{1}.stats{1}.con.consess{1}.tcon.name = 'PPI-Interaction-Positive : (T2-T1)';
jobs{1}.stats{1}.con.consess{1}.tcon.convec = tcon_dif;
spm_jobman('run',jobs);

end









