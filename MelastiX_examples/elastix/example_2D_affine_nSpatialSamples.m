function example_2D_affine_nSpatialSamples
% Shows the effect of changing the number of spatial samples with a 
% fixed number of iterations. Uses the suggested value for alpha. 
% Here we choose relatively low numbers for the iterations and spatial 
% samples. Affine-transformed moving image.
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
p.MaximumNumberOfIterations=1.5E3;
p.SP_alpha=0.6; %The recomended value


nSamples=[50,100,200,500];

ind=3;
for theseNSamples=nSamples
	p.NumberOfSpatialSamples=theseNSamples;
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
	title(sprintf('CORRECTED: %d samples',p.NumberOfSpatialSamples))
	drawnow
	set(gca,'Clim',[0,255])
