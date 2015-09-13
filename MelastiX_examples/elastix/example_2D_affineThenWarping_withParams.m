function varargout=example_2D_affineThenWarping_withParams
% Shows the ability of elasix to chain together different transforms
% Here we do an affine followed by a non-rigid and specify the 
% steps using raw elastix params files, not a YAML.


fprintf('\n=====================\nRunning %s\n\n',mfilename)
help(mfilename)


%Load the data
load lena

%Plot original data
clf
colormap gray
subplot(2,2,1)
imagesc(lena), axis off equal
title('Original')




%apply an affine transform
lenaTrans=distortLena(lena);




subplot(2,2,2)
imagesc(lenaTrans), axis off equal
title('Transformed')
drawnow

tic
fprintf('\nStarting registration\n')
[~,out]=elastix(lenaTrans,lena,[],{'AtW_parameters_1.txt','AtW_parameters_2.txt'});
fprintf('Finished registration in %d seconds\n', round(toc))


%show the results of both steps
subplot(2,2,3)
imagesc(out.transformedImages{1}), axis off equal 
title('CORRECTED: affine only')
drawnow
set(gca,'Clim',[0,255])

subplot(2,2,4)
imagesc(out.transformedImages{2}), axis off equal 
title('CORRECTED: affine + non-rigid')
drawnow
set(gca,'Clim',[0,255])


if nargout>0
	varargout{1}=out;
end