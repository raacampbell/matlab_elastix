function out=struct2varargin(in,removeEmpty)
% Convert structure to paramater/value pairs
%
% function out=struct2varargin(in,removeEmpty)
%
% Example:
% s.category = 'tree'; s.height = 37.4; s.name = 'birch';
% struct2varargin(s)
%
% ans = 
%
%    'category'
%    'tree'   
%    'height' 
%    [37.4000]
%    'name'   
%    'birch' 
%
%
% By default it removes parameters with empty values. This can be
% disabled. 
%
% Rob Campbell - August 2012

if nargin<2
    removeEmpty=1;
end


if ~isstruct(in)
    error('struct2varargin: input should be a structure')
end


parameters=fields(in);
values=struct2cell(in);


if length(parameters) ~= length(values)
    error('parameters and values have different lengths')
end



out=[parameters,values]';

if removeEmpty
    out(:,cellfun(@isempty,out(2,:)))=[]; %remove empties
end


out=out(:);
