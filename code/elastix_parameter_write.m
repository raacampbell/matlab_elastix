function varargout=elastix_parameter_write(elastixParamFname,YAML,userParam)
% Create an elastix-readable parameter file based upon a YAML and optional user-supplied parameters
%
% function params=elastix_parameter_write(elastixParamFname,YAML,userParam)
%
%
% Purpose
% writes the elastix parameter file "elastixParamFname" based upon a YAML
% file and an optional user-supplied structure, userParam, which modifies it.
%
%
% Inputs
% elastixParamFname - a string defining a path to which the elastix parameter 
%                     file will be written.
% YAML - the file name of the YAML file to use. If empty, use the default 
%        file. 
% userParam - an optional parameter structure to tweak parameter settings without
%             needing to write to the YAML. Useful for quick tweaks. 
%
% Outputs
% params = optionally return the parameters
%
% Examples:
% elastix_parameter_write('myFname')
% Write parameter file to fname. Uses default values from elastix_default.yml
%
%
% Default values in the default YAML can be over-ridden as follows:
% elastix_parameter_write('myFname',[],paramStructure)
% where "paramStructure" is in the format:
% >> params
% params =    
%       AutomaticScalesEstimation: 'true'
%       AutomaticTransformInitialization: 'true'
%       BSplineInterpolationOrder: 1
%       DefaultPixelValue: 0
%       .... 
%
% This structure can be produced by hand or by reading in a 
% parameter file or MelastiX YAML with elastix_parameter_read. 
% Not all parameters need to be defined in the parameter structure. 
% Values defined in the structure over-ride the defaults defined 
% in this function. 
%    
% Rob Campbell - August 2015
%
% Also see: 
% elastix_parameter_read, elastixYAML2struct, elastix_paramStruct2txt
  

%Read the parameter file that will go on to be modified (but not on disk)
if isempty(YAML)
   YAML='elastix_default.yml';
   fprintf('%s: Using default YAML file: %s\n',mfilename,YAML)
end
params=elastixYAML2struct(YAML); %Default params from a user-supplied YAML or the default YAML

%If a parameter structure has been provided, validate it using the 
%default elastix YAML
if nargin==3

   [~,defaultYAML]=elastixYAML2struct('elastix_default.yml'); %The raw YAML data with the validation fields
   defaultKeys=fields(defaultYAML);
   keys=fields(userParam);

   for ii=1:length(keys)
   	   thisKey = keys{ii};
   	   if ~isempty(strmatch(thisKey,defaultKeys))
   	   	   valid=defaultYAML.(thisKey).valid;
   	   	   if validateElastixParam(userParam.(thisKey),valid)
                    params.(thisKey)=userParam.(thisKey); %replace with our new value
   	   	   	else
   	   	   		fprintf('Skipping the key %s: its value did not validate\n', thisKey)
  	   	   	end   	   	   		
   	   else
 	   		fprintf('Skipping the key %s: it is not available in default YAML so can not be validated.\n', thisKey)
   	   end

   end %for ii=1:length(keys)

end %if nargin==3



%Write to disk
elastix_paramStruct2txt(elastixParamFname,params)




if nargout>0
    varargout{1}=params;
end
