function txt=readWholeTextFile(fname)
% Read whole text file into a variable
% 
% function txt=readWholeTextFile(fname)
%
% Rob Campbell - August 20120


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
