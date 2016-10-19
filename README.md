# MelastiX

![Transformix Results](https://raw.githubusercontent.com/raacampbell13/matlab_elastix/master/MelastiX_examples/transformix/dog_warp_results.png "Transformix Results")

## What is it?
MelastiX is a collection of MATLAB wrappers for the open source image registration suite [Elastix](http://elastix.isi.uu.nl/). Elastix is cross-platform and is normally called from the system command-line (no GUI). MelastiX allows the elastix and transformix binaries to be called from within MATLAB as though they are native MATLAB commands.

## What does it do?
1. The user can feed in MATLAB matrices instead of image file names and get a MATLAB matrix back as a result.
2. Parameters can be passed in as Elastix text files or as an MelastiX YAML file. The latter provides some error-checking options as the type and possible values of the parameters can be checked. 
3. Parameter files can be modified by passing an optional structure as a command-line argument. This makes it easy to explore how changing parameters affects registration accuracy. 
4. A function and example are provided to handle inverse transforms. 
5. Transforms sparse points. 
6. Handles both 2D and 3D data. Examples are only 2D, though.

## What does it not do?

At the moment MelastiX does not provide tools to:

1. Handle the mask option, thread option, and priority arguments for the elastix binary.
2. Handle multiple fixed and moving image in one elastix call.
3. Analyse transform parameters. 


## Getting started

1. Place the [Elastix](http://elastix.isi.uu.nl/) binaries in your *system* path. If you don't know how to do that, there's information here for [Windows](http://www.howtogeek.com/118594/how-to-edit-your-system-path-for-easy-command-line-access/) and [Linux](http://unix.stackexchange.com/questions/26047/how-to-correctly-add-a-path-to-path). 
2. Add the MelastiX *code* directory to your MATLAB path. 
3. Add <a href="https://github.com/ewiger/yamlmatlab">yamlmatlab</a> to your MATLAB path. 
4. Run the examples in MelastiX_examples. 

## What to do if the transform fails?
If you get unexpected results, first check whether the transform parameter file was written properly. If you are providing an Elastix parameter file and not modifying it then you should be fine. However, if you use the .yml approach or modify a parameter file using a structure then it's possible you've found a bug in the writing of the paramater file. To diagnose this, look at the written parameter file by calling elastix.m with a user-defined output path (so the files produced are not deleted)  or use the verbose option in <a href="https://github.com/raacampbell13/matlab_elastix/blob/master/elastix_paramStruct2txt.m">elastix_paramStruct2txt</a>. If you're *still* getting unexpected results then probably you have an issue with Elastix itself: please go the Elastix website for documentation or ask on their forum. 


## Related projects

1. <a href="https://sourcesup.renater.fr/elxfrommatlab/">ElastixFromMatlab toolbox</a>
2. <a href="http://elastix.bigr.nl/wiki/index.php/Matlab_interface">Elastix MATLAB interface</a>
