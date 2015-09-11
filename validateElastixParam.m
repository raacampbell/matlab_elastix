function out=validateElastixParam(value,valid)
% determine whether an elastix parameter value is valid
%
% function out=validateElastixParam(value,valid)
%
% Purpose
% Uses a value and valid field read from the YAML to 
% determine whether the value field is valid.
% This is a helper function of no direct use to the user.
%
% Inputs
% contents of one value field and one valid field
%
%
% Rob Campbell - Basel 2015
%
% Also see:
% elastixYAML2struct, elastix_parameter_write


	%is valid a function handle?
	if isstr(valid) & regexp(valid,'^_@')
		valid(1)=[];
		isHandle=1;
	else
		isHandle=0;		
	end


	if iscell(value) %Cell arrays should all be numerics 
		if isHandle
  		    out=all(cellfun(eval(valid),value)); %bloody hell, a use for eval
	    else
	    	fprintf('NO TEST FOR CELL ARRAYS WITHOUT A FUNCTION HANDLE\n')
	    	out=0
	    end
  		return			
	end

	if isnumeric(value)
		if isHandle
  		    out=all(arrayfun(eval(valid),value));
	    elseif isnumeric(valid)
	    	out=~isempty(find(valid,value));
	    elseif iscell(valid)
	    	if ~all(cellfun(@isnumeric,valid))
	    		fprintf('%s: value is numeric but valid contains non-numerics\n ',mfilename)
	    		out=0;
	    	end
	    	out=find(cell2mat(valid),value);
	    else
	    	out=0;
	    	fprintf('%s: value is numeric but valid is %s\n',mfilename,class(valid))
	    end
  		return			
	end

	if isstr(value)
		if isHandle
  		    out=all(arrayfun(eval(valid),value)); 
	    elseif isstr(valid)
	    	out=strcmp(valid,value);
	    elseif iscell(valid)
	    	out=~isempty(strmatch(value,valid));
	    else
	    	out=0;
	    	fprintf('%s: value is numeric but valid is %s\n',mfilename,class(valid))
	    end
  		return			
	end

	if islogical(value) & isHandle
	   out=all(arrayfun(eval(valid),value));
	else
		fprintf('Value is logical but valid is %s\n',class(valid))
		out=0;
	end