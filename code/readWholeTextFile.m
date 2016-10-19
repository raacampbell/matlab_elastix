function txt=readWholeTextFile(fname)
% Read whole text file into a variable
% 
% function txt=readWholeTextFile(fname)
%
% Purpose
% Read text file defined by relative or absolute path 'fname' into 
% a string. Return the string to the workspace.
%
% Inputs
% fname - string defining the relative or absolute path to a text file
%
% Outputs
% txt - string containing the contents of file fname.
%
%
% Rob Campbell - August 2012



if ~exist(fname,'file')
	error('Can not find file %s\n',fname)
end


% preassign s to some large cell array
preAsn=1000;
txt=cell(preAsn,1);
sizS = preAsn;
n=1;

fid = fopen(fname);
tline = fgetl(fid);

while ischar(tline)
   txt{n} = tline;
   n=n+1;

   %# grow s if necessary
   if n > sizS
       txt = [txt;cell(preAsn,1)];
       sizS = sizS + preAsn;
   end
   tline = fgetl(fid);
end

% remove empty entries in s
txt(n:end) = [];

fclose(fid);
