function [freq,uppc] = readTFfile(tffull)
%READTFFILE  Read a two-column transfer function file.
%
%   [freq,uppc] = readTFfile(tffull)
%
%   freq - frequency, Hz
%   uppc - [dB re uPa(rms)^2/counts^2]
%
%   The parsing and the duplicate-frequency cleanup that used to live
%   inside getTFx are here, so anything needing to read a .tf file gets
%   identical behaviour instead of a second copy of the same code.
%   getTFx now calls this after its file dialog.
%
%   KL 2026-08

fid = fopen(tffull,'r');
if fid < 0
    error('readTFfile:cannotOpen','Could not open transfer function:\n  %s',tffull);
end
[A,~] = fscanf(fid,'%f %f',[2,inf]);
fclose(fid);

if isempty(A)
    error('readTFfile:empty', ...
        'No freq/uppc pairs read from:\n  %s\nIs it a two-column .tf file?',tffull);
end

freq = A(1,:);
uppc = A(2,:);    % [dB re uPa(rms)^2/counts^2]

% collapse more than one measurement at the same frequency, and leave the
% result sorted ascending - interp1 downstream needs monotonic x, and a
% file that happens to be unsorted but has no duplicates would otherwise
% slip through unfixed
[ufreq,ia,ic] = unique(freq);
if length(ia) ~= length(ic)
    [~,nm,ex] = fileparts(tffull);
    fprintf(2,['Note: TF file %s%s has repeated frequencies - keeping the ', ...
        'first value at each\n'],nm,ex);
end
freq = ufreq;
uppc = uppc(ia);

if numel(freq) < 2
    error('readTFfile:tooFewPoints', ...
        'Only %d usable frequency point(s) in:\n  %s',numel(freq),tffull);
end
