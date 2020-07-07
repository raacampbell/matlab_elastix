function varargout=elastix(movingImage,fixedImage,outputDir,paramFile,varargin)
% elastix image registration and warping wrapper
%
% function varargout=elastix(movingImage,fixedImage,outputDir,paramFile)
%          varargout=elastix(movingImage,fixedImage,outputDir,paramFile,'PARAM1',val1,...)
% Purpose
% Wrapper for elastix image registration package. This function calls the elastix
% binary (needs to be in the system path) to conduct the registration and produce
% the transformation coefficients. These are saved to disk and, optionally, 
% returned as a variable. Transformed images are returned.
%
%
% Inputs [required]
% movingImage - A 2D or 3D matrix corresponding to a 2D image or a 3D volume. 
%               This is the image that you want to align.
%
% fixedImage -  A 2D or 3D matrix corresponding to a 2D image or a 3D volume. 
%               Must have the same number of dimensions as movingImage.
%               This is the target of the alignment. i.e. the image that you want
%               movingImage to match. 
%
% outputDir -   If empty, a temporary directory with a unique name is created 
%               and deleted once the analysis is complete. If a *valid path* is entered
%               then the directory is not deleted. If a directory is defined and it 
%               does not exist then a temporary one is created. The directory is *never deleted* if no
%               outputs are requested.
%
% paramFile - a) A string defining the name of the YAML file that contains the registration 
%             parameters. This is converted to an elastix parameter file. Leave empty to 
%             use the default file supplied with this package (elastix_default.yml)
%             Must end with ".yml" (Can be -1 to ignore this: see example below).
%             b) An elastix parameter file name (relative or full path) or a cell array 
%               of elastix parameter file names. If a cell array, these are applied in 
%               order. Names must end with ".txt"
%
%
% Inputs [optional]
% paramstruct - structure containing parameter values for the registration. This is used 
%          to modify specific parameters which may already have been defined by the .yml 
%          (paramFile). paramstruct can be a cell array of length>1, in which case 
%          these structures are treated as a request for multiple sequential registration 
%          operations. The possible values for fields in the the structure can be found in 
%          elastix_default.yml 
%          *paramstruct is ignored if paramFile is an elastix parameter file.*
%
% threads - How many threads to run the registration on. by default all available cores 
%           will be used.
% t0      - Relative or absolute path(s) (string or cell array of strings) to files 
%           defining the initial transform. If transforms are to be chained, list then 
%           in reverse order (e.g. bspline then affine).
%
%
%
% Outputs
% registered - the final registered image
% stats - all stats from the registration, including any intermediate images produced 
%         during the registration.
%
%
%
% Examples
% elastix('version')   %prints the version of elastix on your system and exits
% elastix('help')      %prints the elastix binary's help and exits
% 
% Basic:
% elastix(movImage,refImage,'regDirName',{'./01_affine.txt','./02_bspline.txt}) 
% elastix(movImage,refImage,[],'elastix_settings.yml')
% elastix(movImage,refImage,[],'elastix_settings.yml', 'paramstruct', modifierStruct)
%
% Advanced - read two parameter files from disk. Modify one and feed in as a 
%            a structre:
%  PP{1}=elastix_parameter_read('01_affine.txt');
%  PP{2}=elastix_parameter_read('02_bspline.txt');
%  PP{2}.NumberOfResolutions=4;
%  elastix(S,T,'mlabtest',-1,'paramstruct',PP);
%  In the line above, the "-1" forces elastix to ignore the default YML structure.
%  *This is safest* as the feature is only partially complete!
%
% Notes:
% 1. You will need to download the elastix binaries (or compile the source)
% from: http://elastix.isi.uu.nl/ There are versions for all platforms. 
% 2. Not extensively tested on Windows. 
% 3. Read the elastix website and elastix_parameter_write.m to
% learn more about the parameters that can be modified. 
%
%
% Rob Campbell - Basel 2015
%
% Dependencies
% - elastix and transformix binaries in path
% - image processing toolbox (to run examples)


%----------------------------------------------------------------------
% *** Handle default options ***

%Confirm that the elastix binary is present and can run
[~,elastix_version] = system('elastix --version');

r=regexp(elastix_version,'error', 'once');
if ~isempty(r)
    fprintf('\n*** ERROR starting elastix binary:\n%s\n',elastix_version)
    return
end

r=regexp(elastix_version,'version', 'once');
if isempty(r)
    fprintf('\n*** ERROR: Unable to find elastix binary in system path. Quitting ***\n')
    return
end

if nargin==0
    help(mfilename)
    return
end

%If the user supplies one input argument only and this is is a string then
%we assume it's a request for the help or version so we run it 
if nargin==1 && ischar(movingImage)
    if regexp(movingImage,'^\w')
        [~,msg]=system(['elastix --',movingImage]);
    end
    fprintf(msg)
    if nargout>0
        varargout{1}=chomp(msg);
    end
    return
end

if ndims(movingImage) ~= ndims(fixedImage)
    fprintf('movingImage and fixedImage must have the same number of dimensions\n')
    return
end

% Make directory into which we will write the image files and associated registration files
if nargin<3 || isempty(outputDir) 
    outputDir=fullfile(tempdir,sprintf('elastixTMP_%s_%d', datestr(now,'yymmddHHMMSS'), round(rand*1E8)));
    deleteDirOnCompletion=1;
else
    deleteDirOnCompletion=0;
end

if strcmp(outputDir(end),filesep) %Chop off any trailing fileseps 
    outputDir(end)=[];
end

if ~exist(outputDir,'dir') || isempty(outputDir)
    if ~mkdir(outputDir)
        error('Can''t make data directory %s',outputDir)
    end
end

if nargin<4
    paramFile=[];
end


if isempty(paramFile)
    defaultParam = 'elastix_default.yml';
    fprintf('Using default parameter file %s\n',defaultParam)
    paramFile = defaultParam;
end


%Handle parameter/value pairs
p = inputParser;
p.addParameter('threads', [], @isnumeric)
p.addParameter('t0', [])
p.addParameter('verbose', 0)
p.addParameter('paramstruct', [], @(x) isstruct(x) || iscell(x))

parse(p,varargin{:})
threads = p.Results.threads;
t0 = p.Results.t0;
paramstruct = p.Results.paramstruct;
verbose = p.Results.verbose;

% Convert paramstruct to cell array if needed
if ~isempty(paramstruct)
    if isstruct(paramstruct) && length(paramstruct)==1
        paramstruct = {paramstruct};
    elseif ~iscell(paramstruct)
        fprintf('\nelastix.m -- paramstruct should be a cell array. BAILING OUT!\n')
        return
    end
end


%error check: confirm initial parameter files exist
if ~isempty(t0)
    if ischar(t0) 
       t0 = {t0}; %just to make later code neater
    end

    for ii = 1:length(t0)
        if ~exist(t0{ii},'file')
            print('Can not find initial transform %s\n', t0{ii})
            return
        end
    end
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
%modify settings from YAML with paramstruct
if ~isempty(paramstruct) && (ischar(paramFile) && endsWith(paramFile,'.yml')) || (isnumeric(paramFile) && paramFile==-1) 
    for ii=1:length(paramstruct)
        paramFname{ii}=sprintf('%s_parameters_%d.txt',dirName,ii);
        paramFname{ii}=fullfile(outputDir,paramFname{ii});
        elastix_parameter_write(paramFname{ii},paramFile,paramstruct{ii})
    end

elseif ischar(paramFile) && endsWith(paramFile,'.yml') && isempty(paramstruct) %read YAML with no modifications
    paramFname{1} = fullfile(outputDir,sprintf('%s_parameters_%d.txt',dirName,1));
    elastix_parameter_write(paramFname{1},paramFile)

elseif (ischar(paramFile) && endsWith(paramFile,'.txt')) %we have an elastix parameter file
    if ~strcmp(outputDir,'.')
        copyfile(paramFname,outputDir)
        paramFname{1} = fullfile(outputDir,paramFname);
    end

elseif iscell(paramFile) %we have a cell array of elastix parameter files
    paramFname = paramFile;
     if ~strcmp(outputDir,'.') 
        for ii=1:length(paramFname)
            copyfile(paramFname{ii},outputDir)
            %So paramFname is now:
            [~,f,e] = fileparts(paramFname{ii});
            paramFname{ii} = fullfile(outputDir,[f,e]);
        end
    end

else
    error('paramFile format in file not understood')
end


%If the user asked for an initial transform, collate the transform files, copy them to the 
%transform directory, and ensure they are linked.
if ~isempty(t0)
    copiedLocations = {}; %Keep track of the locations to which the files are stored
    for ii=1:length(t0)
        [~,pName,pExtension] = fileparts(t0{ii});
        copiedLocations{ii} = fullfile(outputDir,['init_',pName,pExtension]);
        if verbose
            fprintf('Copying %s to %s\n',t0{ii},copiedLocations{ii})
        end
        copyfile(t0{ii},copiedLocations{ii})
    end

    %Modify the parameter files so that they chain together correctly
    for ii=1:length(t0)-1
        changeParameterInElastixFile(copiedLocations{ii},'InitialTransformParametersFileName',copiedLocations{ii+1},verbose)
    end

    %Add the first parameter file to the command string 
    initCMD = sprintf(' -t0 %s ',copiedLocations{1});
else
    initCMD = '';
end


%Build the the appropriate command
CMD=sprintf('elastix -f %s.mhd -m %s.mhd -out %s ',...
            fullfile(outputDir,targetFname),...
            fullfile(outputDir,movingFname),...
            outputDir);
CMD = [CMD,initCMD];


if ~isempty(threads)
    CMD = sprintf('%s -threads %d',CMD,threads);
end


%Loop through, adding each parameter file in turn to the string
for ii=1:length(paramFname) 
    CMD=[CMD,sprintf('-p %s ', paramFname{ii})];
end

%store a copy of the command to the directory
cmdFid = fopen(fullfile(outputDir,'CMD'),'w');
fprintf(cmdFid,'%s\n',CMD);
fclose(cmdFid);





% Run the command and report back if it failed
fprintf('Running: %s\n',CMD)

[status,result]=system(CMD);

if status %Things failed. Oh dear. 
    if status
        fprintf('\n\t*** Transform Failed! ***\n%s\n',result)
        fprintf('\tYou may want to check out the Elastix FAQ: https://github.com/SuperElastix/elastix/wiki/FAQ\n')
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
        d=dir(fullfile(outputDir,'TransformParameters.*.txt'));
        for ii=1:length(d)
            out.TransformParameters{ii}=elastix_parameter_read([outputDir,filesep,d(ii).name]);
            out.TransformParametersFname{ii}=[outputDir,filesep,d(ii).name];
        end

        %return the transformed images
        d=dir(fullfile(outputDir,'result*.*'));
        d(cellfun(@(x) endsWith(x,'.raw'),{d.name}))=[]; % remove .raw files
        if isempty(d)
            fprintf('WARNING: could find no transformed result images in %s\n',outputDir);
            registered=[];
        else
            for ii=1:length(d)
                fullPath = [outputDir,filesep,d(ii).name];
                out.transformedImages{ii}=getImage(fullPath);
            end
            registered=out.transformedImages{end};
        end

        out.log=readWholeTextFile([outputDir,filesep,'elastix.log']);
        out.outputDir=outputDir; %may be a relative path
        out.currentDir=pwd;
        out.movingFname=movingFname;
        out.targetFname=targetFname;
    end

    if nargout>0

        %return the final transformed image
        d=dir(fullfile(outputDir,'result*.*'));
        d(cellfun(@(x) endsWith(x,'.raw'),{d.name}))=[]; % remove .raw files
        if isempty(d)
            fprintf('WARNING: could find no transformed result images in %s\n',outputDir);
            registered=[];
        else
            fullPath = [outputDir,filesep,d(end).name];
            registered = getImage(fullPath);
        end
    end %if nargout

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




function im = getImage(fname)
    % Load images of the correct type
    [~,~,ext]=fileparts(fname);
    if strcmp(ext,'.mhd')
        im=mhd_read(fname);
    elseif strcmp(ext,'.tif') || strcmp(ext,'.tiff') 
        im = load3Dtiff(fname);
    end
