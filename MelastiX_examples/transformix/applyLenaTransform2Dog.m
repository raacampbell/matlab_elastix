function applyLenaTransform2Dog

% Transform dog with Lena transform from elastix affine + warp example
% Then "fix" the image using the transform parameters already calculated by that example


fprintf('\n=====================\nRunning %s\n\n',mfilename)
help(mfilename)

	load('uma')
	umaTform = distortLena(uma);
	load params 

	clf
	colormap gray

	subplot(1,3,1)
	imagesc(umaTform), axis equal off
	title('Input: Warped dog')


	%apply transformix based on parameters calculated in lena affine + warp example
	reg=transformix(umaTform,params);
	subplot(1,3,2)
	imagesc(reg), axis equal off
	title('Output: Transformed dog')


	subplot(1,3,3)
	imagesc(uma), axis equal off
	title('Reference image: Original dog')
