function [kaitFr,kaitTF] = getKTF(KTFsFolder,dlgNote)
% find TF number from XLS and then read in TF
% KL 2026-08 - optional dlgNote for the dialog title.

if nargin < 2 || isempty(dlgNote)
    dlgTitle = 'Pick Kait Transfer Function';
else
    dlgTitle = ['Pick Kait Transfer Function:  ',dlgNote];
end

% get Kait TF
[Ktf_file, Ktf_pathname,~ ] = ...
    uigetfile('*.tf',dlgTitle,KTFsFolder);

if isequal(Ktf_file,0)
    error('getKTF:noTFselected','No Kait transfer function selected - stopping.');
end

disp([ 'Transfer function: ' Ktf_file  ]);
Ktf = fullfile(Ktf_pathname, Ktf_file);

fid = fopen(Ktf,'r');
if fid < 0
    error('getKTF:cannotOpen','Could not open:\n  %s',Ktf);
end
[A,~] = fscanf(fid,'%f %f',[2,inf]);
kaitFr = A(1,:);
kaitTF = A(2,:);    % [dB re uPa(rms)^2/counts^2]

fclose(fid);
