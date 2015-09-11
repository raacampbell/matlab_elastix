function V = mhd_read(info)
% Function for reading the volume of a Insight Meta-Image (.mhd) file
% 
% volume = tk_read(file-header)
%
% examples:
% 1: info = mhd_read_header()
%    V = mhd_read_volume(info);
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

if(~isstruct(info))
    if exist(info,'file')
        info=mhd_read_header(info); 
    else
        error('Can not find file %s',info)
    end        
end

switch(lower(info.DataFile))
    case 'local'
    otherwise
    % Seperate file
    info.Filename=fullfile(fileparts(info.Filename),info.DataFile);
end
        
% Open file
switch(info.ByteOrder(1))
    case ('true')
        fid=fopen(info.Filename','rb','ieee-be');
    otherwise
        fid=fopen(info.Filename','rb','ieee-le');
end

switch(lower(info.DataFile))
    case 'local'
        % Skip header
        fseek(fid,info.HeaderSize,'bof');
    otherwise
        fseek(fid,0,'bof');
end

datasize=prod(info.Dimensions)*info.BitDepth/8;

% Read the Data
switch(info.DataType)
    case 'char'
        V = int8(fread(fid,datasize,'char')); 
    case {'uchar','uint8'}
        V = uint8(fread(fid,datasize,'uchar')); 
    case 'short'
        V = int16(fread(fid,datasize,'short')); 
    case {'ushort','uint16'}
        V = uint16(fread(fid,datasize,'ushort')); 
    case {'int','int32'}
        V = int32(fread(fid,datasize,'int')); 
    case {'uint','uint32'}
        V = uint32(fread(fid,datasize,'uint')); 
    case {'float','single'}
        V = single(fread(fid,datasize,'float'));   
    case 'double'
        V = double(fread(fid,datasize,'double'));
    otherwise
        error('Could not find data type %s',info.DataType)
end

fclose(fid);

V = reshape(V,info.Dimensions);

%flip the first two axes as MHD appears to expect this
V = permute(V,[2,1,3]);
