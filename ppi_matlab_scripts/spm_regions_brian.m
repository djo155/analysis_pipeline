function [Y,xY] = spm_regions(xSPM,SPM,xY)
% VOI time-series extraction of adjusted data (& local eigenimage analysis)
% FORMAT [Y xY] = spm_regions(xSPM,SPM,hReg,[xY]);
%
% xSPM   - structure containing specific SPM, distribution & filtering details
% SPM    - structure containing generic analysis details
% hReg   - Handle of results section XYZ registry (see spm_results_ui.m)
%
% Y      - first scaled eigenvariate of VOI {i.e. weighted mean}
% xY     - VOI structure
%       xY.xyz          - centre of VOI {mm}
%       xY.name         - name of VOI
%       xY.Ic           - contrast used to adjust data (0 - no adjustment)
%       xY.Sess         - session index
%       xY.def          - VOI definition
%       xY.spec         - VOI definition parameters
%       xY.str          - VOI description as a string
%       xY.XYZmm        - Co-ordinates of VOI voxels {mm}
%       xY.y            - [whitened and filtered] voxel-wise data
%       xY.u            - first eigenvariate {scaled - c.f. mean response}
%       xY.v            - first eigenimage
%       xY.s            - eigenvalues
%       xY.X0           - [whitened] confounds (including drift terms)
%
% Y and xY are also saved in VOI_*.mat in the SPM working directory
%
% (See spm_getSPM for details on the SPM & xSPM structures.)
%
%__________________________________________________________________________
%
% spm_regions extracts a representative time course from voxel data in
% terms of the first eigenvariate of the filtered and adjusted response in
% all suprathreshold voxels within a specified VOI centered on the current
% MIP cursor location.
%
% If temporal filtering has been specified, then the data will be filtered.
% Similarly for whitening. Adjustment is with respect to the null space of
% a selected contrast, or can be omitted.
%
% For a VOI of radius 0, the [adjusted] voxel time-series is returned, and
% scaled to have a 2-norm of 1. The actual [adjusted] voxel time series can
% be extracted from xY.y, and will be the same as the [adjusted] data 
% returned by the plotting routine (spm_graph.m) for the same contrast.
%__________________________________________________________________________
% Copyright (C) 1999-2011 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_regions.m 4185 2011-02-01 18:46:18Z guillaume $

%if nargin < 4, xY = []; end




if ~isfield(xY,'name')
    xY.name    = spm_input('name of region','!+1','s','VOI');
end

if ~isfield(xY,'Ic')
    q     = 0;
    Con   = {'<don''t adjust>'};
    for i = 1:length(SPM.xCon)
        if strcmp(SPM.xCon(i).STAT,'F')
            q(end + 1) = i;
            Con{end + 1} = SPM.xCon(i).name;
        end
    end
    i     = spm_input('adjust data for (select contrast)','!+1','m',Con);
    xY.Ic = q(i);
end

%-If fMRI data then ask user to select session
%--------------------------------------------------------------------------
if isfield(SPM,'Sess') && ~isfield(xY,'Sess')
    s       = length(SPM.Sess);
    if s > 1
        s   = spm_input('which session','!+1','n1',s,s);
    end
    xY.Sess = s;
end

%-Specify VOI
%--------------------------------------------------------------------------
%xY.M = xSPM.M;
%xY
%xSPM.XYZmm
[xY, xY.XYZmm, Q] = spm_ROI_brian(xY, xSPM.XYZmm);
%disp('done spm_ROI_brian');

%try, xY = rmfield(xY,'M'); end
%try, xY = rmfield(xY,'rej'); end

if isempty(xY.XYZmm)
    warning('Empty region.');
    Y = [];
    return;
end
%xY.spec.mat
%xY.XYZmm
%Q

%size(xSPM.XYZ)
%Q
%size(SPM.xY.VY)
%SPM.xY.VY(1).dim
XYZmm=spm_vol(xY.spec);
[R,C,P]  = ndgrid(1:XYZmm.dim(1),1:XYZmm.dim(2),1:XYZmm.dim(3));
RCP      = [R(:)';C(:)';P(:)'];
            clear R C P
            RCP(4,:) = 1;
           % size(XYZmm)
    XYZmm    = XYZmm.mat(1:3,:)*RCP;  
            Q2 = ones(1,size(XYZmm,2));
%disp('XYZ');
            xSPM.XYZ    = xY.spec.mat \ [XYZmm ; Q2];
%size(xSPM.XYZ)     
 %           disp('XYZ-Q')
  %          xSPM.XYZ(:,Q);
%-Extract required data from results files
%==========================================================================
%spm('Pointer','Watch')

%-Get raw data, whiten and filter 
%--------------------------------------------------------------------------
y        = spm_get_data(SPM.xY.VY,xSPM.XYZ(:,Q));
%disp('filter')
y        = spm_filter(SPM.xX.K,SPM.xX.W*y);

			%disp('done filter')

%-Computation
%==========================================================================

%-Remove null space of contrast
%--------------------------------------------------------------------------
if xY.Ic

    %-Parameter estimates: beta = xX.pKX*xX.K*y
    %----------------------------------------------------------------------
    beta  = spm_get_data(SPM.Vbeta,xSPM.XYZ(:,Q));

    %-subtract Y0 = XO*beta,  Y = Yc + Y0 + e
    %----------------------------------------------------------------------
    y     = y - spm_FcUtil('Y0',SPM.xCon(xY.Ic),SPM.xX.xKXs,beta);

end

%-Confounds
%--------------------------------------------------------------------------
xY.X0     = SPM.xX.xKXs.X(:,[SPM.xX.iB SPM.xX.iG]);

%-Extract session-specific rows from data and confounds
%--------------------------------------------------------------------------
try
    i     = SPM.Sess(xY.Sess).row;
    y     = y(i,:);
    xY.X0 = xY.X0(i,:);
end

% and add session-specific filter confounds
%--------------------------------------------------------------------------
try
    xY.X0 = [xY.X0 SPM.xX.K(xY.Sess).X0];
end
try
    xY.X0 = [xY.X0 SPM.xX.K(xY.Sess).KH]; % Compatibility check
end

%-Remove null space of X0
%--------------------------------------------------------------------------
xY.X0     = xY.X0(:,any(xY.X0));

%-Compute regional response in terms of first eigenvariate
%--------------------------------------------------------------------------
[m n]   = size(y);
if m > n
    [v s v] = svd(y'*y);
    s       = diag(s);
    v       = v(:,1);
    u       = y*v/sqrt(s(1));
else
    [u s u] = svd(y*y');
    s       = diag(s);
    u       = u(:,1);
    v       = y'*u/sqrt(s(1));
end
d       = sign(sum(v));
u       = u*d;
v       = v*d;
Y       = u*sqrt(s(1)/n);

%-Set in structure
%--------------------------------------------------------------------------
xY.y    = y;
xY.u    = Y;
xY.v    = v;
xY.s    = s;

%-Save
%==========================================================================
str = ['VOI_' xY.name '.mat'];
if isfield(xY,'Sess') && isfield(SPM,'Sess')
    str = sprintf('VOI_%s_%i.mat',xY.name,xY.Sess);
end
if spm_check_version('matlab','7') >= 0
    save(fullfile(SPM.swd,str),'-V6','Y','xY')
else
    save(fullfile(SPM.swd,str),'Y','xY')
end

fprintf('   VOI saved as %s\n',spm_str_manip(fullfile(SPM.swd,str),'k55'));

%-Reset title
%--------------------------------------------------------------------------
%spm('Pointer','Arrow')
