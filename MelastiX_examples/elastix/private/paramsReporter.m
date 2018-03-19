function paramsReporter(params)

% Prints parameter structure to screen so the user knows what each example is doing. 
%
%	function paramsReporter(params)
%
% NOTE: what is presented to screen does not guarantee that a bug isn't causing the
%       reported parameters to fail to be written, etc.


if length(params)>1
	fprintf('\n == Elastix parameters == \n');
	for p=1:length(params)
		paramsReporter(params(p))
	end
	return
end


pFields=fields(params);

for ii=1:length(pFields)
	if isempty(params.(pFields{ii}))
		continue
	end

	if isnumeric(params.(pFields{ii}))
		fprintf('%s: %d\n',pFields{ii},params.(pFields{ii}));
	elseif isstr(params.(pFields{ii}))
		fprintf('%s: %s\n',pFields{ii},params.(pFields{ii}));
	elseif islogical(params.(pFields{ii}))
		fprintf('%s: %d\n',pFields{ii},params.(pFields{ii}));
	end
		
end
