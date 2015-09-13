function varargout=elastix(movingImage,fixedImage,outputDir,paramFile,paramStruct)
% elastix image registration and warping wrapper
%
% function varargout=elastix(movingImage,fixedImage,outputDir,paramFile,paramStruct)
%
% Purpose
% Wrapper for elastix image registration package. This function calls the elastix
% binary (needs to be in the system path) to conduct the registration and produce
% the transformation coefficients. These are saved to disk and, optionally, 
% returned as a variable. Transformed images are returned.
%
%
% Examples
% elastix('version')   %prints the version of elastix on your system and exits
% elastix('help')      %prints the elastix help and exits
%
%
% Inputs
% movingImage - A 2D or 3D matrix corresponding to a 2D image or a 3D volume. 
%               This is the image that you want to align.
%
% fixedImage -  A 2D or 3D matrix corresponding to a 2D image or a 3D volume. 
%               Must have the same number of dimensions as movingImage.
%               This is the target of the alignment. i.e. the image that you want
%               movingImage to match. 
%
% outputDir -   If empty, a temporary directory with a unique name is created 
%               and deleted once the analysis is complete. If a valid path is entered
%               then the directory is not deleted. If a directory is defined and it 
%               does not exist then it is created. The directory is never deleted if no
%               outputs are requested.
%
% paramFile - a) A string defining the name of the YAML file that contains the registration 
%             parameters. This is converted to an elastix parameter file. Leave empty to 
%             use the default file supplied with this package (elastix_default.yml)
%             Must end with ".yml"
%             b) An elastix parameter file name (relative or full path) or a cell array 
%               of elastix parameter file names. If a cell array, these are applied in 
%               order. Names must end with ".txt"
%
% paramStruct - structure containing parameter values for the
%          registration. This is used to modify specific paramater which may 
%          already have been defined by the .yml (paramFile). paramStruct can have a 
%          length>1, in which case these structures are treated as a request for multiple
%          sequential registration operations. The identity of the transform type is 
%          defined here. The possible values for fields in the the structure can be found 
%          in elastix_default.yml paramStruct is ignored if paramFile is an elastix 
%          parameter file.
%
%
% 
% Outputs
% registered - the final registered image
% stats - all stats from the registration, including any intermediate images produced 
%         during the registration.
%
% Rob Campbell - Basel 2015
%
%
% Notes: 
% 1. You will need to download the elastix binaries (or compile the source)
% from: http://elastix.isi.uu.nl/ There are versions for all platforms. 
% 2. Not extensively tested on Windows. 
% 3. Read the elastix website and elastix_parameter_write.m to
% learn more about the parameters that can be modified. 
%
%
% Dependencies
% - elastix and transformix binaries in path
% - image processing toolbox (to run examples)


%----------------------------------------------------------------------
% *** Handle default options ***

%Confirm that the elastix binary is present
[s,elastix_version] = system('elastix --version');
r=regexp(elastix_version,'version');
if isempty(r)
    fprintf('Unable to find elastix binary in system path. Quitting\n')
    return
end

%If the user supplies one input argument only and this is is a string then
%we assume it's a request for the help or version so we run it 
if nargin==1 & isstr(movingImage)
    if regexp(movingImage,'^\w')
        [s,msg]=system(['elastix --',movingImage]);
    end
    fprintf(msg)
    return
end

if ndims(movingImage) ~= ndims(fixedImage)
    fprintf('movingImage and fixedImage must have the same number of dimensions\n')
    return
end

% Make directory into which we will write the image files and associated registration files
if nargin<3 | isempty(outputDir) 
    outputDir=sprintf('/tmp/elastixTMP_%s_%d', datestr(now,'yymmddHHMMSS'), round(rand*1E8));
    deleteDirOnCompletion=1;
else
    deleteDirOnCompletion=0;
end

if strcmp(outputDir(end),filesep) %Chop off any trailing fileseps 
    outputDir(end)=[];
end

if ~exist(outputDir)
    if ~mkdir(outputDir)
        error('Can''t make data directory %s',outputDir)
    end
end

if nargin<4
    paramFile=[];
end

if nargin<5
    paramStruct=[];
end



%----------------------------------------------------------------------
% *** Conduct the registration ***

if strcmp('.',outputDir)
    [~,dirName]=fileparts(pwd);
else
    [~,dirName]=fileparts(outputDir);
end


% Create and move the images
movingFname=[dirName,'_moving']; %TODO: so the file name contains the dir name? 
mhd_write(movingImage,movingFname);
if ~strcmp(outputDir,'.')
    if ~movefile([movingFname,'.*'],outputDir); error('Can''t move files'), end
end

%create fixedImage only if we're registering to an image. parameters
%may have been supplied instead
if isnumeric(fixedImage)
    targetFname=[dirName,'_target'];
    mhd_write(fixedImage,targetFname);
    if ~strcmp(outputDir,'.') %Don't copy if we're already in the directory
        if ~movefile([targetFname,'.*'],outputDir); error('Can''t move files'), end
    end
end


%Build the parameter file(s)
if isstr(paramFile) & strfind(paramFile,'.yml') & ~isempty(paramStruct) %modify settings from YAML with paramStruct
    for ii=1:length(paramStruct)
        paramFname{ii}=sprintf('%s_parameters_%d.txt',dirName,ii);
        elastix_parameter_write([outputDir,filesep,paramFname{ii}],paramFile,paramStruct(ii))
    end
elseif isstr(paramFile) & strfind(paramFile,'.yml') & isempty(paramStruct) %read YAML with no modifications
    paramFname{1}=sprintf('%s_parameters_%d.txt',dirName,1);
    elastix_parameter_write([outputDir,filesep,paramFname{1}],paramFile)
elseif (isstr(paramFile) & strfind(paramFile,'.txt')) %we have an elastix parameter file
    paramFname{1} = paramFile;
    if ~strcmp(outputDir,'.')
        copyfile(paramFname{1},outputDir)
    end
elseif iscell(paramFile) %we have a cell array of elastix parameter files
    paramFname = paramFile;
     if ~strcmp(outputDir,'.') 
        for ii=1:length(paramFname)
            copyfile(paramFname{ii},outputDir)
        end
    end
else
    error('paramFile format not understood')    
end




% Build the the appropriate command
CMD=sprintf('elastix -f %s%s%s.mhd -m %s%s%s.mhd -out %s ',...
            outputDir,filesep,targetFname,...
            outputDir,filesep,movingFname,...
            outputDir);
    
%Loop through, adding each parameter file in turn to the string
for ii=1:length(paramFname) 
    CMD=[CMD,sprintf('-p %s%s%s ', outputDir,filesep,paramFname{ii})];
end

%store a copy of the command to the directory
cmdFid = fopen([outputDir,filesep,'CMD'],'w');
fprintf(cmdFid,'%s\n',CMD);
fclose(cmdFid);





% Run the command and report back if it failed
[status,result]=system(CMD);

if status %Things failed. Oh dear. 
    if status
        fprintf('\n\t*** Transform Failed! ***\n%s\n',result)
    else
        disp(result)
    end
    registered=[];
    out.outputDir=outputDir;
    out.TransformParameters=nan;
    out.TransformParametersFname=nan;    

    if deleteDirOnCompletion
        fprintf('Keeping temporary directory %s for debugging purposes\n',outputDir)
    end


else %Things worked! So let's return stuff to the user 

    if nargout>1
        %Return the transform parameters
        d=dir([outputDir,filesep,'TransformParameters.*.txt']);
        for ii=1:length(d)
            out.TransformParameters{ii}=elastix_parameter_read([outputDir,filesep,d(ii).name]);
            out.TransformParametersFname{ii}=[outputDir,filesep,d(ii).name];
        end

        %return the transformed images
        d=dir([outputDir,filesep,'result*.mhd']);
        if isempty(d)
            fprintf('WARNING: could find no transformed result images\n');
        else
            for ii=1:length(d)
                out.transformedImages{ii}=mhd_read([outputDir,filesep,d(ii).name]);
            end
        end
        registered=out.transformedImages{end};

        out.log=readWholeTextFile([outputDir,filesep,'elastix.log']);
        out.outputDir=outputDir; %may be a relative path
        out.currentDir=pwd;
        out.movingFname=movingFname;
        out.targetFname=targetFname;

    elseif nargout==1      

        %return the final transformed image
        d=dir([outputDir,filesep,'result*.mhd']);
        if isempty(d)
            fprintf('WARNING: could find no transformed result images\n');
        else
            registered=mhd_read([outputDir,filesep,d(end).name]);
        end
    end

        

end



%Optionally return to the command line
if nargout>0
    varargout{1}=registered;
    if deleteDirOnCompletion
        fprintf('Deleting temporary directory %s\n',outputDir)
        rmdir(outputDir,'s')
    end
end

if nargout>1
    varargout{2}=out;
end
