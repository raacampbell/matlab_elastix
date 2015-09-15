function out=readTransformedPointsFile(fname)
% Read transformix points file 
%
% function out=readTransformedPointsFile(fname)	
%
% Inputs
% fname - string defining a relative or absolute path to a transformix points file
%
%
% example
% out = readTransformedPointsFile('outputpoints.txt')
% 
%
% Rob Campbell - Basel 2015

if ~exist(fname)
    fprintf('Can not find %s\n',fname)
    out=[];
    return
end

fid = fopen(fname,'r');


%Get the number of lines 
numLines=1;
tline = fgetl(fid);
while isstr(tline)
	numLines=numLines+1;
	tline = fgetl(fid);

end
numLines=numLines-1; %because the last line is empty (just a newline)



fseek(fid,0,-1); %rewind back to start of file
tline = fgetl(fid);
n=1;

out=struct;
while isstr(tline) 
    tok=regexp(tline,'; (\w+) = \[ (.*?) \]','tokens');

    for ii=1:length(tok)
        tmp=str2num(str2mat(tok{ii}{2}));
    	if n==1 %pre-allocate
    		out.(tok{ii}{1}) = ones(numLines,size(tmp,2));
    	end

    	out.(tok{ii}{1})(n,:) = tmp;

    end

	tline = fgetl(fid);
	n=n+1;
end


fclose(fid);

