function applyLenaTransform2Dog_withParams

% Transform dog with Lena transform from elastix affine + warp example
% Then "fix" the image using the transform parameters already calculated by that example
% This function chains two raw parameters files produced by Elastix

fprintf('\n=====================\nRunning %s\n\n',mfilename)
help(mfilename)

%Load dog image and transform it using the same function us to distort Lena
%in the elastix examples directory
load('uma')
umaTform = distortLena(uma);


%Plot the transformed dog
clf
colormap gray

subplot(1,3,1)
imagesc(umaTform), axis equal off
title('Input: Warped dog')


%apply transformix based on parameters calculated in lena affine + warp example
%Supply paths to parameter files. Note that the order matters. You need to supply 
%the last one in the chain first.
paramFiles = {'./applyLenaTransform2Dog_params/TransformParameters.1.txt','./applyLenaTransform2Dog_params/TransformParameters.0.txt'};
reg=transformix(umaTform,paramFiles,1);
subplot(1,3,2)
imagesc(reg), axis equal off
title('Output: Transformed dog')


%plot the original dog
subplot(1,3,3)
imagesc(uma), axis equal off
title('Reference image: Original dog')
