function varargout=example_2D_affine_alpha

% Shows the effect of changing alpha given a fixed number of spatial samples
% and iterations. Here we choose relatively low
% numbers for the iterations and spatial samples. Affine-transformed moving image.

fprintf('\n=====================\nRunning %s\n\n',mfilename)
help(mfilename)


%Load the data
load lena

%Plot original data
clf
colormap gray
subplot(2,3,1)
imagesc(lena), axis off equal
title('Original')


%apply an affine transform
tform = affine2d([1 0 0; .35 1 0; 0 0 1]);
lenaTrans=imwarp(lena,tform);

subplot(2,3,2)
imagesc(lenaTrans), axis off
title('Transformed')
drawnow

p.Transform='AffineTransform';
p.MaximumNumberOfIterations=400;
p.NumberOfSpatialSamples=300;

alphas=[0.2, 0.3, 0.4, 0.6];

ind=3;
for thisAlpha=alphas
	p.SP_alpha=thisAlpha; 
	runExampleLena(lenaTrans,lena,p,ind)
	ind=ind+1;	
end





function runExampleLena(lenaTrans,lena,p,ind)
	tic
	fprintf('\nStarting registration\n')
	paramsReporter(p)
	reg=elastix(lenaTrans,lena,[],'elastix_default.yml','paramstruct',p);

	fprintf('Finished registration in %d seconds\n', round(toc))

	subplot(2,3,ind)
	imagesc(reg), axis off equal 
	title(sprintf('CORRECTED: alpha=%0.1f',p.SP_alpha))
	set(gca,'Clim',[0,255])
	drawnow

