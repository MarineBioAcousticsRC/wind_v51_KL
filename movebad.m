function [stat1,stat2,stat3,stat4] = movebad(wnfile,ssfile,wnfignam )
%move wind files to the "BAD' directory
%Jah 12-2021
global p
%
wnfilebad = fullfile(p.harp.OutFolder,'BAD',p.harp.OutName);
[stat1,~,~] = movefile(wnfile,wnfilebad);
ssfilebad = fullfile(p.harp.OutBad,p.harp.OutVsFreq);
[stat2,~,~] = movefile(ssfile,ssfilebad);
VsWindfile = fullfile(p.harp.OutFolder,'VsFreqVsWind',p.harp.OutVsWind);
VsWindfilebad = fullfile(p.harp.OutBad,p.harp.OutVsWind);
[stat3,~,~] = movefile(VsWindfile,VsWindfilebad);
wnfignambad = fullfile(p.harp.OutBad,[p.harp.dBaseName,'WindNoise']);
[stat4,~,~] = movefile([wnfignam,'.fig'],wnfignambad);