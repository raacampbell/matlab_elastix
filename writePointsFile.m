function writePointsFile(fname,data,pointType)
% Write a transformix points file for point transformation
%
% function writePointsFile(fname,data,pointType)
%
% examples
%  writePointsFile('myPoints.txt',data, 'index')
%  writePointsFile('myPoints.txt',data)
% 
% The points file format is:
% First line should be "index" or "point", depending if the user supplies voxel indices or real-world coords. 
% The second line should be the number of points that should be transformed. 
% The third and following lines give the indices or points. Space separated. x,y,z
%
%
% fname - string to file name
% data - a matrix that is one row per point. columns must be ordered: x, y, z.
% pointType - a string ('index' or 'point') this is 'point' by default
%
%
% Rob Campbell - Basel 2015

if ~isstr(fname)
	error('fname must be a string that defines a path to a file')
end

if nargin<3
    pointType='point';
end

if ~strcmp(pointType,'index') & ~strcmp(pointType,'point')
    fprintf('argument pointType should be the string "index" or "point"\n')
    return
end


fid = fopen(fname,'w+');

fprintf(fid,'%s\n%d\n',pointType,size(data,1));

formatStr = repmat('%f ',[1,size(data,2)]);
for ii=1:size(data,1)

    fprintf(fid,[formatStr,'\n'], data(ii,:));
end

fclose(fid);

