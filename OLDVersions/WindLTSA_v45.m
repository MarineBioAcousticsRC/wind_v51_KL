% Compare Wind to LSTA - SINGLE DEPLOYMENT
% v45 - add mid band  11/2020
% JAH 10/2019
% derived from LTSAdailySpectra.m
% 141103 smw
clear variables
calavg = 'n'; % calculate LTSA Average ? y or n othewise read in previous
RegPlt = 'on'; % show regression plots off or on
FrePlt = 'on'; % show freq plots for each sea state off or on
WndPlt = 'on'; % show wind speed plots for each frequency off or on
SaveTF = 'yes'; % save  new TF
revise = 'r'; % allow revision of TF cutoff frequencies
addmid = 'yes'; % add mid frequency data
global PARAMS
PARAMS.harp.Proj = 'SOCAL';
% PARAMS.harp.Proj = 'Antarc';
% PARAMS.harp.Proj = 'GofAK';
% PARAMS.harp.Proj = 'OTSG';
% PARAMS.harp.Proj = 'OCNMS';
PARAMS.harp.Proj = 'WAT';
% PARAMS.harp.Proj = 'GofCA';
% PARAMS.harp.Proj = 'Hawaii';
% PARAMS.harp.Site = 'CB';
PARAMS.harp.Site = '_CINMS_C';
PARAMS.harp.Site = 'HATB';
% PARAMS.harp.Site = 'USWTRD';
PARAMS.harp.Depl = '04';
PARAMS.harp.Short = PARAMS.harp.Depl;
PARAMS.harp.band = 'high'; %  high mid or low
PARAMS.harp.harpDataSummaryCSV = 'F:\Shared drives\Wind_deltaTF\HARPdataSummaryWIND.csv';
%PARAMS.harp.harpDataSummaryCSV = 'H:\Wind_TF\Code\HARPdataSummaryWIND.csv';
% PARAMS.harp.harpDataSummaryCSV = 'H:\Wind_TF\Code\HARPdataSummarySOCALB.csv';
PARAMS.harp.harpDataSummary = readtable(PARAMS.harp.harpDataSummaryCSV);
PARAMS.harp.WindFolder = ['H:\Wind_Data\',PARAMS.harp.Proj,'\'];
PARAMS.ltsa.LTSAFolder = ['J:\LTSA\',PARAMS.harp.Proj,'\',PARAMS.harp.Site];
PARAMS.tf.TFsFolder = 'F:\Shared drives\MBARC_TF';
PARAMS.tf.TFsFolderOld = 'H:\Harp_TF';
% PARAMS.tf.TFsFolderOld = 'H:\Harp_TF\OLD\';
PARAMS.harp.OutFolder = 'H:\Wind_TF\Output\newest_TF';
OutFolder = 'H:\Wind_TF\Output\newest_TF';
rm_fifo = 0;    % remove FIFO via interpolation on spectra. 0=no, 1=yes
% fsflag = 1;     % sample rate flag for FIFO removal 1=80kHz, 0=all other
PARAMS.harp.NA = 5;     % number of time slices (spectral averages) to read per raw file
PARAMS.harp.tres = 2;   % time bin resolution 0 = month, 1 = days, 2 = hours
%
PARAMS.harp.OutName1 = [PARAMS.harp.Proj,PARAMS.harp.Site,PARAMS.harp.Depl,...
    '_WindNoise.mat'];
PARAMS.harp.OutName2 = [PARAMS.harp.Proj,PARAMS.harp.Site,PARAMS.harp.Depl,...
    '_WindNoise_mid.mat'];
OutWinFig = ['H:\Wind_TF\Output\newest_TF\VsFreqVsWind\'];
OutVsFreq = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_VsFreq.fig'];
OutVsWind1 = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_VsWind.fig'];
OutVsWind2 = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_VsWind_mid.fig'];
OutTFCorr = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_TFCorr.mat'];
OutBad =  ['H:\Wind_TF\Output\newest_TF\BAD'];

%% calculate or load WindNoise.mat
if strcmp(calavg,'y') % calculate WindNoise.mat file ?
    calLTSA;  % reads LTSA files to get averages and gets Wind model
end
% if mid exists load it
if exist(fullfile(PARAMS.harp.OutFolder,'WindNoiseMat',PARAMS.harp.OutName2))
    load(fullfile(PARAMS.harp.OutFolder,'WindNoiseMat',PARAMS.harp.OutName2));
    PARAMS.harp.band = 'mid'; % 
else
    disp('No existing Mid WindNoise file')
    return
end
% load WindNoise.mat file either newly created or previously stored
if exist(fullfile(PARAMS.harp.OutFolder,'WindNoiseMat',PARAMS.harp.OutName1))
    load(fullfile(PARAMS.harp.OutFolder,'WindNoiseMat',PARAMS.harp.OutName1));
else
    disp('No existing High WindNoise file')
    return
end
% Correct Outfolder
PARAMS.harp.OutFolder = 'H:\Wind_TF\Output\newest_TF';
OutFolder = 'H:\Wind_TF\Output\newest_TF';
PARAMS.harp.band = 'mid'; % high mid or low
OutWinFig = ['H:\Wind_TF\Output\newest_TF\VsFreqVsWind\'];
OutVsFreq = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_VsFreq.fig'];
OutVsWind1 = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_VsWind.fig'];
OutVsWind2 = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_VsWind_mid.fig'];
OutTFCorr = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_TFCorr.mat'];
OutBad =  ['H:\Wind_TF\Output\newest_TF\BAD'];
%
eltsam = unique(eltsam);
%% Make Wind vs Noise plots for cleaning data
if exist('freqm','var')
    dfreqm = 10;
    iffif = find(freqm < 50 + dfreqm/2 & freqm > 50 - dfreqm/2); % 50 Hz
    ifhun = find(freqm < 100 + dfreqm/2 & freqm > 100 - dfreqm/2); % 100 Hz
end
if fs0 == 200000 ||  fs0 == 320000 || fs0 == 64000 || ...
        fs0 == 96000 || fs0 == 50000 || fs0 == 48000
    iffiv = find(freq < 500 + dfreq/2 & freq > 500 - dfreq/2); % 500 Hz
    ifone = find(freq < 1000 + dfreq/2 & freq > 1000 - dfreq/2); % 1Khz
    iften = find(freq < 10000 + dfreq/2 & freq > 10000 - dfreq/2); % 10Khz
    iftwe = find(freq < 20000 + dfreq/2 & freq > 20000 - dfreq/2); % 20Khz
elseif fs0 == 10000 || fs0 == 20000 || fs0 == 24000
    iffiv = find(freq < 500 + dfreq/2 & freq > 500 - dfreq/2); % 500 Hz
    ifone = find(freq < 1000 + dfreq/2 & freq > 1000 - dfreq/2); % 1Khz
else
    disp('Add New Sample Rate')
    return
end
% reduce sig figures to make times match, accurate to ~ 7 min
xp = round(ptime .* 100)./100;
xpm = round(ptimem .* 100)./100;
xw = round(dnew' .* 100)./100;
[~,inoise,iwind] = intersect(xp,xw);
[~,inoisem,iwindm] = intersect(xpm,xw);
% make figures
isok = cell(1,6); % array to hold edited data
figure(2); clf; set(2,'name',sprintf('Wind vs Noise'));
set(gcf,'position',[20 500 600 450]);
h1 = subplot(3,2,1);
plot(h1,wsnew(iwindm),mpwrtfm(iffif,inoisem),'ro'); %use 50 Hz
legend(h1,'50 Hz','Location','southeast');
grid on; hold on;
[isok{1,1}] = createFit4(wsnew(iwindm),mpwrtfm(iffif,inoisem),...
    wsnew(iwindm),mpwrtfm(iffif,inoisem),h1 );
%
h2 = subplot(3,2,2);
plot(h2,wsnew(iwindm),mpwrtfm(ifhun,inoisem),'ro'); %use 500 Hz
legend(h2,'100 Hz','Location','southeast');
grid on; hold on;
[isok{1,2}] = createFit4(wsnew(iwindm),mpwrtfm(ifhun,inoisem),...
    wsnew(iwindm),mpwrtfm(ifhun,inoisem),h2 );
%
h3 = subplot(3,2,3);
plot(h3,wsnew(iwind),mpwrtf(iffiv,inoise),'ro'); %use 500 Hz
legend(h3,'500 Hz','Location','southeast');
grid on; hold on;
[isok{1,3}] = createFit4(wsnew(iwind),mpwrtf(iffiv,inoise),...
    wsnew(iwind),mpwrtf(iffiv,inoise),h3 );
%
h4 = subplot(3,2,4);
plot(h4,wsnew(iwind),mpwrtf(ifone,inoise),'ro');%use 1 kH
legend(h4,'1 kHz','Location','southeast');
grid on; hold on;
[isok{1,4}] = createFit4(wsnew(iwind),mpwrtf(ifone,inoise),...
    wsnew(iwind),mpwrtf(ifone,inoise),h4 );

if fs0 ==  320000 || fs0 ==  200000 || fs0 == 96000 || ...
        fs0 == 64000 || fs0 == 50000 || fs0 == 48000
    h5 = subplot(3,2,5);
    plot(h5,wsnew(iwind),mpwrtf(iften,inoise),'ro');%use 10 kH
    legend(h5,'10 kHz','Location','southeast');
    grid on; hold on;
    [isok{1,5}] = createFit4(wsnew(iwind),mpwrtf(iften,inoise),...
        wsnew(iwind),mpwrtf(iften,inoise),h5 );
    %
    h6 = subplot(3,2,6);
    plot(h6,wsnew(iwind),mpwrtf(iftwe,inoise),'ro');%use 20 kH
    legend(h6,'20 kHz','Location','southeast');
    grid on; hold on;
    [isok{1,6}] = createFit4(wsnew(iwind),mpwrtf(iftwe,inoise),...
        wsnew(iwind),mpwrtf(iftwe,inoise),h6 );
end
subplot(3,2,1)
xlabel('Wind Speed m/s');
ylabel('Spectrum Level [dB re uPa^2/Hz]');
title([dBaseName,'Noise vs Wind Speed']);
%% Eliminate Bad Points in Noise vs wind Plots
% editing based on function selectdata
if ~exist('zTD','var')
    % overlap of all except 50 Hz and 100 Hz
    zTD = mintersect(isok{1,3}, isok{1,4}, isok{1,5}, isok{1,6});
else
    disp('using existing zTD')
end
if ~exist('zTDm','var')
    % overlap of 50 Hz and 100 Hz
    zTDm = mintersect(isok{1,1}, isok{1,2});
else
    disp('using existing zTDm')
end
disp('Done with cleaning');
revise = 'd';
while strcmp(revise,'d')
    wnfile = fullfile(PARAMS.harp.OutFolder,'WindNoiseMat',PARAMS.harp.OutName1);
    save(wnfile) % save all workspace
    wsfinal = wsnew(iwind(zTD));
    mpwfinal = mpwrtf(:,inoise(zTD));
    wsfinalm = wsnew(iwindm(zTDm));
    mpwfinalm = mpwrtfm(:,inoisem(zTDm));
    figure(3); clf;
    plot(wsfinal',mpwfinal(iffiv,:),'ko'); %use 1 kHz noise
    hold on
    plot(wsfinal',mpwfinal(ifone,:),'bo'); %use 1 kHz noise
    plot(wsfinal,mpwfinal(iften,:),'ro'); %use 1 %use 10 kH
    plot(wsfinal,mpwfinal(iftwe,:),'go'); %use 1 %use 20 kH
    legend('500 Hz','1 kHz','10 kHz','20 kHz','Location','northwest');
    figure(5); clf;
    plot(wsfinalm',mpwfinalm(iffif,:),'ko'); %use 50 Hz noise
    hold on
    plot(wsfinalm',mpwfinalm(ifhun,:),'bo'); %use 100Hz noise
    legend('50 Hz','100 Hz','Location','southeast');
    %% save wind vs noise figure
    %wnfigname = fullfile(WindFolder,'WindvsNoise',[dBaseName,'WindNoise']);
    wnfignam2 = fullfile(OutWinFig,[dBaseName,'WindNoisefit']);
    figure(2);
    savefig(wnfignam2)
    wnfignam3 = fullfile(OutWinFig,[dBaseName,'WindNoise']);
    figure(3);
    savefig(wnfignam3)
    wnfignam5 = fullfile(OutWinFig,[dBaseName,'WindNoise_mid']);
    figure(5);
    savefig(wnfignam5)
    %sort into speed bins
    [MPTF] = WindSort(wsfinal,mpwfinal); % Mean Pressure TF corrected
    [MPTFm] = WindSort(wsfinalm,mpwfinalm);
    %
    if (~exist('depth') || isnan(depth))
        prompt = ' Please Enter Depth in m: ';
        depth = input(prompt);
    end
    % Ocean Wind Noise Model Knudsen6 has extra depth dependent term
    %     [kd,ss,f,ms] = NoiseModel(depth);  %Knudsen5
    %     [kdp,ss,fnm,ms] = NoiseModelnew(depth,2,400,5,100,12);  % new Knudsen6
    a=2.8; b=100; aof=1.5; bof=100; cof=12; %new model parameters
    nfacl = 1000; mfacl = 1000; mfacf = 100; %Knudsen8
    [kdp,ss,fnm,ms] = NoiseModelnew(depth,a,b,aof,bof,cof,nfacl,mfacl,mfacf);  % Knudsen8
    fm = .01 : .01 : 1; % 10 Hz - 1 khz
    kdm = zeros(11,100);
    for i = 1:11
        kdm(i,:) = interp1([fnm(1:10),fnm(12:20)],...
            [kdp(i,1:10),kdp(i,12:20)],fm); %10 Hz -1000 Hz
    end
    kd = kdp(:,11:end);
    % plot Knudsen curves
    if strcmp(FrePlt,'on')
        iplot = 1;
        ssFig = figure(4); clf;
        subplot(3,3,iplot) % first of tiled plot
        for i = 1: length(ms)
            semilogx(1000*fnm, kdp(i,:),'k','LineWidth',2);
            if i == 1
                hold on
            end
        end
        i=5;
        semilogx(1000*fnm, kdp(i,:),'r','LineWidth',2); % ss = 4 is log10(ms) = 1
        axis([10,160000,10,95]);
        xlabel('Frequency [Hz]')
        ylabel('dB re uPa^2/Hz')
        ttitle = ['Noise Model ',num2str(depth),' m ',...
            dBaseName,' Hyd ',tf_file(1:3)];
        title(ttitle)
        grid on
        hold on
    end
    % Theory is fnm starts with .01 kHz (need to x 1000) 
    % Data is freq and freq mstarts with 0 then 100 (Hz)
    % fnm is frequency for the noise model
    itf = 1; % increases with wind speed
    TFCorr = NaN(8,nf-1); TFCorrm = NaN(8,500); % hard wired nfm = 501
    ifr = [.2,.3,.4,.5,.6,.7,.8,.9,1,2,5,10,15,20,25,30,100]; % selected freq in kHz
    ifrm = [.02,.05,.1,.2,.3,.4,.5,.6]; % select mid freq
    %     TFCorrWS = zeros(8,length(ifr)); %  wind speeds by freq
    for  i = 2 : 9    % start at i = 2 ss1 end i=9 ss8
        if ~isempty(MPTF{i}) && ~isempty(MPTFm{i})
            % Average MPTF: AMm and AM start at 10 Hz and 100 Hz
            smptf = size((MPTF{i}(2:nf,:)')); % 200 Hz to 30 kHz
            if smptf(1) > 1
                AM = mean(MPTF{i}(2:nf,:)');
            elseif smptf(1) == 1
                AM = MPTF{i}(2:nf,:)';
            end
            smptfm = size((MPTFm{i}(2:501,:)')); % 
            if smptfm(1) > 1
                AMm = mean(MPTFm{i}(2:501,:)'); % 20 Hz to 5 kHz hardwired for 501 nf
            elseif smptfm(1) == 1
                AMm = MPTFm{i}(2:501,:)'; % hardwired for 501 mid frequency nf
            end
            % make TF Correction
            TFCorrm(itf,1:100) = kdm(i,1:100) - AMm(1:100); % first value is 10 Hz last 1000 Hz
            TFCorr(itf,1:nf-1) = kd(i,1:nf-1) - AM(1:nf-1); % first value is 100 Hz last highest freq
%             for j = 1 : length(ifrm)
%                 mPTFm = mean(MPTFm{i}(100*ifrm(j)+1,:));
%                 sPTFm = std(MPTFm{i}(100*ifrm(j)+1,:));
%                 iPTFm = find (MPTFm{i}(100*ifrm(j)+1,:) <  mPTFm + sPTFm);
%                 imPTFm = mean(MPTFm{i}(100*ifrm(j)+1,iPTFm));
%                 TFCorrWSm(itf,j) = kdm(i,10*ifr(j)) - imPTFm;
%             end
%             for j = 1 : length(ifr)
%                 mPTF = mean(MPTF{i}(10*ifr(j)+1,:));
%                 sPTF = std(MPTF{i}(10*ifr(j)+1,:));
%                 iPTF = find (MPTF{i}(10*ifr(j)+1,:) <  mPTF + sPTF);
%                 imPTF = mean(MPTF{i}(10*ifr(j)+1,iPTF));
%                 TFCorrWS(itf,j) = kd(i,10*ifr(j)) - imPTF;
%             end
            itf = itf + 1;
            if strcmp(FrePlt,'on')
                figure(ssFig);
                iplot = iplot + 1;
                subplot(3,3,iplot)  % 9 subplots = 3 x 3
                semilogx(freq(3:nf),MPTF{i}(3:nf,:)); % from 200 Hz to 30 kHz
                hold on
                semilogx(freqm(3:21),MPTFm{i}(3:21,:)); % from 20 Hz to 200 Hz
                semilogx(freq(3:nf),AM(2:nf-1),'r','LineWidth',3); % from 200 Hz to 30 kHz
                semilogx(freqm(3:21),AMm(2:20),'r','LineWidth',3); % from 20 Hz to 100 Hz
                semilogx(1000*fnm,kdp(i,:),'k','LineWidth',3); % theory as a line
                xlabel('Frequency [Hz]')
                ylabel('dB re uPa^2/Hz')
                grid on
                title(['Beaufort Force' ,num2str(ss(i))]);
                v = [20 10e4 25 90];
                xticks([10 100 1000 10000 100000])
                axis(v)
            end
        end
    end
    % Save SS Figure
    ssfile = fullfile(OutFolder,'VsFreqVsWind',OutVsFreq);
    savefig(ssFig,ssfile)
    % Frequencies for plotting
     if (fs0 == 200000 || fs0 == 320000)
         ifr = [.2, .5, 1, 5, 10, 20, 30, 100]; % freq in kHz
    elseif (fs0 == 64000 || fs0 == 96000)
        ifr = [.2, .5, 1, 5, 10, 20, 30]; % freq in kHz
    elseif fs0 == 48000 || fs0 == 50000
        ifr = [.2, .5, 1, 5, 10, 20]; % freq in kHz
     end
    ifrm = [.02,.05,.1,.2,.3,.4,.5,.6];
    % REgress
    % mid
    [SlopeLRm,OffSetLRm,SlopeTSm,OffSetTSm,fTSm] = WNRegress1(...
        OutFolder,OutVsWind2,Proj,Site,Depl,ttitle,depth,...
        wsfinalm,mpwfinalm,ptimem,dnew,kdm,ms,fs0,ifrm,freqm,...
        dfreqm,RegPlt,8);
    % high
    [SlopeLR,OffSetLR,SlopeTS,OffSetTS,fTS] = WNRegress1(...
        OutFolder,OutVsWind1,Proj,Site,Depl,ttitle,depth,...
        wsfinal,mpwfinal,ptime,dnew,kd,ms,fs0,ifr,freq,...
        dfreq,RegPlt,9);
    %
    % Make TF Correction
    % for mid freq use only ss4 - ss8
    MTFCorrm = mean(TFCorrm(4:8,:),'omitnan');%starts with freq = 10 Hz
    if isnan(MTFCorrm(1))
         MTFCorrm = TFCorrm(3,:);%s
         disp(' Used SS3 for mid')
    end  
    % for high freq use only ss2 - ss8
    MTFCorr = mean(TFCorr(2:8,:),'omitnan');  %starts with freq = 100 Hz
    MTFCorra = [MTFCorrm(10:10:40),MTFCorr(5:end)]; %replace point at 100 Hz
    nMT = isnan(MTFCorr); 
    inMT = find(nMT > 0);
    if (~isempty(inMT))
        for i = 1 : length(inMT)
            MTFCorr(inMT(i))=(MTFCorr(inMT(i)-1)+MTFCorr(inMT(i)+1))/2 ;
        end
    end
    nMTm = isnan(MTFCorrm(1:100)); % correct Nan
    inMTm = find(nMTm > 0);
    if (~isempty(inMTm))
        for i = 1 : length(inMTm)
            MTFCorrm(inMTm(i))=(MTFCorrm(inMTm(i)-1)+MTFCorrm(inMTm(i)+1))/2 ;
        end
    end
    figure(6); clf;
    semilogx(freq(2:nf),MTFCorr(1:nf-1),'r','LineWidth',3); %
    hold on
    semilogx(freq(2:nf),MTFCorra(1:nf-1),'k:','LineWidth',3); %
    semilogx(freqm(2:101),MTFCorrm(1:100),'r--','LineWidth',3); %
    v = [10 1e5 -10 5];
    axis(v)
    grid on
    title([dBaseName,' Hydrophone ',tf_file(1:3)])
    xlabel('Frequency [Hz]')
    ylabel('dB re uPa//counts')
    %
    %% Make New TF
    % MAKE TF CORRECTION > 500 Hz < 20 kHz
    % note freq = (count -1)*100 Hz
    col = floor(300/100);  % 300 Hz start
    coh = floor(20000/100);  % mod tf cutoff frequencies in Hz
    [TFold, TFnew] = tfmake(col, coh, freq, Ptf, MTFCorra);
    %Make TF Figure
    TFFig = figure(7); clf;
    [TFFig] = tffigmake(TFFig,TFnew,TFold,tf_file,dBaseName,col,coh);
    %%
    revise = input('Revise Data: d ; Cutoff: c; Bad x; other key end  ','s');
    if strcmp(revise,'d')
        disp('Revise Data')
        celnums = inputdlg({'Enter Freq', 'Add=a Subtact=s'}, 'Data Edit', [1 20; 1 20]);
        efreq = str2double(celnums{1});
        addsub = (celnums{2});
        % make figure to edit
        if efreq == 50
            ifx = iffif;
        elseif efreq == 100
            ifx = ifhun;
        elseif efreq == 500
            ifx = iffiv;
        elseif efreq == 1000
            ifx = ifone;
        elseif efreq == 10000
            ifx = iften;
        elseif efreq == 20000
            ifx = iftwe;
        else
            ifx = ifone;
        end
        figure(1); clf; set(1,'name',sprintf('Wind vs Noise')); h1 = gca;
        if (ifx == iffif || ifx == ifhun)
            plot(h1,wsnew(iwindm),mpwrtfm(ifx,inoisem),'o'); %use mid select
        else
            plot(h1,wsnew(iwind),mpwrtf(ifx,inoise),'o'); %use selected noise
        end
        legend(h1,[num2str(efreq),' Hz'],'Location','southeast');
        grid on; hold on;
        if strcmp(addsub,'a')
            pl = selectdataA('selectionmode','brush');
            if (ifx == iffif || ifx == ifhun)
                zTDm = [zTDm, pl'];
                zTDm = unique(zTDm); % remove duplicated
            else
                zTD = [zTD, pl'];
                zTD = unique(zTD); % remove duplicated
            end
        end
        if strcmp(addsub,'s')
            pl = selectdataS('selectionmode','brush');
            if (ifx == iffif || ifx == ifhun)
                zTDm = setdiff(zTDm, pl);
            else
                zTD = setdiff(zTD, pl);
            end
        end
        close(1); close(3);
        close(4); close(5); close(6); close(7);
    elseif strcmp(revise,'c')
        cutlow = input('Low cutoff Hz: ');
        col = floor(cutlow/100);
        cuthigh = input('High cuttoff Hz: ');
        coh = floor(cuthigh/100);
        [TFold, TFnew] = tfmake(col, coh, freq, Ptf, MTFCorra);
        figure(TFFig); clf;
        [TFFig] = tffigmake(TFFig,TFnew,TFold,tf_file,dBaseName,col,coh);
    elseif strcmp(revise,'x') % bad result move files to "bad" folder
        SaveTF = 'no';
        wnfilebad = fullfile(PARAMS.harp.OutFolder,'BAD',PARAMS.harp.OutName1);
        status1 = movefile(wnfile,wnfilebad);
        wnfignam2bad = fullfile(OutBad,[dBaseName,'WindNoisefit']);
        status2 = movefile([wnfignam2,'.fig'],wnfignam2bad);
        wnfignam3bad = fullfile(OutBad,[dBaseName,'WindNoise']);
        status3 = movefile([wnfignam3,'.fig'],wnfignam3bad);
        ssfilebad = fullfile(OutBad,OutVsFreq);
        status4 = movefile(ssfile,ssfilebad);
        VsWindfile = fullfile(OutFolder,'VsFreqVsWind',OutVsWind);
        VsWindfilebad = fullfile(OutBad,OutVsWind);
        status5 = movefile(VsWindfile,VsWindfilebad);
        if (status1 && status2 && status3 && status4 && status5)
            disp('Successful Move to BAD folder')
        else
            disp(' Failed move to BAD folder')
        end
    end
end
% save in inverse sensitivity tf format in original TF Folder
if strcmp(SaveTF,'yes')
    tfcorrfile = fullfile(OutFolder,'TFCorr',OutTFCorr);
    fre = freq(2:1001);
    tfn = str2num(tf_file(1:3));
    save(tfcorrfile,'fre','MTFCorra','MTFCorr','TFCorr','MTFCorrm','TFCorrm','depth','tfn',...
        'SlopeTSm','OffSetTSm','fTSm','SlopeTS','OffSetTS','fTS','col','coh');
    % save TF_Wind in Folder in Output
    tfnewfile = fullfile(OutFolder,'TF_Wind',...
        [tf_file(1:3),'_',Proj,Site,Depl,'_TFnew.tf']);
    save(tfnewfile,'TFnew','-ascii','-tabs');
    tfnewfig = fullfile(OutFolder,'TF_Wind',...
        [tf_file(1:3),'_',Proj,Site,Depl,'_TFnewfig']);
    savefig(TFFig,tfnewfig)
    tfnewfigpdf = fullfile(OutFolder,'TF_Wind',...
        [tf_file(1:3),'_',Proj,Site,Depl,'_TFnewfig.pdf']);
    saveas(TFFig,tfnewfigpdf)
end
% end
% t = toc;
% disp(' ')
% disp(['Time Elapsed: Spectra from LTSA ', num2str(t),' secs'])
%
