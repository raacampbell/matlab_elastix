function example_invert
% This example shows how to invert a transform.
% We load a fixed image and a distorted version of it, the moving image.
% Landmarks are defined in the moving image space and overlaid on the moving image.
% The goal is to overlay these points on the fixed image. 
% Achieving this goal requires calculating the inverse transform. 
%
% This approach is useful in scenarios where you have a single reference
% image and multiple sample images that you want to register to the one 
% reference image. If these sample images are associated with landmarks,
% you can overlay the landmarks from the different sample images into a common
% reference space. 


help(mfilename)


fprintf('\nStep One:\nLoad images and points.\n')


tmpDir = fullfile(tempdir,'dog_registration');
params = {'params_0.txt','params_1.txt'};
fixed = imread('../transformix/uma.tiff');
moving = imread('../transformix/uma_distorted.tiff');

pointsInMovingSpace = csvread('points_on_deformed_dog.csv'); %read sparse points

clf 
subplot(2,2,1)
showImage(fixed,'Fixed image')

subplot(2,2,2)
showImage(moving,'Moving image with sparse points')
hold on 
plot(pointsInMovingSpace(:,1),pointsInMovingSpace(:,2),'g.')
hold off

drawnow


fprintf('\nStep Two:\nRegistering moving image to fixed image with elastix...\n')
elastix(moving,fixed,tmpDir,params)

registered_dog = mhd_read(fullfile(tmpDir,'result.1.mhd'));

subplot(2,2,3)
showImage(registered_dog,'Registered moving image')
drawnow


fprintf('\nStep Three:\nInverting the transform...\n')
inverted = invertElastixTransform(tmpDir);

fprintf('\nStep Four:\nUsing transformix to apply inverted transform to sparse points in moving space...\n')
subplot(2,2,4)
showImage(fixed,'Fixed image with inverse transformed points')
drawnow

REG=transformix(pointsInMovingSpace,inverted);
hold on
plot(REG.OutputPoint(:,1),REG.OutputPoint(:,2),'g.')
hold off



function showImage(im,thisTitle)
	imagesc(im)
	axis equal off
	title(thisTitle)