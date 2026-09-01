% Compare Wind to LSTA
% JAH 10/2019
% derived from LTSAdailySpectra.m
% 141103 smw
clear variables
calavg = 'no'; % calculate LTSA Average ? yes or no othewise read in previous
RegPlt = 'on'; % show regression plots off or on
FrePlt = 'on'; % show freq plots for each sea state off or on
WndPlt = 'on'; % show wind speed plots for each frequency off or on
global PARAMS
PARAMS.harp.Proj = 'GofAK';
PARAMS.harp.Site = 'PT';
PARAMS.harp.Depl = '01';
PARAMS.harp.Short = '01';
PARAMS.harp.band = 'high'; % high mid or low
PARAMS.harp.harpDataSummaryCSV = 'H:\Wind_TF\Code\HARPdataSummary.csv';
PARAMS.harp.harpDataSummary = readtable(PARAMS.harp.harpDataSummaryCSV);
PARAMS.harp.WindFolder = ['H:\Wind_Data\',PARAMS.harp.Proj,'\'];
PARAMS.ltsa.LTSAFolder = ['G:\LTSA\',PARAMS.harp.Proj,'\',PARAMS.harp.Site];
PARAMS.tf.TFsFolder = 'H:\Harp_TF\';
PARAMS.tf.TFsFolderOld = 'H:\Harp_TF\OLD\';
PARAMS.harp.OutFolder = 'H:\Wind_TF\Output';
rm_fifo = 0;    % remove FIFO via interpolation on spectra. 0=no, 1=yes
% fsflag = 1;     % sample rate flag for FIFO removal 1=80kHz, 0=all other
PARAMS.harp.NA = 5;     % number of time slices (spectral averages) to read per raw file
PARAMS.harp.tres = 2;   % time bin resolution 0 = month, 1 = days, 2 = hours
%
PARAMS.harp.OutName1 = [PARAMS.harp.Proj,PARAMS.harp.Site,PARAMS.harp.Depl,...
    '_WindNoise','.mat'];
PARAMS.harp.OutName2 = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_WindNoise','.mat'];
if strcmp(calavg,'yes') % calculate WindNoise.mat file ?
    calLTSA;  % reads LTSA files to get averages and gets Wind model
end
%
% load WindNoise.mat file either newly created or previously stored
if exist(fullfile(PARAMS.harp.OutFolder,PARAMS.harp.OutName1))
    load(fullfile(PARAMS.harp.OutFolder,PARAMS.harp.OutName1));
elseif exist(fullfile(PARAMS.harp.OutFolder,PARAMS.harp.OutName2))
    load(fullfile(PARAMS.harp.OutFolder,PARAMS.harp.OutName2));
else
    disp('No existing WindNoise file')
    return
end
%
eltsam = unique(eltsam);
%Identify times with Bite Swapped Data
if tfn > 499  && fs0 > 100000 % skip for old TF or decimated data
    inbs = find(((mpwr(300,:) - mpwr(600,:))) < 5 );  %JAH to remove Bswap data
    ibs = setxor([1:length(mpwr)],inbs);
    ibscount = 0; anygood = 0;
    for i = 1:fnum
        ibscount = find(ibs > eltsam(i) & ibs < eltsam(i+1));
        if (length(ibscount) > .5 * ( eltsam(i+1) - eltsam(i)))
            disp([fn_files{i},' WARNING BYTE SWAPPED DATA REMOVED']);
        else
            anygood = 1;
        end
        ibscount = 0;
    end
    if anygood == 0
        disp([dBaseName,'   WARNING ALL DATA BYTE SWAPPED']);
        return
    end
    %Remove outlier / low noise data
    ptime = ptime(inbs);
    mpwr = mpwr(:,inbs);
    mpwrtf = mpwrtf(:,inbs);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clean Data then compare to Noise Model
% %JAH HACK to remove bad data
if fs0 == 200000
    isok = find( mpwrtf(101,:) > 30 & mpwrtf(101,:) < 65); %10kHz = 100 * 100
elseif fs0 == 10000
    isok = find( mpwrtf(11,:) > 40 & mpwrtf(11,:) < 90); %100 Hz = 10 * 10
else
    disp('Add New Sample Rate')
    return
end
ptime = ptime(isok);
mpwr = mpwr(:,isok);
mpwrtf = mpwrtf(:,isok);
% reduce sig figures to make times match, accurate to ~ 7 min
xp = round(ptime .* 100)./100;
xw = round(dnew' .* 100)./100;
[~,inoise,iwind] = intersect(xp,xw);
Wfig = figure; % Wind versus Noise plot
if fs0 == 200000
    plot(wsnew(iwind),mpwrtf(11,inoise),'o') %use 1 kHz noise
    hold on
    plot(wsnew(iwind),mpwrtf(101,inoise),'ro') %use 10 kH
    legend('1 kHz','10 kHz','Location','southeast');
elseif fs0 == 10000
    plot(wsnew(iwind),mpwrtf(11,inoise),'o') %use 100 Hz noise
    hold on
    plot(wsnew(iwind),mpwrtf(51,inoise),'ro') %use 500 Hz
    legend('100 Hz','500 Hz','Location','southeast');
end
xlabel('Wind Speed m/s');
ylabel('Pressure Spectrum Level [dB re uPa^2/Hz]');
title([dBaseName,'Noise vs Wind Speed']);
%save wind vs noise figure
wnfigname = fullfile(WindFolder,'WindvsNoise',[dBaseName,'WindNoise']);
savefig(Wfig,wnfigname)
%sort into speed bins
force1 = find(wsnew(iwind) > 0.3 & wsnew(iwind) <= 1.6);
MPTF{1} = mpwrtf(:,inoise(force1));
force2 = find(wsnew(iwind) > 1.6 & wsnew(iwind) <= 3.4);
MPTF{2} = mpwrtf(:,inoise(force2));
force3 = find(wsnew(iwind) > 3.4 & wsnew(iwind) <= 5.5);
MPTF{3} = mpwrtf(:,inoise(force3));
force4 = find(wsnew(iwind) > 5.5 & wsnew(iwind) <= 8.0);
MPTF{4} = mpwrtf(:,inoise(force4));
force5 = find(wsnew(iwind) > 8.0 & wsnew(iwind) <= 10.8);
MPTF{5} = mpwrtf(:,inoise(force5));
force6 = find(wsnew(iwind) > 10.8 & wsnew(iwind) <= 13.9);
MPTF{6} = mpwrtf(:,inoise(force6));
force7 = find(wsnew(iwind) > 13.9 & wsnew(iwind) <= 17.2);
MPTF{7} = mpwrtf(:,inoise(force7));
force8 = find(wsnew(iwind) > 17.2 & wsnew(iwind) <= 20.8);
MPTF{8} = mpwrtf(:,inoise(force8));
force9 = find(wsnew(iwind) > 20.8 & wsnew(iwind) <= 24.5);
MPTF{9} = mpwrtf(:,inoise(force9));
force10 = find(wsnew(iwind) > 24.5 & wsnew(iwind) <= 28.5);
MPTF{10} = mpwrtf(:,inoise(force10));
force11 = find(wsnew(iwind) > 28.5 & wsnew(iwind) <= 32.7);
MPTF{11} = mpwrtf(:,inoise(force11));
force12 = find(wsnew(iwind) > 32.7 );
MPTF{12} = mpwrtf(:,inoise(force12));
%
% Ocean Wind Noise Model
[kd,ss,fnm,ms] = NoiseModel(depth);  %kd is noise level
% plot Knudsen curves
if strcmp(FrePlt,'on')
    iplot = 1;
    ssfig = figure;
    subplot(3,3,iplot) % first of tiled plot
    for i = 1: length(ms)
        semilogx(1000*fnm, kd(i,:),'k','LineWidth',2);
        if i == 1
            hold on
        end
    end
    i=5;
    semilogx(1000*fnm, kd(i,:),'r','LineWidth',2); % ss = 4 is log10(ms) = 1
    % Thermal Noise curve
    for iif = 1:length(fnm)
        nt(iif) = -15 + 20 * log10(fnm(iif));
    end
    semilogx(1000*fnm, nt,'k','LineWidth',2);
    axis([100,100000,10,95]);
    xlabel('Frequency [Hz]')
    ylabel('dB re uPa^2/Hz')
    title(['Noise Model for ',num2str(depth),' m depth'])
    grid on
    hold on
end
% Theory is f starts with 100
% Data is freq starts with 0
itf = 1;
TFCorr = zeros(8,300);
for  i = 2 : 9    % start at i = 2 ss1 end i=9 ss8
    if ~isempty(MPTF{i})
        smptf = size((MPTF{i}(2:301,:)')); % 100 Hz to 30 kHz
        if smptf(1) > 1
            AM = mean(MPTF{i}(2:301,:)');
        elseif smptf(1) == 1
            AM = MPTF{i}(2:301,:)';
        end
        TFCorr(itf,:) = kd(i,1:300) - AM; % first value is 100 Hz
        itf = itf + 1;
        if strcmp(FrePlt,'on')
            figure(ssfig);
            iplot = iplot + 1;
            subplot(3,3,iplot)  % 9 subplots = 3 x 3
            semilogx(freq(2:301),MPTF{i}(2:301,:)); % from 100 Hz to 100 kHz
            hold on
            semilogx(freq(2:301),AM,'r','LineWidth',3); % from 100 Hz to 100 kHz
            semilogx(freq(2:301),kd(i,1:300),'k','LineWidth',3); % theory as a line
            xlabel('Frequency [Hz]')
            ylabel('dB re uPa^2/Hz')
            grid on
            title(['Sea State' ,num2str(ss(i))]);
            v = [100 3e4 25 90];
            axis(v)
        end
    end
end
% REgress
[SlopeLR,OffSetLR,SlopeTS,OffSetTS,~] = WNRegress(...
    Proj,Site,Depl,depth,wsnew,mpwrtf,ptime,dnew,kd,ms,fs0,RegPlt);
%
% Make TF Correction
MTFCorr = mean(TFCorr);  %starts with freq = 100 Hz
nMT = isnan(MTFCorr); % correct Nan
inMT = find(nMT > 0);
if (~isempty(inMT))
    for i = 1 : length(inMT)
        MTFCorr(inMT(i))=(MTFCorr(inMT(i)-1)+MTFCorr(inMT(i)+1))/2 ;
    end
end
figure
semilogx(freq(2:301),MTFCorr(1:300),'r','LineWidth',3); %
v = [500 2e4 -5 5];
axis(v)
grid on
hold on
% Make New TF
% MAKE TF CORRECTION > 500 Hz < 20 kHz
% note freq = (count -1)*100 Hz
revise = 'y';
col = floor(500/100);  % 500 Hz start
coh = floor(20000/100);  % mod tf cutoff frequencies in Hz
while strcmp(revise,'y')
    iPtf = find(PARAMS.tf.freq > 0 & PARAMS.tf.freq < 100); % part below 100Hz
    miP = max(iPtf);
    TFnew = [PARAMS.tf.freq(iPtf)',PARAMS.tf.uppc(iPtf)'];% adds < 500 Hz data
    TFnew(miP+1:miP+1000,:) = [freq(2:1001)',Ptf(2:1001)']; %  100 Hz - 100 kHz
    TFold = TFnew;
    TFnew(1:miP,2) = TFnew(1:miP,2) + MTFCorr(col); % for < 500 Hz
    TFnew(miP+1:miP+col-1,2) = TFnew(miP+1:miP+col-1,2) + MTFCorr(col); % for 100 Hz - 400 Hz
    TFnew(miP+col:miP+coh,2) = TFnew(miP+col:miP+coh,2) + MTFCorr(col:coh)'; % for 500 Hz - 20 kHz
    TFnew(miP+coh+1:end,2) = TFnew(miP+coh+1:end,2) + MTFCorr(coh); % for > 20 kHz
    %Make TF Figure
    TFFig = figure;
    semilogx(TFnew(:,1),TFnew(:,2),'r','LineWidth',3); %
    hold on
    semilogx(TFold(:,1),TFold(:,2),'k','LineWidth',3); %
    legend('NewTF','OldTF');
    title([dBaseName,' Hydrophone ',tf_file(1:3)])
    xlabel('Frequency [Hz]')
    ylabel('Inverse Sensitivity [dB re uPa//counts]')
    grid on
    revise = input('Revise TF cutoff - y or n:  ','s');
    if strcmp(revise,'y')
        cutlow = input('Low cutoff Hz: ');
        col = floor(cutlow/100);
        cuthigh = input('High cuttoff Hz: ');
        coh = floor(cuthigh/100);
    end
end
%
% save in inverse sensitivity tf format in original TF Folder
tfnewfile = fullfile(tf_pathname,...
    [tf_file(1:3),'_',Proj,Site,Depl,'_TFnew.tf']);
save(tfnewfile,'TFnew','-ascii','-tabs');
tfnewfig = fullfile(tf_pathname,...
    [tf_file(1:3),'_',Proj,Site,Depl,'_TFnewfig']);
savefig(TFFig,tfnewfig)
tfnewfigpdf = fullfile(tf_pathname,...
    [tf_file(1:3),'_',Proj,Site,Depl,'_TFnewfig.pdf']);
saveas(TFFig,tfnewfigpdf)
% Another copy in TF_Wind Folder
tfnewfile = fullfile(TFsFolder,'TF_Wind',...
    [tf_file(1:3),'_',Proj,Site,Depl,'_TFnew.tf']);
save(tfnewfile,'TFnew','-ascii','-tabs');
tfnewfig = fullfile(TFsFolder,'TF_Wind',...
    [tf_file(1:3),'_',Proj,Site,Depl,'_TFnewfig']);
savefig(TFFig,tfnewfig)
tfnewfigpdf = fullfile(TFsFolder,'TF_Wind',...
    [tf_file(1:3),'_',Proj,Site,Depl,'_TFnewfig.pdf']);
saveas(TFFig,tfnewfigpdf)
% end
t = toc;
disp(' ')
disp(['Time Elapsed: Spectra from LTSA ', num2str(t),' secs'])
