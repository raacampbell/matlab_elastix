function mhd_write(im,fname,elementSpacing)
% Writes MHD and associated RAW files for an image. 
%
% function mhd_write(im,fname,elementSpacing)
%
% Purpose
% Convert a MATLAB matrix to an MHD/RAW file pair using some reasonable defaults in the 
% MHD file. The MHD file is effectively a plain-text header file and the RAW file just
% binary. The only way to correctly re-assemble the image to use the recorded dimension 
% sizes in the MHD.
%
% The element spacing is crucial for setting the image scale. For now, this is the only
% input argument that will control what is written to the MHD file. In the future we 
% could set up param/val pairs as a cell array. If element spacing is empty we default to
% [1,1,1] for 3D data and [1,1] for 2D. For some purposes, the ratios between the numbers
% are sufficient. For others, you might want physically meaningful units.
%
%
% Inputs
% im - a matrix of image data
% fname - file name (no need to include extension)
% elementSpacing - [optional] the size of each dimension. The pixels are sized to fit. 
%
%
% Example
% mhd_write(imMat,'myImMat')
%
% see:
% http://www.itk.org/pipermail/insight-users/2007-November/024337.html


if ~isnumeric(im)
	error('im should be a matrix')
end

if ndims(im)>3
	error('Not designed to handle more than three dimensions. You''d best get hacking!')
end

if ~ischar(fname)
	error('fname should be a string')
end

%strip any extensions from fname, should they be present
[thisPath,fname] = fileparts(fname);
fname = fullfile(thisPath,fname);

if nargin<3
	elementSpacing = [1,1,1];
	elementSpacing = elementSpacing(1:ndims(im));
end


fid=fopen([fname,'.raw'],'w+');

%MATLAB indexes stuff as rows by columns, but MHD appears to expect these inverted
%without this step, stuff is rotated in VV and point transforms fail
im = permute(im,[2,1,3]);


cnt=fwrite(fid,im,class(im));
fclose(fid);

switch class(im)
	case 'uint8',  dtype='uchar';
	case 'int16', dtype='short';
	case 'uint16', dtype='ushort';
	case 'uint32', dtype='int';
    case 'int32', dtype='int';
	case 'single', dtype='float';
	case 'double', dtype='double';
	otherwise
		error('conversion for data type %s unknown',class(im))
end

%convert elementSpacing to a string to make it easier to handle below
elementSpacing = num2str(elementSpacing);
elementSpacing = regexprep(elementSpacing,' +',' ');


fid=fopen([fname,'.mhd'],'w+');
fprintf(fid,'ObjectType = Image\nCompressedData = False\nBinaryData = True\n');
fprintf(fid,'NDims = %d\n', ndims(im));
fprintf(fid,'DataType = %s\n',dtype);
fprintf(fid,['DimSize = ',repmat('%d ',1, length(size(im))), '\n'], size(im));
fprintf(fid,'ElementSize = %s\n', elementSpacing); %Make the voxels fill the spaces
fprintf(fid,'ElementSpacing =  %s\n', elementSpacing);
fprintf(fid,'ElementType = MET_%s\n',upper(dtype));
fprintf(fid,'ElementByteOrderMSB = False\n');
[~,nm]=fileparts(fname);
fprintf(fid,'ElementDataFile = %s.raw\n',nm);
fclose(fid);
