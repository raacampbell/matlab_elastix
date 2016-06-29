function varargout=elastixYAML2struct(fname)
% Read MelastiX YAML file and convert to a structure
%
% function [params,origStruct]=elastixYAML2struct(fname)
%
% Purpose
% Read MelastiX YAML file and convert to a structure. 
% Relies on https://github.com/raacampbell13/yamlmatlab
% In addition to reading the YAML, this function also
% checks for errors and ensures that the values in the file
% are reasonable. It does this based on the .valid fields
% in the params structure. 
%
% Usage:
% elastixYAML2struct('myFname')
% if no arguments are supplied, the function attempts to read
% the default YAML file: elastix_default.yml
%
% Outputs
% params - a processed version of the YAML file in the form of an 
%          easy to read structure that can readily be converted into
%          an elastix parameter file.
% origStruct - the original structure produced by ReadYaml.
%
%
% Rob Campbell - Basel 2015
   
if nargin==0 | isempty(fname)
	fname='elastix_default.yml';
	fprintf('Using the default YAML file: %s\n',fname)
end


if ~exist(fname,'file')
	fprintf('%s: Unable to find YAML file %s\n',mfilename,fname)
	return
end


% Instruct user to download YAML tools if they are missing. 
% Function will go on to crash on the next line if the tools are missing
if isempty(which('yaml.ReadYaml'))
	fprintf('\n\n ** Unable to find yaml tools. Please download from https://github.com/raacampbell/yamlmatlab and add to path ** \n\n')
end

%Read the YAML file into a structure
yml=yaml.ReadYaml(fname);



%Go through the YAML file one key at a time and convert it into a more friendly format
keys = fields(yml);
params = struct;

for ii=1:length(keys)
	thisKey=keys{ii};

	if isempty(yml.(thisKey))
		continue
	end

	%Get the value and valid values for this key
	if isfield(yml.(thisKey),'value')
		value = yml.(thisKey).value;
	else
		fprintf('no value for key %s. SKIPPING\n',thisKey)
		continue
	end

	if isfield(yml.(thisKey),'valid')
		valid = yml.(thisKey).valid;
	else
		fprintf('no field "valid" for key %s. SKIPPING\n',thisKey)
		continue
	end
		

	%Handle a string
	if isstr(value) 
		if validateElastixParam(value,valid)
			params.(thisKey)=value;
		else
			fprintf('SKIPPING key %s. Value %s does not validate\n',thisKey,value)
		end			
		continue
	end


	%Convert logicals to the strings 'true' or 'false'
	if islogical(value) 
		if ~validateElastixParam(value,valid)
			fprintf('SKIPPING key %s. Value %d does not validate\n',thisKey,value)
			continue
		end

		if value
			params.(thisKey)='true';
		else
			params.(thisKey)='false';			
		end
		continue
	end


	%Handle numerics. These may exist as either scalars or cell arrays of scalars
	if isnumeric(value)
		if validateElastixParam(value,valid)
			params.(thisKey)=value;
		else
			fprintf('SKIPPING key %s. Value %d does not validate\n',thisKey,value)
		end			
		continue
	end

	if iscell(value)
		if validateElastixParam(value,valid)
			params.(thisKey)=cell2mat(value);
		else
			fprintf('SKIPPING key %s. Value is a cell array and does not validate\n',thisKey)
		end					
		continue
	end


	%If we have arrived here, there's something wrong
	fprintf('There is something wrong with key %s\n',thisKey)


end




if nargout>0
	varargout{1}=params;
end

if nargout>1
	varargout{2}=yml;
end