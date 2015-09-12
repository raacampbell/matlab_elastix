# MelastiX

![Transformix Results](https://raw.githubusercontent.com/raacampbell13/matlab_elastix/master/MelastiX_examples/transformix/dog_warp_results.png "Transformix Results")

## What is it?
MelastiX is a collection of wrappers for the open source image registration suite [Elastix](http://elastix.isi.uu.nl/). Elastix is cross-platform and is normally called from the system command-line (no GUI). MelastiX allows the elastix and transformix commands to be called from within MATLAB as though they are native MATLAB commands. This has the following advantages:

1. The user can feed in MATLAB matrices instead of image file names and get a MATLAB matrix back as a result.
2. Parameters can be passed in as Elastix text files or as an MelastiX YAML file. The latter provides some error-checking options as the type and possible values of the parameters can be checked. 
3. Parameter files can be modified by passing an optional structure as a command-line argument. This makes it easy to explore how changing parameters affects registration accuracy. 
4. Handles both 2D and 3D data. Examples are only 2D, though.

## What does it not do?
At the moment MelastiX does not provide tools to:

1. Transform sparse points with transformix
2. Perform inverse transforms
3. Analyse transform parameters. 

## Getting started
Install [Elastix](http://elastix.isi.uu.nl/). Add MelastiX directory to your path. Run the examples. 

## What to do if the transform fails?
If you get unexpected results, first check whether the transform parameter file was written properly. If you are providing an Elastix parameter file and not modifying it then you should be fine. However, if you use the .yml approach or modify a parameter file using a structure then it's possible you've found a bug in the writing of the paramater file. To diagnose this, look at the written parameter file or use the verbose option in <a href="https://github.com/raacampbell13/matlab_elastix/blob/master/elastix_paramStruct2txt.m">elastix_paramStruct2txt</a>. If you're *still* getting unexpected results then probably you have an issue with Elastix itself: please go the Elastix website for documentation or ask on their forum. 
