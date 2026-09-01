function p = getWindParamsX(varargin)
% JAH 7/2021
drivelet = char(varargin{1,1});
% FILE PARAMETERS
p.harp.Proj = char(varargin{1,2});
p.harp.Site = char(varargin{1,3});
p.harp.Depl = char(varargin{1,4});
% 
p.calavgl = 'y'; % calculate LTSAl Average ? y or n othewise read in previous
p.calavgm = 'y'; % calculate LTSAm Average ? y or n othewise read in previous
p.calavg = 'y'; % calculate LTSA Average ? y or n othewise read in previous
%
p.usel = 'y'; % use low band data ~1kHz and 1 Hz bin
p.usem = 'y'; % use mid band data ~10kHz and 10 Hz bin
p.use = 'y'; % use full band data ~100kHz and 100 Hz bin
%
p.RegPlt = 'on'; % show regression plots off or on
p.FrePlt = 'on'; % show freq plots for each sea state off or on
p.NMPlt = 'on'; % show Noise Model plot for each sea state off or on
p.WndPlt = 'on'; % show wind speed plots for each frequency off or on
p.SaveTF = 'yes'; % save  new TF
p.tf.freq = [];
p.tf.uppc = [];
p.dEarly = datenum([2005 0 0 0 0 0]); %too early
p.dLate = datenum([2023 0 0 0 0 0]); % too late
%
p.harp.dBaseName = [p.harp.Proj,p.harp.Site,'_',p.harp.Depl] ;
% p.harp.harpDataSummaryCSV = 'L:\Shared drives\Wind_deltaTF\HARPdataSummaryWIND.csv';
% p.harp.harpDataSummaryCSV = [drivelet,':\Wind_TF\HARPdataSummaryWIND.csv'];
p.harp.harpDataSummaryCSV = [drivelet,':\Shared drives\Wind_deltaTF\HARPdataSummaryWIND.csv'];
p.harp.harpDataSummary = readtable(p.harp.harpDataSummaryCSV);
p.harp.WindFolder = [drivelet,':\Shared drives\Wind_deltaTF\Wind_Data\',p.harp.Proj,'\'];
% p.ltsa.LTSAFolder = [drivelet,':\LTSA\',p.harp.Proj,'\',p.harp.Proj,...
%     '_',p.harp.Site,'_',p.harp.Depl];
p.ltsa.LTSAFolder = fullfile('\\frosty','LTSA',p.harp.Proj);
p.tf.TFsFolder = [drivelet,':\Shared drives\MBARC_TF'];
% p.tf.TFsFolder = [drivelet,':\Wind_TF\Output\Kona_TF\TF_Wind']; %uses wind TF
% p.tf.TFsFolder = [drivelet,':\Shared drives\GOM_Pm_Density\NewTFs_2022']; %Kait TF
p.tf.TFsFolderOld = [drivelet,':\Shared drives\MBARC_TF'];
% p.tf.TFsFolderOld = [drivelet,':\Harp_TF\OLD\'];
p.harp.OutFolder = [drivelet,':\Shared drives\Wind_deltaTF\All3_TF'];
p.harp.OutWinFig = [drivelet,':\Shared drives\Wind_deltaTF\All3_TF\VsFreqVsWind\']; % Directory for files
p.harp.OutBad =  [drivelet,':\Shared drives\Wind_deltaTF\All3_TF\BAD'];
p.harp.Short = p.harp.Depl;
%
p.harp.NA = 5;     % number of time slices (spectral averages) to read per raw file
p.harp.tres = 2;   % time bin resolution 0 = month, 1 = days, 2 = hours
%
p.harp.OutName = [p.harp.dBaseName,'_WindNoise.mat'];
p.harp.OutNamem = [p.harp.dBaseName,'_WindNoise_mid.mat'];
p.harp.OutNamel = [p.harp.dBaseName,'_WindNoise_low.mat'];
p.harp.OutVsFreq = [p.harp.dBaseName,'_VsFreq.fig'];
p.harp.OutVsFreqm = [p.harp.dBaseName,'_VsFreqm.fig'];
p.harp.OutVsFreql = [p.harp.dBaseName,'_VsFreql.fig'];
p.harp.OutVsWind = [p.harp.dBaseName,'_VsWind.fig'];
p.harp.OutVsWindm = [p.harp.dBaseName,'_VsWind_mid.fig'];
p.harp.OutVsWindl = [p.harp.dBaseName,'_VsWind_low.fig'];
p.harp.OutTFCorr = [p.harp.dBaseName,'_TFCorr.mat']; % mid and low are made in WindLTSA
