function stats=invertElastixTransform(fixedImage,params,reverseParam,outputDir)
%
% Inverts an already-calculated elastix transform 
%
% invertedTransform=invertElastixTransform(fixedImage,params,reverseParam,outputDir)
%
% 
% Purpose
% Uses elastix to invert an already-calculated transform 
%
% 
% Inputs
% fixedImage - The fixed image associated with the transform parameters 
% params - Absolute or relative paths to the elastix parameter files used to calculate the 
%          the transform coefs (reverseParam). Supply from low order to high order:
%          e.g. affine then bspline.
% reverseParam - Absolute or relative paths to the transform parameters produced by 
%                Elastix and associated with fixedImage. i.e. these are transform coefs.
%                Supply in reverse order. e.g. bspline then affine.
% outputDir  - Directory in which to conduct the registration. A temporary directory
%              is created if none is defined here. 
%
%
% Outputs
% Returns a structure containing the inverted transform
%
% 
% To see this in action look in the examples directory.
%
% 


if nargin<4
	outputDir=[];
end


%This calculates the inverse transform 
[~,stats] = elastix(fixedImage,fixedImage,outputDir,params,'t0',reverseParam);


%Force the transform chain to end here (in theory it would otherwise attempt to carry on
%and undo the inverse transform)
stats.TransformParameters{1}.InitialTransformParametersFileName='NoInitialTansform';

