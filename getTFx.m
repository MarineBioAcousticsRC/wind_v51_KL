function [freq,uppc,tffull] = getTFx(TFsFolder,dlgNote)
%GETTFX  Pick and read a transfer function file.
%JAH streamlined pick TF
% Aug 2022
% KL 2026-08 - optional dlgNote so the dialog title says which hydrophone
%              number and deployment you are picking for. Called as
%              getTFx(folder) it behaves exactly as before.

if nargin < 2 || isempty(dlgNote)
    dlgTitle = 'Pick Transfer Function';
else
    dlgTitle = ['Pick Transfer Function:  ',dlgNote];
end

[tf_file, tf_pathname,~ ] = ...
    uigetfile('*.tf',dlgTitle,TFsFolder);

if isequal(tf_file,0)
    error('getTFx:noTFselected','No transfer function selected - stopping.');
end

disp([ 'Transfer function: ' tf_file  ]);
tffull = fullfile(tf_pathname, tf_file);

% parsing / dedup lives in readTFfile so CompareWindTFs and anything else
% reads .tf files exactly the same way
[freq,uppc] = readTFfile(tffull);
