function [ name, matrix ] = get_ppi_task_matrix( spmmat , contrast_number, Nsessions ) 

SPM=load(spmmat);
con=struct2cell(SPM.SPM.xCon);
con=con(:,:,contrast_number);
name=con(1);
contrast = SPM.SPM.xCon(contrast_number).c;
if (Nsessions>1) % there are added variables to model session
contrast = contrast(1: ( (length(contrast)-Nsessions)/Nsessions));
end
	
matrix= find(contrast);
matrix= [ matrix ones(length(matrix),1) contrast(matrix) ];