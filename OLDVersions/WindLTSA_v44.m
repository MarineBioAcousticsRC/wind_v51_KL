% Compare Wind to LSTA - SINGLE DEPLOYMENT
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
global PARAMS
PARAMS.harp.Proj = 'SOCAL';
PARAMS.harp.Proj = 'GofAK';
% PARAMS.harp.Proj = 'ADRIA';
% PARAMS.harp.Proj = 'OCNMS';
% PARAMS.harp.Proj = 'WAT';
% PARAMS.harp.Proj = 'GofMX';
% PARAMS.harp.Proj = 'Hawaii';
% PARAMS.harp.Site = 'JD';
% PARAMS.harp.Site = '_CINMS_B';
% PARAMS.harp.Site = 'HATB';
PARAMS.harp.Site = 'QN';
PARAMS.harp.Depl = '06';
PARAMS.harp.Short = PARAMS.harp.Depl;
PARAMS.harp.band = 'high'; % high mid or low
PARAMS.harp.harpDataSummaryCSV = 'F:\Shared drives\Wind_deltaTF\HARPdataSummaryWIND.csv';
%PARAMS.harp.harpDataSummaryCSV = 'H:\Wind_TF\Code\HARPdataSummaryWIND.csv';
% PARAMS.harp.harpDataSummaryCSV = 'H:\Wind_TF\Code\HARPdataSummarySOCALB.csv';
PARAMS.harp.harpDataSummary = readtable(PARAMS.harp.harpDataSummaryCSV);
PARAMS.harp.WindFolder = ['H:\Wind_Data\',PARAMS.harp.Proj,'\'];
PARAMS.ltsa.LTSAFolder = ['J:\LTSA\',PARAMS.harp.Proj,'\',PARAMS.harp.Site];
PARAMS.tf.TFsFolder = 'F:\Shared drives\MBARC_TF';
PARAMS.tf.TFsFolderOld = 'H:\Harp_TF';
% PARAMS.tf.TFsFolderOld = 'H:\Harp_TF\OLD\';
PARAMS.harp.OutFolder = 'H:\Wind_TF\Output\new_TF';
OutFolder = 'H:\Wind_TF\Output\new_TF';
rm_fifo = 0;    % remove FIFO via interpolation on spectra. 0=no, 1=yes
% fsflag = 1;     % sample rate flag for FIFO removal 1=80kHz, 0=all other
PARAMS.harp.NA = 5;     % number of time slices (spectral averages) to read per raw file
PARAMS.harp.tres = 2;   % time bin resolution 0 = month, 1 = days, 2 = hours
%
PARAMS.harp.OutName1 = [PARAMS.harp.Proj,PARAMS.harp.Site,PARAMS.harp.Depl,...
    '_WindNoise','.mat'];
PARAMS.harp.OutName2 = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_WindNoise','.mat'];
OutWinFig = ['H:\Wind_TF\Output\new_TF\VsFreqVsWind\'];
OutBad =  ['H:\Wind_TF\Output\new_TF\BAD'];
OutVsFreq = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_VsFreq','.fig'];
OutVsWind = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_VsWind','.fig'];
OutTFCorr = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_TFCorr','.mat'];
%% calculate or load WindNoise.mat
if strcmp(calavg,'y') % calculate WindNoise.mat file ?
    calLTSA;  % reads LTSA files to get averages and gets Wind model
end
%
% load WindNoise.mat file either newly created or previously stored
if exist(fullfile(PARAMS.harp.OutFolder,'WindNoiseMat',PARAMS.harp.OutName1))
    load(fullfile(PARAMS.harp.OutFolder,'WindNoiseMat',PARAMS.harp.OutName1));
elseif exist(fullfile(PARAMS.harp.OutFolder,'WindNoiseMat',PARAMS.harp.OutName2))
    load(fullfile(PARAMS.harp.OutFolder,'WindNoiseMat',PARAMS.harp.OutName2));
else
    disp('No existing WindNoise file')
    return
end
%
eltsam = unique(eltsam);
%% Test for Byte Swapped Data
if ~strcmp(Proj,'SanctSound')
    %Identify times with Bite Swapped Data
    if tfn > 600  && fs0 > 100000 % skip for old TF or decimated data
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
end
%% Make Wind vs Noise plots for cleaning data
if fs0 == 200000 ||  fs0 == 320000 || fs0 == 64000 || ...
        fs0 == 96000 || fs0 == 50000 || fs0 == 48000
    ifhun = find(freq < 100 + dfreq/2 & freq > 100 - dfreq/2); % 100 Hz
    iffiv = find(freq < 500 + dfreq/2 & freq > 500 - dfreq/2); % 500 Hz
    ifone = find(freq < 1000 + dfreq/2 & freq > 1000 - dfreq/2); % 1Khz
    iften = find(freq < 10000 + dfreq/2 & freq > 10000 - dfreq/2); % 10Khz
    iftwe = find(freq < 20000 + dfreq/2 & freq > 20000 - dfreq/2); % 20Khz
elseif fs0 == 10000 || fs0 == 20000 || fs0 == 24000
    ifhun = find(freq < 100 + dfreq/2 & freq > 100 - dfreq/2); % 100 Hz
    iffiv = find(freq < 500 + dfreq/2 & freq > 500 - dfreq/2); % 500 Hz
    ifone = find(freq < 1000 + dfreq/2 & freq > 1000 - dfreq/2); % 1Khz
else
    disp('Add New Sample Rate')
    return
end
% reduce sig figures to make times match, accurate to ~ 7 min
xp = round(ptime .* 100)./100;
xw = round(dnew' .* 100)./100;
[~,inoise,iwind] = intersect(xp,xw);
% make figures
isok = cell(1,5); % array to hold edited data
figure(2); clf; set(2,'name',sprintf('Wind vs Noise'));
set(gcf,'position',[20 500 600 450]);
h2 = subplot(2,2,1);
plot(h2,wsnew(iwind),mpwrtf(iffiv,inoise),'ro'); %use 500 Hz
legend(h2,'500 Hz','Location','southeast');
grid on; hold on;
[isok{1,2}] = createFit4(wsnew(iwind),mpwrtf(iffiv,inoise),...
    wsnew(iwind),mpwrtf(iffiv,inoise),h2 );
%
h3 = subplot(2,2,2);
plot(h3,wsnew(iwind),mpwrtf(ifone,inoise),'ro');%use 1 kH
legend(h3,'1 kHz','Location','southeast');
grid on; hold on;
[isok{1,3}] = createFit4(wsnew(iwind),mpwrtf(ifone,inoise),...
    wsnew(iwind),mpwrtf(ifone,inoise),h3 );

if fs0 ==  320000 || fs0 ==  200000 || fs0 == 96000 || ...
        fs0 == 64000 || fs0 == 50000 || fs0 == 48000
    h4 = subplot(2,2,3);
    plot(h4,wsnew(iwind),mpwrtf(iften,inoise),'ro');%use 10 kH
    legend(h4,'10 kHz','Location','southeast');
    grid on; hold on;
    [isok{1,4}] = createFit4(wsnew(iwind),mpwrtf(iften,inoise),...
        wsnew(iwind),mpwrtf(iften,inoise),h4 );
    %
    h5 = subplot(2,2,4);
    plot(h5,wsnew(iwind),mpwrtf(iftwe,inoise),'ro');%use 20 kH
    legend(h5,'20 kHz','Location','southeast');
    grid on; hold on;
    [isok{1,5}] = createFit4(wsnew(iwind),mpwrtf(iftwe,inoise),...
        wsnew(iwind),mpwrtf(iftwe,inoise),h5 );
end
xlabel('Wind Speed m/s');
ylabel('Pressure Spectrum Level [dB re uPa^2/Hz]');
title([dBaseName,'Noise vs Wind Speed']);
%% Eliminate Bad Points in Noise vs wind Plots
% editing based on function selectdata
if ~exist('zTD','var')
    zTD = mintersect(isok{1,2}, isok{1,3}, isok{1,4}, isok{1,5});
else
    disp('existing zTD')
end
disp('Done with cleaning');
revise = 'd';
while strcmp(revise,'d')
    wnfile = fullfile(PARAMS.harp.OutFolder,'WindNoiseMat',PARAMS.harp.OutName1);
    save(wnfile) % save all workspace
    wsfinal = wsnew(iwind(zTD));
    mpwfinal = mpwrtf(:,inoise(zTD));
    figure(3); clf;
    plot(wsfinal',mpwfinal(iffiv,:),'ko'); %use 1 kHz noise
    hold on
    plot(wsfinal',mpwfinal(ifone,:),'bo'); %use 1 kHz noise
    plot(wsfinal,mpwfinal(iften,:),'ro'); %use 1 %use 10 kH
    plot(wsfinal,mpwfinal(iftwe,:),'go'); %use 1 %use 20 kH
    legend('500 Hz','1 kHz','10 kHz','20 kHz','Location','northwest');
    %% save wind vs noise figure
    %wnfigname = fullfile(WindFolder,'WindvsNoise',[dBaseName,'WindNoise']);
    wnfignam2 = fullfile(OutWinFig,[dBaseName,'WindNoisefit']);
    figure(2);
    savefig(wnfignam2)
    wnfignam3 = fullfile(OutWinFig,[dBaseName,'WindNoise']);
    figure(3);
    savefig(wnfignam3)
    %sort into speed bins
    force1 = find(wsfinal > 0.3 & wsfinal <= 1.6);
    MPTF{1} = mpwfinal(:,force1);
    force2 = find(wsfinal > 1.6 & wsfinal <= 3.4);
    MPTF{2} = mpwfinal(:,force2);
    force3 = find(wsfinal > 3.4 & wsfinal <= 5.5);
    MPTF{3} = mpwfinal(:,force3);
    force4 = find(wsfinal > 5.5 & wsfinal <= 8.0);
    MPTF{4} = mpwfinal(:,force4);
    force5 = find(wsfinal > 8.0 & wsfinal <= 10.8);
    MPTF{5} = mpwfinal(:,force5);
    force6 = find(wsfinal > 10.8 & wsfinal <= 13.9);
    MPTF{6} = mpwfinal(:,force6);
    force7 = find(wsfinal > 13.9 & wsfinal <= 17.2);
    MPTF{7} = mpwfinal(:,force7);
    force8 = find(wsfinal > 17.2 & wsfinal <= 20.8);
    MPTF{8} = mpwfinal(:,force8);
    force9 = find(wsfinal > 20.8 & wsfinal <= 24.5);
    MPTF{9} = mpwfinal(:,force9);
    force10 = find(wsfinal > 24.5 & wsfinal <= 28.5);
    MPTF{10} = mpwfinal(:,force10);
    force11 = find(wsfinal > 28.5 & wsfinal <= 32.7);
    MPTF{11} = mpwfinal(:,force11);
    force12 = find(wsfinal > 32.7 );
    MPTF{12} = mpwfinal(:,force12);
    %
    if (~exist('depth') || isnan(depth))
        prompt = ' Please Enter Depth in m: ';
        depth = input(prompt);
    end
    % Ocean Wind Noise Model Knudsen6 has extra depth dependent term
    [kd,ss,fnm,ms] = NoiseModel(depth);  %Knudsen5
%   [kd,ss,fnm,ms] = NoiseModelnew(depth,2,400,5,100);  % new Knudsen6
    % plot Knudsen curves
    if strcmp(FrePlt,'on')
        iplot = 1;
        ssFig = figure(4); clf;
        subplot(3,3,iplot) % first of tiled plot
        for i = 1: length(ms)
            semilogx(1000*fnm, kd(i,:),'k','LineWidth',2);
            if i == 1
                hold on
            end
        end
        i=5;
        semilogx(1000*fnm, kd(i,:),'r','LineWidth',2); % ss = 4 is log10(ms) = 1
        axis([100,160000,10,95]);
        xlabel('Frequency [Hz]')
        ylabel('dB re uPa^2/Hz')
        ttitle = ['Noise Model ',num2str(depth),' m ',...
            dBaseName,' Hyd ',tf_file(1:3)];
        title(ttitle)
        grid on
        hold on
    end
    % Theory is f starts with 100
    % Data is freq starts with 0
    itf = 1;
    TFCorr = zeros(8,nf-1);
    ifr = [.1,.2,.3,.4,.5,.6,.7,.8,.9,1,2,5,10,15,20,25,30,100]; % selected freq in kHz
    TFCorrWS = zeros(8,length(ifr)); %  wind speeds by freq
    for  i = 2 : 9    % start at i = 2 ss1 end i=9 ss8
        if ~isempty(MPTF{i})
            smptf = size((MPTF{i}(2:nf,:)')); % 100 Hz to 30 kHz
            if smptf(1) > 1
                AM = mean(MPTF{i}(2:nf,:)');
            elseif smptf(1) == 1
                AM = MPTF{i}(2:nf,:)';
            end
            TFCorr(itf,:) = kd(i,1:nf-1) - AM; % first value is 100 Hz
            for j = 1 : length(ifr)
                mPTF = mean(MPTF{i}(10*ifr(j)+1,:));
                sPTF = std(MPTF{i}(10*ifr(j)+1,:));
                iPTF = find (MPTF{i}(10*ifr(j)+1,:) <  mPTF + sPTF);
                imPTF = mean(MPTF{i}(10*ifr(j)+1,iPTF));
                TFCorrWS(itf,j) = kd(i,10*ifr(j)) - imPTF;
            end
            itf = itf + 1;
            if strcmp(FrePlt,'on')
                figure(ssFig);
                iplot = iplot + 1;
                subplot(3,3,iplot)  % 9 subplots = 3 x 3
                semilogx(freq(3:nf),MPTF{i}(3:nf,:)); % from 200 Hz to 30 kHz
                hold on
                semilogx(freq(3:nf),AM(2:nf-1),'r','LineWidth',3); % from 200 Hz to 30 kHz
                semilogx(freq(2:nf),kd(i,1:nf-1),'k','LineWidth',3); % theory as a line
                xlabel('Frequency [Hz]')
                ylabel('dB re uPa^2/Hz')
                grid on
                title(['Sea State' ,num2str(ss(i))]);
                v = [100 16e4 25 90];
                axis(v)
            end
        end
    end
    % Save SS Figure
    ssfile = fullfile(OutFolder,'VsFreqVsWind',OutVsFreq);
    savefig(ssFig,ssfile)
    % REgress
    if (fs0 == 200000 || fs0 == 320000)
        ifr = [.1, .5, 1, 5, 10, 20, 30, 100]; % freq in kHz
    elseif (fs0 == 64000 || fs0 == 96000)
        ifr = [.1, .5, 1, 5, 10, 20, 30]; % freq in kHz
    elseif fs0 == 48000 || fs0 == 50000
        ifr = [.1, .5, 1, 5, 10, 20]; % freq in kHz
    end
    [SlopeLR,OffSetLR,SlopeTS,OffSetTS,fTS] = WNRegress1(...
        OutFolder,OutVsWind,Proj,Site,Depl,ttitle,depth,...
        wsfinal,mpwfinal,ptime,dnew,kd,ms,fs0,ifr,freq,dfreq,RegPlt);
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
    figure(6); clf;
    semilogx(freq(2:nf),MTFCorr(1:nf-1),'r','LineWidth',3); %
    v = [500 2e4 -5 5];
    axis(v)
    grid on
    hold on
    %
    %% Make New TF
    % MAKE TF CORRECTION > 500 Hz < 20 kHz
    % note freq = (count -1)*100 Hz
    col = floor(500/100);  % 500 Hz start
    coh = floor(20000/100);  % mod tf cutoff frequencies in Hz
    [TFold, TFnew] = tfmake(col, coh, freq, Ptf, MTFCorr);
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
        if efreq == 500
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
        plot(h1,wsnew(iwind),mpwrtf(ifx,inoise),'o'); %use selected noise
        legend(h1,[num2str(efreq),' Hz'],'Location','southeast');
        grid on; hold on;
        if strcmp(addsub,'a')
            pl = selectdataA('selectionmode','brush');
            zTD = [zTD, pl'];
            zTD = unique(zTD); % remove duplicated
        end
        if strcmp(addsub,'s')
            pl = selectdataS('selectionmode','brush');
            zTD = setdiff(zTD, pl);
        end
        close(1); close(3);
        close(4); close(5); close(6); close(7);
    elseif strcmp(revise,'c')
        cutlow = input('Low cutoff Hz: ');
        col = floor(cutlow/100);
        cuthigh = input('High cuttoff Hz: ');
        coh = floor(cuthigh/100);
        [TFold, TFnew] = tfmake(col, coh, freq, Ptf, MTFCorr);
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
%
% save in inverse sensitivity tf format in original TF Folder
if strcmp(SaveTF,'yes')
    %     tfnewfile = fullfile(tf_pathname,...
    %         [tf_file(1:3),'_',Proj,Site,Depl,'_TFnew.tf']);
    %     save(tfnewfile,'TFnew','-ascii','-tabs');
    %     tfnewfig = fullfile(tf_pathname,...
    %         [tf_file(1:3),'_',Proj,Site,Depl,'_TFnewfig']);
    %     savefig(TFFig,tfnewfig)
    %     tfnewfigpdf = fullfile(tf_pathname,...
    %         [tf_file(1:3),'_',Proj,Site,Depl,'_TFnewfig.pdf']);
    %     saveas(TFFig,tfnewfigpdf)
    % Save TFCorr in Folder in Output
    tfcorrfile = fullfile(OutFolder,'TFCorr',OutTFCorr);
    fre = freq(2:1001);
    tfn = str2num(tf_file(1:3));
    save(tfcorrfile,'fre','MTFCorr','TFCorrWS','depth','tfn','SlopeTS','OffSetTS','fTS','col','coh');
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
