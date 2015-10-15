function stats=invertElastixTransform(transformDir,outputDir)
%
% Inverts an already-calculated elastix transform 
%
% invertedTransform=invertElastixTransform(transformDir,outputDir)
%
% 
% Purpose
% Uses elastix to invert an already-calculated transform 
%
% 
% Inputs
% transformDir - the directory containing the elastix transform results. 
% outputDir  - [optional] Directory in which to conduct the registration. A temporary directory
%              is created if none is defined here. 
%
%
% Outputs
% Returns a structure containing the inverted transform
%
% 
% Example: 
% see example_invert.m in the examples directory
%
% Rob Campbell - Basel 2015


if nargin<2
	outputDir=[];
end


%Find the log file
logFile = fullfile(transformDir,'elastix.log');
if ~exist(logFile,'file')
	error('Can not find elastix.log in %s',transformDir)
end

%From the log file we need to extract the fixed image and the parameter names
fid = fopen(logFile,'r');


%Get fixed file name
tline = fgetl(fid);
while ischar(tline)
	if strfind(tline,'-f  ')
		fixedFile=regexp(tline,'^-f +(.*)','tokens');
		fixedFile = fixedFile{1}{1};

		if ~exist(fixedFile,'file')
			error('Can not find fixed file at %s', fixedFile)
		end

		fseek(fid,0,'bof');
		break
	end
	tline = fgetl(fid);
end


% Get a cell array of paths to the elastix parameter files used to calculate the the 
% transform coefs (reverseParam). We will need these ordered from lower order to higher
% order. e.g. affine then bspline. 
tline = fgetl(fid);
params = {};
while ischar(tline)
	if strfind(tline,'-p  ')
		thisFile=regexp(tline,'^-p +(.*)','tokens');
		thisFile = thisFile{1}{1};

		if ~exist(thisFile,'file')
			error('Can not find parameter file at %s', thisFile)
		end

		params = [params, thisFile];

	end
	if strfind(tline,'== start of ')
		fseek(fid,0,'bof');
		break
	end

	tline = fgetl(fid);
end

fclose(fid);

% Get a cell array of paths to the transform parameters produced by Elastix and 
% associated with fixedImage. i.e. these are transform coefs. These will be 
% supplied in reverse order. e.g. bspline then affine.
files = dir(fullfile(transformDir,'TransformParameters.*'));

if length(files) ~= length(params)
	error('Did not find as many transform coefs as parameter files')
end

coefFiles = fliplr({files.name});
for ii=1:length(coefFiles)
	coefFiles{ii} = fullfile(transformDir,coefFiles{ii});
	if ~exist(coefFiles{ii},'file')
		error('Can not find coef file at %s', coefFiles{ii})
	end
end




%Report what we will be working with
fprintf('Using fixed file: %s\n',fixedFile)
fprintf('Using parameter files:')
for ii=1:length(params)
	fprintf(' %s', params{ii})
	if ii<length(params)
		fprintf(',')
	end
end
fprintf('\n')

fprintf('Using coef files:')
for ii=1:length(coefFiles)
	fprintf(' %s', coefFiles{ii})
	if ii<length(coefFiles)
		fprintf(',')
	end
end
fprintf('\n')


%Now calculate the inverse transform 
fixedImage = mhd_read(fixedFile);
[~,stats] = elastix(fixedImage,fixedImage,outputDir,params,'t0',coefFiles);


%Force the transform chain to end here (in theory it would otherwise attempt to carry on
%and undo the inverse transform)
stats.TransformParameters{1}.InitialTransformParametersFileName='NoInitialTransform';

