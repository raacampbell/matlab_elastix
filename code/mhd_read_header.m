function info = mhd_read_header(filename)
% Read the header of an Insight Meta-Image (.mhd) file
% 
% info  = mhd_read_header(filename);
%
% examples:
% 1,  info=mhd_read_header()
% 2,  info=mhd_read_header('volume.mhd');
%
% Output:
% Returns a structure containing the data in the header file 
%
%
% From Viewer3D by Dirk-Jan Kroon (see FEX)



if(exist('filename','var')==0)
    [filename, pathname] = uigetfile('*.mhd', 'Read mhd-file');
    filename = [pathname filename];
end

fid=fopen(filename,'rb');
if(fid<0)
    fprintf('could not open file %s\n',filename);
    return
end



info.Filename=filename;
info.Format='MHD';
info.CompressedData='false'; %We don't allow compressed data at all
readelementdatafile=false;


while(~readelementdatafile)
    str=fgetl(fid);
    s=find(str=='=',1,'first');
    if(~isempty(s))
        type=str(1:s-1); 
        data=str(s+1:end);
        while(type(end)==' '); type=type(1:end-1); end
        while(data(1)==' '); data=data(2:end); end
    else
        type=''; data=str;
    end
    
    switch(lower(type))
        case 'ndims'
            info.NumberOfDimensions=sscanf(data, '%d')';
        case 'dimsize'
            info.Dimensions=sscanf(data, '%d')';
        case 'elementspacing'
            info.elementSpacing=sscanf(data, '%lf')';
        case 'elementsize'
            info.ElementSize=sscanf(data, '%lf')';
            if(~isfield(info,'PixelDimensions'))
                info.elementSize=info.ElementSize;
            end
        case 'elementbyteordermsb'
            info.ByteOrder=lower(data);
        case 'anatomicalorientation'
            info.AnatomicalOrientation=data;
        case 'centerofrotation'
            info.CenterOfRotation=sscanf(data, '%lf')';
        case 'offset'
            info.Offset=sscanf(data, '%lf')';
        case 'binarydata'
            info.BinaryData=lower(data);
        case 'compresseddatasize'
            info.CompressedDataSize=sscanf(data, '%d')';
        case 'objecttype',
            info.ObjectType=lower(data);
        case 'transformmatrix'
            info.TransformMatrix=sscanf(data, '%lf')';
        case 'compresseddata';
            info.CompressedData=lower(data);
        case 'binarydatabyteordermsb'
            info.ByteOrder=lower(data);
        case 'elementdatafile'
            info.DataFile=data;
            readelementdatafile=true;
        case 'elementtype'
            info.DataType=lower(data(5:end));
        case 'headersize'
            val=sscanf(data, '%d')';
            if(val(1)>0), info.HeaderSize=val(1); end
        otherwise
            info.(type)=data;
    end
end


switch(info.DataType)
    case 'char', info.BitDepth=8;
    case 'uchar', info.BitDepth=8;
    case 'uint8', info.BitDepth=8; %MATLAB
    case 'uint16', info.BitDepth=16; %MATLAB
    case 'short', info.BitDepth=16;
    case 'ushort', info.BitDepth=16;
    case 'int', info.BitDepth=32;
    case 'uint', info.BitDepth=32;
    case 'uint32', info.BitDepth=32; %MATLAB
    case 'float', info.BitDepth=32;
    case 'double', info.BitDepth=64;
    otherwise
     info.BitDepth=0;
     fprintf('data type %s has unknown bit BitDepth',info.DataType)
end

if(~isfield(info,'HeaderSize'))
    info.HeaderSize=ftell(fid);
end


fclose(fid);
