function varargout=transformix(movingImage,parameters)
% transformix image registration and warping wrapper
%
% function varargout=transformix(movingImage,parameters) 
%
% Purpose
% Wrapper for transformix. Applies a transform calculated by elastix to 
% the matrix "movingImage." The transformix binary writes the transformed 
% image to an MHD file then reads that file and returns it as a MATLAB
% matrix. 
%
%
% Inputs
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
%                 NOTE the elastix automatically produces the transformed image, so this
%                 mode of operation for transformix.m is unlikely to be needed often.
%
% * When called with TWO input arguments:
%    movingImage - a) A 2D or 3D matrix corresponding to a 2D image or a 3D volume.  
%                     This is the image that you want to align.
%                  b) If empty, transformix returns all the warped control points. 
%    parameters - a) output structure from elastix.m
%                 b) path to a parameter text file produced by elastix. Will work only
%                    if a single parameter file is all that is needed. 
%
%  The MHD files and other data are written to a temporary directory that is 
%  cleaned up on exit. This mode allows the user to delete the data from their elastix 
%  run and freely transform the moving image according to transform parameters they
%  have already calculated. 
%
% Note that the parameters argument is *NOT* the same as the parameters provided to 
% elastix (the YAML file). Instead, it is the output of the elastix command that 
% describes the calculated transformation between the fixed image and the moving image.
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
%
%


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

%Handle case where the user supplies a path to a directory
if nargin==1 
    if isstr(movingImage)
        if ~exist(movingImage,'dir')
            error('Can not find directory %s',movingImage)
        end

        %Find moving images
        outputDir = movingImage;
        movingFname = dir([outputDir,filesep,'*_moving.mhd']);
        if isempty(movingImage)
            error('No moving images exist in directory %s',outputDir)
        end
        if length(movingFname)>1
            fprintf('Found %d moving files in directory. Choosing just the first one: %s\n',...
                movingFname(1).name)
        end
        movingFname=movingFname(1).name;

        %Find transform parameters
        params = dir([outputDir,filesep,'TransformParameters*.txt']);
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




%Handle case 2, where the user supplies a matrix and a parameters structure from an elastix run.
%This mode allows the user to have deleted their elastix data and just keep the parameters.
if nargin==2
    outputDir=sprintf('/tmp/transformix_%s_%d', datestr(now,'yymmddHHMMSS'), round(rand*1E8)); 
    if ~exist(outputDir)
        if ~mkdir(outputDir)
            error('Can''t make data directory %s',outputDir)
        end
    else
        error('directory %s already exists. odd. Please check what is going on',outputDir)
    end


    %Write the matrix to the temporary directory
    if ~isempty(movingImage)
        movingFname=[outputDir,filesep,'tmp_moving'];
        mhd_write(movingImage,movingFname);
        CMD = sprintf('transformix -in %s.mhd ',movingFname);
    else
        CMD = 'transformix ';
    end
    CMD = sprintf('%s-out %s ',CMD,outputDir);

    if isstruct(parameters)
        %Generate error the image dimensions are different between the parameters and the supplied matrix
        if parameters.TransformParameters{end}.FixedImageDimension ~= ndims(movingImage)
            error('Transform Parameters are from an image with %d dimensions but movingImage has %d dimensions',...
                parameters.TransformParameters{end}.FixedImageDimension, ndims(movingImage))
        end

        %Write all the tranform parameters (transformix is fed only the final one but this calls the previous one, and so on)
        for ii=1:length(parameters.TransformParameters)        
            transParam=parameters.TransformParameters{ii};
            transParamsFname{ii} = sprintf('%s%stmp_params_%d.txt',outputDir,filesep,ii);
            if ii>1
                transParam.InitialTransformParametersFileName=transParamsFname{ii-1};
            end
            elastix_paramStruct2txt(transParamsFname{ii},transParam);
        end

        %Build command
        CMD=sprintf('%s-tp %s ',CMD,transParamsFname{end});

    elseif isstr(parameters)

        copyfile(parameters,outputDir)        
        CMD=sprintf('%s-tp %s ',CMD,[outputDir,filesep,parameters]);

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
    if status
        fprintf('\n\t*** Transform Failed! ***\n%s\n',result)
    else
        disp(result)
    end

else %Things worked! So let's return the transformed image to the user. 
    disp(result)
    if ~isempty(movingImage)
        d=dir([outputDir,filesep,'result.mhd']); 
    else
        d=dir([outputDir,filesep,'deformationField.mhd']); 
    end
    registered=mhd_read([outputDir,filesep,d.name]);
    transformixLog=readWholeTextFile([outputDir,filesep,'transformix.log']);
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


