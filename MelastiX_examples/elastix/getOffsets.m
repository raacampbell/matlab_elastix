function getOffsets
% example of getting translation offsets from an Elastix affine transform 	
%
% Rob Campbell - Basel 2016



%Generate fixed and moving images
fixedImage = peaks(2^8);
fixedImage = padarray(fixedImage,20); %Just to give prettier results

% circularly shifts first dimension by 10 and second dimension left by 5 pixelsn
myOffsets=[25 -15];
movingImage = circshift(fixedImage,myOffsets);


%Plot the fixed and moving images
clf
subplot(2,2,1)
imagesc(fixedImage)
title('fixed image')

subplot(2,2,2)
imagesc(movingImage)
title('movingImage image')


%Perform an affine transform
p.Transform='AffineTransform';
[OUT,stats]=elastix(movingImage,fixedImage,[],[],'paramstruct',p);


%Show the result image and the difference between this and the original
subplot(2,2,3)
imagesc(OUT)
title('transformed image')
c=caxis;

subplot(2,2,4)
imagesc(double(OUT)-fixedImage)
title('transformed-fixed image')
caxis(c)


%report offset to screen
offsets = stats.TransformParameters{1}.TransformParameters(end-1:end);
fprintf('Calculated row offset is %0.1f. True value is %d\n',offsets(2),myOffsets(1))
fprintf('Calculated col offset is %0.1f. True value is %d\n',offsets(1),myOffsets(2))

if any((myOffsets-fliplr(offsets))>1)
	fprintf('\nRegistration errors remain over a pixel. Performance could be better. You could try tuning the parameters.\n\n')
end