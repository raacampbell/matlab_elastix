function V = mhd_read(headerInfo)
% Function for reading the volume of a Insight Meta-Image (.mhd) file
% 
% volume = mhd_read(file-header)
%
% examples:
% 1: headerInfo = mhd_read_header()
%    V = mhd_read_volume(headerInfo);
%    imshow(squeeze(V(:,:,round(end/2))),[]);
%
% 2: V = mhd_read_volume('test.mhd');
%
% Modified by Rob Campbell, August 2012
% Does not work with compressed data, since we will never write these with MelastiX
%
% Original on FEX:
% Viewer3D by Dirk-Jan Kroon (file: mhd_read_volume.m)
% Also see: http://ch.mathworks.com/matlabcentral/fileexchange/29344-read-medical-data-3d

if(~isstruct(headerInfo))
    if exist(headerInfo,'file')
        headerInfo=mhd_read_header(headerInfo); 
    else
        error('Can not find file %s',headerInfo)
    end        
end

switch(lower(headerInfo.DataFile))
    case 'local'
    otherwise
    % Seperate file
    headerInfo.Filename=fullfile(fileparts(headerInfo.Filename),headerInfo.DataFile);
end
        
% Open file
switch(headerInfo.ByteOrder(1))
    case ('true')
        fid=fopen(headerInfo.Filename,'rb','ieee-be');
    otherwise
        fid=fopen(headerInfo.Filename,'rb','ieee-le');
end

switch(lower(headerInfo.DataFile))
    case 'local'
        % Skip header
        fseek(fid,headerInfo.HeaderSize,'bof');
    otherwise
        fseek(fid,0,'bof');
end

datasize=prod(headerInfo.Dimensions)*headerInfo.BitDepth/8;

% Read the Data
switch(headerInfo.DataType)
    case 'char'
        V = int8(fread(fid,datasize,'char')); 
    case {'uchar','uint8'}
        V = uint8(fread(fid,datasize,'uchar')); 
    case 'short'
        V = int16(fread(fid,datasize,'short')); 
    case {'ushort','uint16'}
        V = uint16(fread(fid,datasize,'ushort')); 
    case {'int','int32'}
        V = (fread(fid,datasize,'int')); 
    case {'uint','uint32'}
        V = uint32(fread(fid,datasize,'uint')); 
    case {'float','single'}
        V = single(fread(fid,datasize,'float'));   
    case 'double'
        V = double(fread(fid,datasize,'double'));
    otherwise
        error('Could not find data type %s',headerInfo.DataType)
end

fclose(fid);

V = reshape(V,headerInfo.Dimensions);

%flip the first two axes as MHD appears to expect this
V = permute(V,[2,1,3]);
