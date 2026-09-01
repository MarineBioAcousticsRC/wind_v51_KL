% Compare Wind to LSTA - SINGLE DEPLOYMENT
% JAH 10/2019
% derived from LTSAdailySpectra.m
% 141103 smw
clear variables
calavg = 'no'; % calculate LTSA Average ? yes or no othewise read in previous
RegPlt = 'on'; % show regression plots off or on
FrePlt = 'on'; % show freq plots for each sea state off or on
WndPlt = 'on'; % show wind speed plots for each frequency off or on
SaveTF = 'yes'; % save  new TF
revise = 'r'; % allow revision of TF cutoff frequencies
global PARAMS
PARAMS.harp.Proj = 'GOFAK';
PARAMS.harp.Site = 'PT';
PARAMS.harp.Depl = '03';
PARAMS.harp.Short = PARAMS.harp.Depl;
PARAMS.harp.band = 'high'; % high mid or low
PARAMS.harp.harpDataSummaryCSV = 'F:\Shared drives\Wind_deltaTF\HARPdataSummaryWIND.csv';
% PARAMS.harp.harpDataSummaryCSV = 'H:\Wind_TF\Code\HARPdataSummaryWIND.csv';
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
OutVsFreq = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_VsFreq','.fig'];
OutVsWind = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_VsWind','.fig'];
OutTFCorr = [PARAMS.harp.Proj,PARAMS.harp.Depl,PARAMS.harp.Site,...
    '_TFCorr','.mat'];
%% calculate or load WindNoise.mat
if strcmp(calavg,'yes') % calculate WindNoise.mat file ?
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
%% Make Three Wind vs Noise plots for cleaning data
if fs0 == 200000 ||  fs0 == 320000 || fs0 == 64000 || ...
        fs0 == 96000 || fs0 == 48000
    ifone = find(freq < 1000 + dfreq/2 & freq > 1000 - dfreq/2); % 1Khz
    iften = find(freq < 10000 + dfreq/2 & freq > 10000 - dfreq/2); % 10Khz
    iftwe = find(freq < 20000 + dfreq/2 & freq > 20000 - dfreq/2); % 20Khz
elseif fs0 == 10000
    ifone = find(freq < 100 + dfreq/2 & freq > 100 - dfreq/2); % 100 Hz
    iffive = find(freq < 500 + dfreq/2 & freq > 500 - dfreq/2); % 500 Hz
else
    disp('Add New Sample Rate')
    return
end
% reduce sig figures to make times match, accurate to ~ 7 min
xp = round(ptime .* 100)./100;
xw = round(dnew' .* 100)./100;
[~,inoise,iwind] = intersect(xp,xw);
% Create three Figures
figure(1); clf; set(1,'name',sprintf('Wind vs Noise 1kHz')); h1 = gca;
figure(2); clf; set(2,'name',sprintf('Wind vs Noise 10kHz')); h2 = gca;
figure(3); clf; set(3,'name',sprintf('Wind vs Noise 20kHz')); h3 = gca;
if fs0 ==  320000 || fs0 ==  200000 || fs0 == 96000 || ...
        fs0 == 64000 || fs0 == 48000
    figure(1)
    plot3(h1,wsnew(iwind),mpwrtf(ifone,inoise),ptime(inoise),'o'); %use 1 kHz noise
    legend(h1,'1 kHz','Location','southeast');  
    grid on;
    view([0 90]); 
    hold on
    figure(2)
    plot3(h2,wsnew(iwind),mpwrtf(iften,inoise),ptime(inoise),'ro'); %use 10 kH
    legend(h2,'10 kHz','Location','southeast');
    grid on
    view([0 90]);
    hold on
    figure(3)
    plot3(h3,wsnew(iwind),mpwrtf(iftwe,inoise),ptime(inoise),'go');%use 20 kH
    legend(h3,'20 kHz','Location','southeast');
    grid on
    view([0 90]);
    hold on
elseif fs0 == 20000 || fs0 == 10000
    plot(h1,wsnew(iwind),mpwrtf(ifone,inoise),'o') %use 100 Hz noise
    legend(h1,'100 Hz','Location','southeast');
    plot(h2,wsnew(iwind),mpwrtf(iffive,inoise),'ro') %use 500 Hz
    legend(h2,'100 Hz','500 Hz','Location','southeast');
end
xlabel('Wind Speed m/s');
ylabel('Pressure Spectrum Level [dB re uPa^2/Hz]');
title([dBaseName,'Noise vs Wind Speed']);
%% Eliminate Bad Points in Noise vs wind Plots
%JAH Hack for cleaning
% isoka = find( mpwrtf(ifone,:) > 30 & mpwrtf(ifone,:) < 90); %1 kHz
% if tfd <= 300
%     isokb = find( mpwrtf(iften,:) > 50 & mpwrtf(iften,:) < 90); %10 kHz
% else
%     isokb = find( mpwrtf(iften,:) > 35 & mpwrtf(iften,:) < 70); %10 kHz
% end
% isokc = find( mpwrtf(iftwe,:) > 30 & mpwrtf(iftwe,:) < 60); %1 kHz
% isok = mintersect(isoka,isokb,isokc);
% ptime = ptime(isok);
% mpwr = mpwr(:,isok);
% mpwrtf = mpwrtf(:,isok);
figure(1);
yell = []; cc = 'p';  zFD = [];
while cc == 'p'
    disp(' Clean bad data: Enter "p" in window, else any key to proceed')
    pause  % wait for user input.
    cc = get(gcf,'CurrentCharacter'); % get key stroke
    % if brush selected get action key
    if strcmp(cc,'p')
        disp(' r = bad; g = good; s = skip')
        h = brush;
        set(h,'Color',[1,1,0],'Enable','on'); % light yellow [.9290 .6940 .1250]
        waitfor(gcf,'CurrentCharacter')
        set(h,'Enable','off')
        cc = get(gcf,'CurrentCharacter');
    end
    if  strcmp(cc,'g') || strcmp(cc,'r')
        % get brushed data and figure out what to do based on color:
        disp(['Number of Bad Wind/Noise Hrs: ',num2str(length(zFD))]);
        [yell,zFD,bFlag] = brush_colorWIND(gca,cc,zFD,ptime);
        if bFlag
            % remove False
            [fptime,izFD,~] = intersect(ptime(inoise),zFD');
            figure(1)
            plot3(h1,wsnew(iwind(izFD)),mpwrtf(ifone,inoise(izFD)),ptime(inoise(izFD)),'kx'); %use 1 kHz noise
            figure(2)
            plot3(h2,wsnew(iwind(izFD)),mpwrtf(iften,inoise(izFD)),ptime(inoise(izFD)),'kx'); %use 10 kH
            figure(3)
            plot3(h3,wsnew(iwind(izFD)),mpwrtf(iftwe,inoise(izFD)),ptime(inoise(izFD)),'kx');%use 20 kH
        end
        cc = 'p';
    elseif  strcmp(cc,'s')
        disp(' No change')
        cc = 'p';
    end
end
disp('Done with cleaning');
[~,nzFD] = setdiff(ptime(inoise),zFD'); % nzFD is index for not false detections
wsfinal = wsnew(iwind(nzFD));
mpwfinal = mpwrtf(:,inoise(nzFD));
figure(4); clf;
plot(wsfinal',mpwfinal(ifone,:),'o'); %use 1 kHz noise
hold on
plot(wsfinal,mpwfinal(iften,:),'ro'); %use 1 %use 10 kH
plot(wsfinal,mpwfinal(iftwe,:),'go'); %use 1 %use 20 kH
legend('1 kHz','10 kHz','20 kHz','Location','southeast');
%% save wind vs noise figure
%wnfigname = fullfile(WindFolder,'WindvsNoise',[dBaseName,'WindNoise']);
wnfigname = fullfile(OutWinFig,[dBaseName,'WindNoise']);
figure(4);
savefig(wnfigname)
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
% Ocean Wind Noise Model
[kd,ss,fnm,ms] = NoiseModel(depth);  %kd is noise level
% plot Knudsen curves
if strcmp(FrePlt,'on')
    iplot = 1;
    ssFig = figure;
    subplot(3,3,iplot) % first of tiled plot
    for i = 1: length(ms)
        semilogx(1000*fnm, kd(i,:),'k','LineWidth',2);
        if i == 1
            hold on
        end
    end
    i=5;
    semilogx(1000*fnm, kd(i,:),'r','LineWidth',2); % ss = 4 is log10(ms) = 1
    %     % Thermal Noise curve
    %     for iif = 1:length(fnm)
    %         nt(iif) = -15 + 20 * log10(fnm(iif));
    %     end
    %     semilogx(1000*fnm, nt,'k','LineWidth',2);
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
for  i = 2 : 9    % start at i = 2 ss1 end i=9 ss8
    if ~isempty(MPTF{i})
        smptf = size((MPTF{i}(2:nf,:)')); % 100 Hz to 30 kHz
        if smptf(1) > 1
            AM = mean(MPTF{i}(2:nf,:)');
        elseif smptf(1) == 1
            AM = MPTF{i}(2:nf,:)';
        end
        TFCorr(itf,:) = kd(i,1:nf-1) - AM; % first value is 100 Hz
        itf = itf + 1;
        if strcmp(FrePlt,'on')
            figure(ssFig);
            iplot = iplot + 1;
            subplot(3,3,iplot)  % 9 subplots = 3 x 3
            semilogx(freq(2:nf),MPTF{i}(2:nf,:)); % from 100 Hz to 30 kHz
            hold on
            semilogx(freq(2:nf),AM(1:nf-1),'r','LineWidth',3); % from 100 Hz to 30 kHz
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
elseif fs0 == 48000
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
figure
semilogx(freq(2:nf),MTFCorr(1:nf-1),'r','LineWidth',3); %
v = [500 2e4 -5 5];
axis(v)
grid on
hold on
% Save in TFCorr Folder in Output
tfcorrfile = fullfile(OutFolder,'TFCorr',OutTFCorr);
fre = freq(2:1001);
tfn = str2num(tf_file(1:3));
save(tfcorrfile,'fre','MTFCorr','depth','tfn','SlopeTS','OffSetTS','fTS');
% Make New TF
% MAKE TF CORRECTION > 500 Hz < 20 kHz
% note freq = (count -1)*100 Hz
col = floor(500/100);  % 500 Hz start
coh = floor(20000/100);  % mod tf cutoff frequencies in Hz
while strcmp(revise,'r')
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
    semilogx(TFnew(10:end,1),TFnew(10:end,2),'r','LineWidth',3); %
    hold on
    semilogx(TFold(10:end,1),TFold(10:end,2),'k','LineWidth',3); %
    tflegend = replace(tf_file,'_','.');
    legend('WindTF',tflegend,'AutoUpdate','off','Location','Northwest');
    title([dBaseName,' Hydrophone ',tf_file(1:3)])
    xlabel('Frequency [Hz]')
    ylabel('Inverse Sensitivity [dB re uPa//counts]')
    revise = input('Data Select: d - Revise Cutoff:  r - other key end ','s');
    if strcmp(revise,'r')
        cutlow = input('Low cutoff Hz: ');
        col = floor(cutlow/100);
        cuthigh = input('High cuttoff Hz: ');
        coh = floor(cuthigh/100);
    end
    % add shading 
    figure(TFFig)
    xl = xlim;
    yl = ylim;
    gray = [0.8 0.8 0.8];
    patch([xl(1) col*100 col*100 xl(1)],[yl(1) yl(1) yl(2) yl(2)],gray)
    patch([coh*100 xl(2) xl(2) coh*100],[yl(1) yl(1) yl(2) yl(2)],gray)
    set(gca,'children',flipud(get(gca,'children')))
    grid on
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
    % Another copy in TF_Wind Folder in Output
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
% yell = []; cc = 'p';  
% while cc == 'p'
%     disp(' Edit data: Enter "a" add, "s" subtract, any other key to proceed')
%     pause  % wait for user input.
%     cc = get(gcf,'CurrentCharacter'); % get key stroke
%     % if brush selected get action key
%     if strcmp(cc,'a')
%         pl = selectdata('selectionmode','brush');
%         zFD = [zFD;pl];
%         zFD = unique(zFD); % remove duplicated
%     end
%      if strcmp(cc,'s')
%         pl = selectdata('selectionmode','brush');
%         zFD = setdiff(zFD, pl);
%     end
% end