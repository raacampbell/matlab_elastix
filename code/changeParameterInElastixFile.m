function varargout = changeParameterInElastixFile(fname,param,value,verbose)
% change or add a paramater in an elastix parameter or transform file 
%
% function fileContents = changeParameterInElastixFile(fname,param,value)	
%
% Purpose
% Replace or add parameter 'param' in file 'fname'. This function is used
% to ake minor changes to elastix or transformix parameter files.
%
%
% Inputs
% fname - relative or absolute path to a parameter file. This file will 
%         be modified by this function.
% param - a string defining a parameter that is to be changed or added.
%         (not case-sensitive)
% value - a string defining the new value of 'param'
% verbose - [optional, 0 by default] if 1 we print to screen what 
%           changes were made
%
% 
% Outputs
% fileContents - [optional] If fileContents is requested, the file fname
%                is not over-written and is instead returned as a string.
%                This option is useful for testing purposes. 
%
%
% Examples
% changeParameterInElastixFile('paramFile.txt','BSplineTransformSplineOrder', '3')
%
%
% Rob Campbell - Basel 2015


if ~exist(fname,'file')
	error('Unable to find file %s\n',fname)
end

if nargin<4
	verbose=0;
end

if ~isstr(param)
	error('Input argument param should be a string')
end

if ~isstr(value)
	error('Input argument value should be a string')
end


%Read in file line by line
fid = fopen(fname,'r');
tline = fgetl(fid);
fileLines = {};

while ischar(tline)
	fileLines = [fileLines,tline];
	tline = fgetl(fid);
end
fclose(fid);


%Look for the parameter we want to change
foundIt=0;
for ii=1:length(fileLines)
	if regexp(fileLines{ii},'//') %skip comment lines
		continue
	end

	rex = sprintf('\\((%s) (.*)\\)',param);
	tok=regexpi(fileLines{ii},rex,'tokens');

	if isempty(tok)
		continue
	end
	if length(tok{1}) ~= 2
		continue
	end

	paramName = tok{1}{1};
	valueName = tok{1}{2};

	%Add quotes around value if needed
	if strcmp(valueName(1),'"')
		value = ['"',value,'"'];
	end
	if verbose
		fprintf('File: %s - Found param %s: replacing %s with %s\n',fname,paramName,valueName,value)
	end

	%Build new param string for this line
	fileLines{ii} = sprintf('(%s %s)',paramName,value);
	foundIt=1;
	break
end

%If the line was not found, that means the user is trying to add a new parameter
if ~foundIt
	if regexp(value,'[^0-9 \.-+]') %add quotes if it's not a number or list of numbers
		value = ['"',value,'"'];
	end
	if verbose
		fprintf('Adding new param %s with value %s\n',param,value)
	end
	fileLines = [fileLines,sprintf('(%s %s)',param,value)];
end


%Write to file or return as a string
if nargout>0
	str = [];
	for ii=1:length(fileLines)
		str = [str,sprintf('%s\n',fileLines{ii})];
	end
	varargout{1}=str;
	return
end

%Replace data in file
if verbose
	fprintf('replacing %s\n',fname)
end
fid = fopen(fname,'w');
for ii=1:length(fileLines)
	fprintf(fid,'%s\n',fileLines{ii});
end
fclose(fid);