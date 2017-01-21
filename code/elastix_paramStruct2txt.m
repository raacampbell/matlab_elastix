function elastix_paramStruct2txt(fname,params,verbose)
% Write elastix parameter structure to text file
%
% function elastix_paramStruct2txt(fname,params,verbose)
%
% Write parameter file to fname. Uses default values from this
% file. The output parameters are those produced by a
% registration (e.g. TransformParameters.0.txt). This function
% writes one of these files using a previously imported structure. 
%
%
% Rob Campbell - August 2012
%
% Also see: elastix_parameter_read, elastix_parameter_write


if length(params)>1
    error('params must have a length of 1')
end

if nargin<3
    verbose=false;
end


fprintf('Writing parameter file to %s\n',fname)

fid=fopen(fname,'w+');


R=fields(params);
for ii=1:length(R)
    param=R{ii};
    value=params.(R{ii});

    if isempty(value) %Allows for a value to not be written
        continue
    end

    if ischar(value)
        value = strrep(value,'\','\\');
        str = sprintf('(%s "%s")\n',param,value);
        fprintf(fid,str);
        if verbose
            fprintf(str)
        end
        continue
    end

    if isnumeric(value)
        if mod(value(1),1)==0
            str = sprintf(['(%s',repmat(' %d',1,length(value)), ')\n'], param, value);
            fprintf(fid,str);
            if verbose
                fprintf(str)
            end 
            continue
        elseif mod(value(1),1)>0
            str = sprintf(['(%s',repmat(' %2.6f',1,length(value)), ')\n'],param,value);
            fprintf(fid,str);
            if verbose
                fprintf(str)
            end
            continue
        end        
    end

    if islogical(value)
        if value
            str = sprintf('(%s "true")\n',param);
        else
            str = sprintf('(%s "false")\n',param);
        end
        fprintf(fid,str);
        if verbose
            fprintf(str)
        end
        continue
    end

    fprintf('elastix_paramStruct2txt did not write param %s\n', param)


end

fclose(fid);


