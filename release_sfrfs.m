% build_release.m
% Script to package the SFRFS Toolbox and place the .mltbx file in the dist/ folder

% Define the .prj file and output .mltbx file
prjFile = 'sfrfs-toolbox.prj';
outputFile = fullfile('dist', 'sfrfs.mltbx');

% Ensure the dist/ folder exists
if ~exist('dist', 'dir')
    mkdir('dist');
end

% Package the toolbox
matlab.addons.toolbox.packageToolbox(prjFile, outputFile);

disp('SFRFS Toolbox packaged successfully!');

