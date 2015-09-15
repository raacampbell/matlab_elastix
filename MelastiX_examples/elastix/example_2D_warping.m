function varargout=example_2D_warping
% Shows the non-rigid registration ability of Elastix

fprintf('\n=====================\nRunning %s\n\n',mfilename)
help(mfilename)


%Load the data
load lena

%Plot original data
clf
colormap gray
subplot(1,3,1)
imagesc(lena), axis off equal
title('Original')



%Horribly warp Lena using code from 
% http://blogs.mathworks.com/steve/2006/08/04/spatial-transformations-defining-and-applying-custom-transforms/
r = @(x) sqrt(x(:,1).^2 + x(:,2).^2);
w = @(x) atan2(x(:,2), x(:,1));

f = @(x) [r(x).^1.35 .* cos(w(x)), r(x).^1.35 .* sin(w(x))];
g = @(x, unused) f(x);

tform3 = maketform('custom', 2, 2, [], g, []);
lenaTrans = imtransform(lena, tform3, 'UData', [-1 1], 'VData', [-1 1], ...
    'XData', [-1 1], 'YData', [-1 1]);




subplot(1,3,2)
imagesc(lenaTrans), axis off equal
title('Transformed')
drawnow


p.Transform='BSplineTransform';
p.MaximumNumberOfIterations=1E3;
p.NumberOfSpatialSamples=1E3;
p.SP_a=4000;


tic
fprintf('\nStarting registration\n')
paramsReporter(p)
reg=elastix(lenaTrans,lena,[],'elastix_default.yml','paramstruct',p);

fprintf('Finished registration in %d seconds\n', round(toc))

subplot(1,3,3)
imagesc(reg), axis off equal 
title(sprintf('CORRECTED: %d samples',p.NumberOfSpatialSamples))
drawnow
set(gca,'Clim',[0,255])
