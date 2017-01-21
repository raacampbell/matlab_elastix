function varargout=transformix(movingImage,parameters,verbose)
% transformix image registration and warping wrapper
%
% function [registeredImage,log] = transformix(movingImage,parameters) 
%
% Purpose
% Wrapper for transformix. Applies a transform calculated by elastix to 
% the matrix "movingImage." The transformix binary writes the transformed 
% image to an MHD file then reads that file and returns it as a MATLAB
% matrix. 
%
%
% Inputs
% * When called with TWO input arguments:
%    movingImage - a) A 2D or 3D matrix corresponding to a 2D image or a 3D volume.  
%                     This is the image that you want to align.
%                  b) If empty, transformix returns all the warped control points. 
%    parameters - a) [struct] output structure from elastix.m
%                 b) [string] absolute or relative paths to an elastix output directory
%                    containing the transform parameter (coefs) files produced by elastix.
%                 c) [string or cell array] absolute or relative path to a transform 
%                    parameter text file produced by elastix. Will work only if a single 
%                    parameter file is all that is needed. In cases where you want to 
%                    chain transforms, supply a cell array of relative paths ordered 
%                    from the last transform on the list to the first (see examples, below).
%   verbose - [optional, 0 by default] if 1, some debugging information is printed.
%
% * When called with ONE input argument
%    movingImage - is a path to the output directory created by elastix. transformix
%                 will apply the last parameter structure present in that directory to a
%                 single moving image present in that directory. These are distinguished by
%                 filename, as elastix.m names the moving files in particular way. 
%                 This argument is useful as it allows you to simply run transformix
%                 immediately after elastix. This minimises IO compared to two argument mode.
%                 e.g. 
%                 out = elastix(imM,imF);
%                 corrected = transformix(out.outputDir;)
%                 NOTE the elastix command automatically produces the transformed image, so this
%                 mode of operation for transformix.m is unlikely to be needed often.
%
% * Transforming points
%  To transform sparse points, movingImage should be an n-by-2 or n-by-3 array
%
%
% Outputs
% registeredImage - the registred image or image volume
% log - the transformix log text.
%
%
%
% Implementation details
%  The MHD files and other data are written to a temporary directory that is 
%  cleaned up on exit. This allows the user to delete the data from their elastix 
%  run and transform the moving image according to transform parameters they
%  have already calculated as needed. This saves disk space at the expense of 
%  computation time. 
%
% Note that the parameters argument is *NOT* the same as the parameters provided to 
% elastix (the YAML file). Instead, it is the output of the elastix command that 
% describes the calculated transformation between the fixed image and the moving image.
%
%
% Examples
% reg=transformix(imageToTransform,paramStructure);
%
% reg=transformix(imageToTransform,'/path/to/elastixDir');
%
% reg=transformix(imageToTransform,'/path/to/TransformParameters.0.txt');
%
% params = {'/path/to/TransformParameters.1.txt', '/path/to/TransformParameters.0.txt'};
% reg=transformix(imageToTransform,params);
%
%
%
% Rob Campbell - Basel 2015
%
%
% Notes: 
% 1. You will need to download the elastix binaries (or compile the source)
% from: http://elastix.isi.uu.nl/ There are versions for all
% platforms. 
% 2. Not extensively tested on Windows. 
% 3. Read the elastix website and the default YAML to
% learn more about the parameters that can be modified. 
%
%
% Dependencies
% - elastix and transformix binaries in path
% - image processing toolbox (to run examples)



%Confirm that the transformix binary is present
[s,transformix_version] = system('transformix --version');
r=regexp(transformix_version,'version');
if isempty(r)
    fprintf('Unable to find transformix binary in system path. Quitting\n')
    return
end

if nargin==0
    movingImage=pwd;
end

if nargin<3
    verbose=0;
end

%Handle case where the user supplies only a path to a directory
if nargin==1 
    if isstr(movingImage)
        if ~exist(movingImage,'dir')
            error('Can not find directory %s',movingImage)
        end

        %Find moving images
        outputDir = movingImage;
        movingFname = dir(fullfile(outputDir,'*_moving.mhd'));
        if isempty(movingImage)
            error('No moving images exist in directory %s',outputDir)
        end
        if length(movingFname)>1
            fprintf('Found %d moving files in directory. Choosing just the first one: %s\n',...
                movingFname(1).name)
        end
        movingFname=movingFname(1).name;

        %Find transform parameters
        params = dir(fullfile(outputDir,'TransformParameters*.txt'));
        if isempty(params)
            error('No transform parameters found in directory %s',outputDir)
        end
        paramFname = params(end).name; %Will apply just the last, final, set of parameters. 

        %Build command
        CMD=sprintf('transformix -in %s%s%s -out %s -tp %s%s%s',...
            outputDir,filesep,movingFname,...
            outputDir,...
            outputDir,filesep,paramFname);

    else
        error('Expected movingImage to be a string corresponding to a directory')
    end
        
end




%Handle case, where the user supplies a matrix and a parameters structure from an elastix run.
%This mode allows the user to have deleted their elastix data and just keep the parameters.
if nargin>1

    %error check: confirm parameter files exist
    if ischar(parameters)
        if isdir(parameters)
            if verbose
                fprintf('%s using parameters in directory %s\n',mfilename,parameters)
            end
            paramDir = parameters;
            clear parameters
            parameterFiles = dir(fullfile(paramDir,'TransformParameters*.txt'));
            if isempty(parameterFiles)
                print('Can not find parameter any files in %s\n', parameters)
                return
            end

            parameterFiles = flipud(parameterFiles); %must go from first to last

            %create full paths
            for ii=1:length(parameterFiles)
                parameters{ii} = fullfile(paramDir,parameterFiles(ii).name);
            end

            if verbose
                fprintf('Found parameter files:\n')
                cellfun(@(x) fprintf('%s\n',x), parameters)
                fprintf('\n')
            end


        elseif ~exist(parameters,'file')
            print('Can not find parameter file %s\n', parameters)
            return
        end
    end

    if iscell(parameters)
        for ii = 1:length(parameters)
            if ~exist(parameters{ii},'file')
                fprintf('Can not find %s\n', parameters{ii})
                return  
            end
        end
    end

    %MATLAB should figure out the correct temporary directory on Windows
    outputDir=fullfile(tempdir,sprintf('transformix_%s_%d', datestr(now,'yymmddHHMMSS'), round(rand*1E8))); 

    if ~exist(outputDir,'dir')
        if ~mkdir(outputDir)
            error('Can''t make data directory %s',outputDir)
        end
    else
        error('directory %s already exists. odd. Please check what is going on',outputDir)
    end


    %Write the movingImage matrix to the temporary directory
    if isempty(movingImage)
        CMD = 'transformix ';
    elseif size(movingImage,2)>3 %It's an image
        movingFname=fullfile(outputDir,'tmp_moving');
        mhd_write(movingImage,movingFname);
        CMD = sprintf('transformix -in %s.mhd ',movingFname);
    elseif size(movingImage,2)==2 | size(movingImage,2)==3 %It's sparse points
        movingFname=fullfile(outputDir,'tmp_moving.txt');
        writePointsFile(movingFname,movingImage)
        CMD = sprintf('transformix -def %s ',movingFname);
    else
        error('Unknown format for movingImage')
    end
    CMD = sprintf('%s-out %s ',CMD,outputDir);

    if isstruct(parameters)
        %Generate an error if the image dimensions are different between the parameters and the supplied matrix
        if size(movingImage,2)>3 & parameters.TransformParameters{end}.FixedImageDimension ~= ndims(movingImage)
            error('Transform Parameters are from an image with %d dimensions but movingImage has %d dimensions',...
                parameters.TransformParameters{end}.FixedImageDimension, ndims(movingImage))
        end

        %Write all the tranform parameters (transformix is fed only the final one but this calls the previous one, and so on)
        for ii=1:length(parameters.TransformParameters)        
            transParam=parameters.TransformParameters{ii};
            transParamsFname{ii} = fullfile(outputDir,sprintf('tmp_params_%d.txt',ii));
            if ii>1
                transParam.InitialTransformParametersFileName=transParamsFname{ii-1};
            end
            elastix_paramStruct2txt(transParamsFname{ii},transParam);
        end

        %Build command
        CMD=[CMD, '-tp ', transParamsFname{end} ,' '];

    elseif ischar(parameters)
        if verbose
            fprintf('Copying %s to %s\n',parameters,outputDir)
        end
        copyfile(parameters,outputDir) %We've already tested if the parameters file exists   
        [~,pName,pExtension] = fileparts(parameters);
        CMD=[CMD, '-tp ', fullfile(outputDir,[pName,pExtension]) ,' '];

    elseif iscell(parameters)
        %copy parameter files
        copiedLocations = {}; %Keep track of the locations to which the files are stored
        for ii=1:length(parameters)
            if verbose
                fprintf('Copying %s to %s\n',parameters{ii},outputDir)
            end
            copyfile(parameters{ii},outputDir)
            [fPath,pName,pExtension] = fileparts(parameters{ii});
            copiedLocations{ii} = fullfile(outputDir,[pName,pExtension]);
        end
        if verbose
            fprintf('\n')
        end

        %Modify the parameter files so that they chain together correctly: the files should point to the new copied locations. 
        for ii=1:length(parameters)-1
            changeParameterInElastixFile(copiedLocations{ii},'InitialTransformParametersFileName',copiedLocations{ii+1},verbose)
        end

        %Add the first parameter file to the command string 
        CMD=sprintf('%s -tp %s ',CMD,copiedLocations{1});

    else
        error('Parameters is of unknown type')
    end

    if isempty(movingImage)
        CMD = [CMD,'-def all'];
    end
        
end




%----------------------------------------------------------------------
% *** Conduct the transformation ***
[status,result]=system(CMD);
fprintf('Running: %s\n',CMD)

if status %Things failed. Oh dear. 
    fprintf('\n\t*** Transform Failed! ***\n%s\n',result)
    registered=[];
    transformixLog=[];
else %Things worked! So let's return the transformed image to the user. 
    disp(result)
    if size(movingImage,2)>3 & ~isempty(movingImage)
        d=dir(fullfile(outputDir,'result.mhd')); 
    elseif size(movingImage,2)<=3 & ~isempty(movingImage)
        d=dir(fullfile(outputDir,'outputpoints.txt')); 
    else
        d=dir(fullfile(outputDir,'deformationField.mhd')); 
    end

    if isempty(d)
        error('Failed to find transformed result. Retaining output directory for debugging purposes.')
    end

    if size(movingImage,2)>3 %It's an image
        registered=mhd_read(fullfile(outputDir,d.name));
    else %it's a points file
        registered=readTransformedPointsFile(fullfile(outputDir,d.name));
    end
        
    transformixLog=readWholeTextFile(fullfile(outputDir,'transformix.log'));
end


%Delete temporary dir (only happens if the user used two output args)
if nargin==2
    fprintf('Deleting temporary directory %s\n',outputDir)
    rmdir(outputDir,'s')
end
%----------------------------------------------------------------------


if nargout>0
    varargout{1}=registered;
end

if nargout>1
    varargout{2}=transformixLog;
end


