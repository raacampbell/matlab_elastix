function transformSparsePoints_forward

% Transform points on the original image to the warped domain. 
% The transform parameters used here were those calculated to get an image deformed
% by the transform in distortLena.m back to its original state. However, as described
% in the Elastix PDF manual, these parameters define the transform *from the fixed 
% (non-deformed) image to the moving (deformed) image*. Consequently, here we transform
% points laid over the original image onto the deformed image.



fprintf('\n=====================\nRunning %s\n\n',mfilename)
help(mfilename)

%Load dog image and transform it using the same function us to distort Lena
%in the elastix examples directory
load('uma')



%Plot the transformed dog
clf
colormap gray

subplot(1,2,1)
imagesc(uma), axis equal off
title('Original image with overlaid points')
rawPoints = csvread('points_on_raw_dog.csv');
hold on
rawP = plot(rawPoints(:,1),rawPoints(:,2),'.g');
hold off



subplot(1,2,2)
umaTform = distortLena(uma);
imagesc(umaTform), axis equal off
title('Deformed image with transformed points')

%apply transformix to the points using parameters calculated in lena affine + warp example
paramFiles = {'./applyLenaTransform2Dog_params/TransformParameters.1.txt','./applyLenaTransform2Dog_params/TransformParameters.0.txt'};
reg=transformix(rawPoints,paramFiles,1);
hold on
transP=plot(reg.OutputIndexFixed(:,1),reg.OutputIndexFixed(:,2),'.g');

