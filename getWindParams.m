function p = getWindParams(varargin)
% JAH 7/2021
drivelet = char(varargin{1,1});
% FILE PARAMETERS
p.harp.Proj = char(varargin{1,2});
p.harp.Site = char(varargin{1,3});
p.harp.Depl = char(varargin{1,4});
% 
p.calavgl = 'n'; % calculate LTSAl Average ? y or n othewise read in previous
p.calavgm = 'y'; % calculate LTSAm Average ? y or n othewise read in previous
p.calavg  = 'y'; % calculate LTSA Average ? y or n othewise read in previous
%
p.usel = 'n'; % use low band data ~1kHz and 1 Hz bin
p.usem = 'y'; % use mid band data ~10kHz and 10 Hz bin
p.use = 'y'; % use full band data ~100kHz and 100 Hz bin
%
p.ice = ''; % use data on ice to segregate data
p.icethres = 20; % percent ice coverage threshold
%
p.usek = 'n'; % add Kait TF to upper frequencies
%
p.RegPlt = 'on'; % show regression plots off or on
p.FrePlt = 'on'; % show freq plots for each sea state off or on
p.NMPlt = 'on'; % show Noise Model plot for each sea state off or on
p.WndPlt = 'on'; % show wind speed plots for each frequency off or on
p.SaveTF = 'yes'; % save  new TF
p.tf.freq = [];
p.tf.uppc = [];
% Data outside this window is discarded by calLTSA*51.m. NOTE datenum with
% month/day = 0 rolls BACKWARDS: datenum([2026 0 0]) is 30-Nov-2025, not
% 2026. Written explicitly here so the cutoff is what it looks like.
p.dEarly = datenum(2005,1,1);   %too early
p.dLate  = datenum(2030,1,1);   % too late % kl changed 260623

%
p.harp.dBaseName = [p.harp.Proj,p.harp.Site,'_',p.harp.Depl] ;
p.harp.harpDataSummaryCSV = [drivelet,':\Wind_deltaTF\HARPdataSummaryWIND.csv']; % kl changed 260623
p.harp.harpDataSummary = readtable(p.harp.harpDataSummaryCSV);
p.harp.WindFolder = [drivelet,':\Wind_deltaTF\Wind_Data\',p.harp.Proj,'\'];% kl changed 260623

%% ------------------------- WIND SOURCE -------------------------------
% CCMP model wind is THE default and the norm for every site. It is found
% automatically under p.harp.WindFolder using the standard naming:
%     <WindFolder>\<year>\<Proj><Site>windvec.mat   (and 3 name variants)
%     <WindFolder>\<Proj><Site>windvec.mat           (all-years products)
%
% loadWindData.m will ONLY auto-accept a file that (a) sits in one of those
% canonical locations, (b) actually contains data for the year being asked
% for, and (c) is not inside a quarantine subfolder such as
% "potentially_incorrect". Anything else and it stops and asks you to pick
% the file by hand - it will never substitute a file it is not sure about.
%
% p.windfile : optional. Explicit full paths to wind .mat files, used ahead
%              of the automatic search. Each entry is matched to a year by
%              the data it holds, not by its position in the cell, so the
%              order does not matter. Leave empty for normal CCMP runs; set
%              it only to pin a one-off source (e.g. an NDBC buoy file from
%              WindTimeSeries_NDBC.m) without clicking through the dialog
%              every run. Files must contain dnvec (datenum) and wspeed.
%
%              p.windfile{1,1} = 'Z:\...\2022\SOCALBwindvec.mat';
%
% Whatever is loaded, loadWindData reads stationID/buoyLat/buoyLon out of
% the file when present and prints whether it is model or buoy data, so a
% one-off substitution cannot be mistaken for CCMP later.
p.windfile = cell(6,1); % assume 2 yr * 3 max, best to leave this

% Minimum matched wind/noise points before a fit is trusted. createFit4 and
% createFit5 use poly5, which cannot fit fewer than 6 at all; between 6 and
% this value you get a warning rather than a stop.
p.minFitPts = 20;

p.ltsa.LTSAFolder = 'E:\LTSAs'; %fullfile('\\frosty','LTSA',p.harp.Proj);
p.tf.TFsFolder = 'G:\Shared drives\MBARC_TF';% kl changed 260623
p.tf.KTFsFolder = [drivelet,':\Shared drives\GOM_Pm_Density\NewTFs_2022']; %Kait TF
p.tf.TFsFolderOld = [drivelet,':\Shared drives\MBARC_TF'];% kl changed 260623
% p.harp.OutFolder = [drivelet,':\Shared drives\Wind_deltaTF\All3_TF'];
% p.harp.OutWinFig = [drivelet,':\Shared drives\Wind_deltaTF\All3_TF\VsFreqVsWind\']; % Directory for files
% p.harp.OutBad =  [drivelet,':\Shared drives\Wind_deltaTF\All3_TF\BAD'];

outputBase = 'G:\Shared drives\MBARC_Engineering\Hydrophone_Lab\wind\HARPs'; % Directory for output files - just change here 
% outputBase = 'G:\Shared drives\MBARC_Engineering\Hydrophone_Lab\MARPs\windResults\RevC\WindCheckOutput'; % Directory for output files - just change here - Rev C
p.harp.OutFolder = outputBase; 
p.harp.OutWinFig = [outputBase,'\VsFreqVsWind\']; 
p.harp.OutBad =  [outputBase,'\BAD'];
p.harp.OutLog =  fullfile(outputBase,'RunLogs'); % command window diaries
p.harp.Short = p.harp.Depl;
%
p.icepath = 'D:\Ice_wind\data\SPIRE_2023_evaluationSet'; %location of ice data cvs files 
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
