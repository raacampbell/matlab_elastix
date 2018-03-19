function lenaTrans = distortLena(lena)
% function lenaTrans = distortLena(lena)	
%
%
% Distort lena

tform = affine2d([1 0 0; .35 1 0; 0 0 1]);
lenaTrans=imwarp(lena,tform);

%Horribly warp Lena using code from 
% http://blogs.mathworks.com/steve/2006/08/04/spatial-transformations-defining-and-applying-custom-transforms/
r = @(x) sqrt(x(:,1).^2 + x(:,2).^2);
w = @(x) atan2(x(:,2), x(:,1));

f = @(x) [r(x).^1.35 .* cos(w(x)), r(x).^1.35 .* sin(w(x))];
g = @(x, unused) f(x);

tform3 = maketform('custom', 2, 2, [], g, []);
lenaTrans = imtransform(lenaTrans, tform3, 'UData', [-1 1], 'VData', [-1 1], ...
    'XData', [-1 1], 'YData', [-1 1]);
