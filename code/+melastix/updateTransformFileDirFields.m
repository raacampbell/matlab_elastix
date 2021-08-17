function updateTransformFileDirFields(tDir)
% Ensure that the paths in the transform files located in tDir are pointing to that directory
%
% function melastix.updateTransformFileDirFields(tDir)
%
%
% Purpose
% If a directory containing an elastix registration is moved, the paths in the transform 
% files will be wrong. So if there are multiple tranforms, running transformix will fail. 
% This function corrects this, changing the path so it matches the directory the file 
% is in. 
%
%
% Inputs [optional]
% tDir - path to elastix registration dir
%
%
% Outputs
% None
%
%
% Rob Campbell - SWC 2021



if ~isfolder(tDir)
    fprintf('melastix.%s -- %s is not a directory\n',mfilename,tDir)
    return
end



% Find transform parameter files
d = dir(fullfile(tDir,'TransformParameters.*.txt'));

if isempty(d)
    fprintf('melastix.%s -- finds no TransformParameters files in directory %s\n',mfilename,tDir)
    return
end



for ii=1:length(d)
    % Loop through all files modifying the InitialTransformParametersFileName field if needed
    replace(d(ii).name,tDir);
end



function replace(transformFname,tDir)

    % This function matches and modifies the line that looks like:
    %(InitialTransformParametersFileName "/registration_BAK/reg_01__2021_08_16_a/sample2ARA/TransformParameters.0.txt")

    % Read the file
    transformFname = fullfile(tDir,transformFname);
    fContents = fileread(transformFname);

    tok=regexp(fContents,' *InitialTransformParametersFileName "(.*?)"','tokens');

    if isempty(tok)
        return
    end
    tok = tok{1}{1};

    % If the following matches this Transform file was the first in the chain
    if strmatch(tok,'NoInitialTransform')
        return
    end

    % If we are here we have to make a transform parameter file path
    [~,fname,ext]=fileparts(tok);
    newFname = fullfile(tDir,[fname,ext]);
    newLineInFile = sprintf('InitialTransformParametersFileName "%s"',newFname);
    NEW=regexprep(fContents,'InitialTransformParametersFileName ".*?"',newLineInFile);


    % If we are here then we should replace the contents of the the transform file
    fid = fopen(transformFname,'w');
    fprintf(fid,NEW);
    fclose(fid);
