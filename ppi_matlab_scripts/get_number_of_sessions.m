function N = get_number_of_sessions( spmmat )
%Get Number of Session used in first-level analysis for SPM.mat

SPM = load(spmmat);
N = length(SPM.SPM.Sess);
