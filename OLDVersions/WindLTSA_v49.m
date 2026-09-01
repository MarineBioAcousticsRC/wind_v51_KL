% Compare Wind to LSTA - SINGLE DEPLOYMENT
% v45 - add mid band  11/2020 - v47 no need to move midband 1/2021 skip48
% v49 add low band 7/2021
% JAH 10/2019
% derived from LTSAdailySpectra.m 141103 smw
%% Parameters
clear variables
% p holds var that come from getWindParams
% PARAMS read from the LTSAs
global p
p = getWindParams; % paramter file

%% Get TF and Depth
p = getTF; % Save tf incase it gets overwritten in recall
Psave = p;

%% calculate or load WindNoise.mat
% Low band assumes 1 Hz LTSA bins
if strcmp(Psave.usel,'y')
    if strcmp(Psave.calavgl,'y') % calculate WindNoise_low.mat file ?
        [ptimel,mpwrl,mpwrtfl,freql,eltsal,dfreql,dnew,wsnew] = calLTSAl49;  % reads LTSAm files to get averages and gets Wind model
    else
        % if low exists load it
        if exist(fullfile(p.harp.OutFolder,'WindNoiseMat',p.harp.OutName3))
            disp(['load: ',p.harp.OutName3])
            load(fullfile(p.harp.OutFolder,'WindNoiseMat',p.harp.OutName3),...
                'ptimel','mpwrl','mpwrtfl','freql','eltsal','dfreql','dnew','wsnew','p');
            % check if tf is correct
            if p.tf.uppc ~= Psave.tf.uppc
                disp('Need to update low TF')
                return
            end
        else
            disp('No existing Low WindNoise file')
            return
        end
    end
    eltsal = unique(eltsal);
end
% Mid band assumes 10 Hz LTSA bins
if strcmp(Psave.usem,'y')
    if strcmp(Psave.calavgm,'y') % calculate WindNoise_mid.mat file ?
        [ptimem,mpwrm,mpwrtfm,freqm,eltsam,dfreqm,dnew,wsnew] = calLTSAm49;  % reads LTSAm files to get averages and gets Wind model
    else
        % if mid exists load it
        if exist(fullfile(p.harp.OutFolder,'WindNoiseMat',p.harp.OutName2))
            disp(['load: ',p.harp.OutName2])
            load(fullfile(p.harp.OutFolder,'WindNoiseMat',p.harp.OutName2),...
                'ptimem','mpwrm','mpwrtfm','freqm','eltsam','dfreqm','dnew','wsnew','p');
            if p.tf.uppc ~= Psave.tf.uppc
                disp('Need to update mid TF')
                return
            end
        else
            disp('No existing Mid WindNoise file')
            return
        end
    end
    eltsam = unique(eltsam);
end
%High band assumes 100 Hz LTSA bins
if strcmp(Psave.use,'y')
    if strcmp(Psave.calavg,'y') % calculate WindNoise.mat file ?
        [ptime,mpwr,mpwrtf,freq,eltsa,dfreq,dnew,wsnew] = calLTSA49();  % reads LTSA files to get averages and gets Wind model
        load(fullfile(p.harp.OutFolder,'WindNoiseMat',p.harp.OutName1));
    else
        if exist(fullfile(p.harp.OutFolder,'WindNoiseMat',p.harp.OutName1))
            disp(['load: ',p.harp.OutName1])
            load(fullfile(p.harp.OutFolder,'WindNoiseMat',p.harp.OutName1),...
                'ptime','mpwr','mpwrtf','freq','eltsa','dfreq','dnew','wsnew','p');
            if p.tf.uppc ~= Psave.tf.uppc
                disp('Need to update high TF')
                return
            end
        else
            disp('No existing High WindNoise file')
            return
        end
    end
    eltsa = unique(eltsa);
end
Psave.ltsa =  p.ltsa;
p = Psave;
depth = p.tf.depth;
tf_file = p.tf.tffile;

%% Noise model
% Ocean Wind Noise Model
a=2.8; b=600; aof=0; bof=100; cof=12; %Knudsen 8 as in JASA
nfacl = 1000; mfacl = 1000; mfacf = 150; mfaca = 3;%
[kdp,ss,fnm,ms] = NoiseModelnew(depth,a,b,aof,bof,cof,nfacl,mfacl,mfacf,mfaca);  % Knudsen8
fm = .01 : .01 : 5; % 10 Hz - 5 khz in 10 Hz steps
kdm = zeros(11,500);
for i = 1:11
    kdm(i,:) = interp1([fnm(1:10),fnm(12:60)],...
        [kdp(i,1:10),kdp(i,12:60)],fm); %10 Hz -5 kHz
end
kd = kdp(:,11:end);
% plot Knudsen curves
if strcmp(p.NMPlt,'on')
    nmFig = figure(5); clf;
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
        p.harp.dBaseName,' Hyd ',tf_file(1:3)];
    title(ttitle)
    grid on
    hold on
end
%% Make Wind vs Noise plots for cleaning data
% reduce sig figures to make wind and noise times match, accurate to ~ 7 min
xw = round(dnew' .* 100)./100;

if exist('freq','var')
    fs0 = p.ltsa.fs0;
    xp = round(ptime .* 100)./100; % reduce sig fig to make match
    [~,inoise,iwind] = intersect(xp,xw);
    if fs0 >= 200000
        if60k = find(freq < 60000 + dfreq/2 & freq > 60000 - dfreq/2); % 60Khz
        if70k = find(freq < 70000 + dfreq/2 & freq > 70000 - dfreq/2); % 70Kh
    end
    if fs0 >= 100000
        if30k = find(freq < 30000 + dfreq/2 & freq > 30000 - dfreq/2); % 30Khz
        if40k = find(freq < 40000 + dfreq/2 & freq > 40000 - dfreq/2); % 40Khz
        if50k = find(freq < 50000 + dfreq/2 & freq > 50000 - dfreq/2); % 50Khz
    end
    if fs0 >= 48000
        if200 = find(freq < 200 + dfreq/2 & freq > 200 - dfreq/2); % 200 Hz
        if300 = find(freq < 300 + dfreq/2 & freq > 300 - dfreq/2); % 300 Hz
        if500 = find(freq < 500 + dfreq/2 & freq > 500 - dfreq/2); % 500 Hz
        if1000 = find(freq < 1000 + dfreq/2 & freq > 1000 - dfreq/2); % 1Khz
        if10k = find(freq < 10000 + dfreq/2 & freq > 10000 - dfreq/2); % 10Khz
        if20k = find(freq < 20000 + dfreq/2 & freq > 20000 - dfreq/2); % 20Khz
    end
end

if exist('freqm','var')
    fs0m = p.ltsa.fs0m;
    xpm = round(ptimem .* 100)./100;
    [~,inoisem,iwindm] = intersect(xpm,xw);
    [~,~,iXm] = intersect(iwind,iwindm);% make wind agree for mid and high
    if20m = find(freqm < 20 + dfreqm/2 & freqm > 20 - dfreqm/2); % 20 Hz
    if50m = find(freqm < 50 + dfreqm/2 & freqm > 50 - dfreqm/2); % 50 Hz
    if100m = find(freqm < 100 + dfreqm/2 & freqm > 100 - dfreqm/2); % 100 Hz
    if200m = find(freqm < 200 + dfreqm/2 & freqm > 200 - dfreqm/2); % 200 Hz
    if500m = find(freqm < 500 + dfreqm/2 & freqm > 500 - dfreqm/2); % 500 Hz
    if1000m = find(freqm < 1000 + dfreqm/2 & freqm > 1000 - dfreqm/2); % 1000 Hz
end

if exist('freql','var')
    fs0l = p.ltsa.fs0l;
    xpl = round(ptimel .* 100)./100;
    [~,inoisel,iwindl] = intersect(xpl,xw);
    [~,~,iXl] = intersect(iwindm,iwindl);% make wind agree for low and mid
    if5l = find(freql < 5 + dfreql/2 & freql > 5 - dfreql/2); % 5 Hz
    if10l = find(freql < 10 + dfreql/2 & freql > 10 - dfreql/2); % 10 Hz
    if20l = find(freql < 20 + dfreql/2 & freql > 20 - dfreql/2); % 20 Hz
    if50l = find(freql < 50 + dfreql/2 & freql > 50 - dfreql/2); % 50 Hz
    if100l = find(freql < 100 + dfreql/2 & freql > 100 - dfreql/2); % 100 Hz
    if200l = find(freql < 200 + dfreql/2 & freql > 200 - dfreql/2); % 200 Hz
    if500l = find(freql < 500 + dfreql/2 & freql > 500 - dfreql/2); % 500 Hz
    if1000l = find(freql < 1000 + dfreql/2 & freql > 1000 - dfreql/2); % 1000 Hz
end

% make vs wind figures
if strcmp(p.use,'y') %figure 2 and 20
    isok = cell(1,6); % array to hold edited data
    % figure(2)
    figure(2); clf; set(2,'name',sprintf('Wind vs Noise'));
    set(gcf,'position',[20 500 600 450]);
    h1 = subplot(3,2,1);

    plot(h1,wsnew(iwindm(iXm)),mpwrtfm(iffif,inoisem(iXm)),'ro'); %use 50 Hz
    legend(h1,'50 Hz','Location','southeast');
    grid on; hold on;
    [isok{1,1}] = createFit4(wsnew(iwindm(iXm)),mpwrtfm(iffif,inoisem(iXm)),...
        wsnew(iwindm(iXm)),mpwrtfm(iffif,inoisem(iXm)),h1 );
    h2 = subplot(3,2,2);
    plot(h2,wsnew(iwindm(iXm)),mpwrtfm(ifhun,inoisem(iXm)),'ro'); %use 500 Hz
    legend(h2,'100 Hz','Location','southeast');
    grid on; hold on;
    [isok{1,2}] = createFit4(wsnew(iwindm(iXm)),mpwrtfm(ifhun,inoisem(iXm)),...
        wsnew(iwindm(iXm)),mpwrtfm(ifhun,inoisem(iXm)),h2 );
    h3 = subplot(3,2,3);
    plot(h3,wsnew(iwind),mpwrtf(if500,inoise),'ro'); %use 500 Hz
    legend(h3,'500 Hz','Location','southeast');
    grid on; hold on;
    [isok{1,3}] = createFit4(wsnew(iwind),mpwrtf(if500,inoise),...
        wsnew(iwind),mpwrtf(if500,inoise),h3 );
    h4 = subplot(3,2,4);
    plot(h4,wsnew(iwind),mpwrtf(if1000,inoise),'ro');%use 1 kH
    legend(h4,'1 kHz','Location','southeast');
    grid on; hold on;
    [isok{1,4}] = createFit4(wsnew(iwind),mpwrtf(if1000,inoise),...
        wsnew(iwind),mpwrtf(if1000,inoise),h4 );
    %
    if fs0 ==  320000 || fs0 ==  200000 || fs0 == 96000 || ...
            fs0 == 64000 || fs0 == 50000 || fs0 == 48000
        h5 = subplot(3,2,5);
        plot(h5,wsnew(iwind),mpwrtf(if10k,inoise),'ro');%use 10 kH
        legend(h5,'10 kHz','Location','southeast');
        grid on; hold on;
        [isok{1,5}] = createFit4(wsnew(iwind),mpwrtf(if10k,inoise),...
            wsnew(iwind),mpwrtf(if10k,inoise),h5 );
        %
        h6 = subplot(3,2,6);
        plot(h6,wsnew(iwind),mpwrtf(if20k,inoise),'ro');%use 20 kH
        legend(h6,'20 kHz','Location','southeast');
        grid on; hold on;
        [isok{1,6}] = createFit4(wsnew(iwind),mpwrtf(if20k,inoise),...
            wsnew(iwind),mpwrtf(if20k,inoise),h6 );
    end
    subplot(3,2,1)
    xlabel('Wind Speed m/s');
    ylabel('Spectrum Level [dB re uPa^2/Hz]');
    title([p.harp.dBaseName,'Noise vs Wind Speed']);
    wnfignam2 = fullfile(p.harp.OutWinFig,[p.harp.dBaseName,'WindNoisefit']);
    figure(2);
    savefig(wnfignam2)
    
    % plot for high frequency noise %figure(20)
    figure(20); clf; set(20,'name',sprintf('Wind vs Noise'));
    h21 = subplot(3,2,1);
    plot(h21,wsnew(iwind),mpwrtf(if20k,inoise),'ro');%use 20 kH
    legend(h21,'20 kHz','Location','southeast');
    grid on; hold on;
    h22 = subplot(3,2,2);
    plot(h22,wsnew(iwind),mpwrtf(if30k,inoise),'ro');%use 30 kH
    legend(h22,'30 kHz','Location','southeast');
    grid on; hold on;
    h23 = subplot(3,2,3);
    plot(h23,wsnew(iwind),mpwrtf(if40k,inoise),'ro');%use 40 kH
    legend(h23,'40 kHz','Location','southeast');
    grid on; hold on;
    h24 = subplot(3,2,4);
    plot(h24,wsnew(iwind),mpwrtf(if50k,inoise),'ro');%use 50 kH
    legend(h24,'50 kHz','Location','southeast');
    grid on; hold on;
    h25 = subplot(3,2,5);
    plot(h25,wsnew(iwind),mpwrtf(if60k,inoise),'ro');%use 50 kH
    legend(h25,'60 kHz','Location','southeast');
    grid on; hold on;
    h26 = subplot(3,2,6);
    plot(h26,wsnew(iwind),mpwrtf(if70k,inoise),'ro');%use 50 kH
    legend(h26,'70 kHz','Location','southeast');
    grid on; hold on;
    subplot(3,2,1)
    xlabel('Wind Speed m/s');
    ylabel('Spectrum Level [dB re uPa^2/Hz]');
    title([p.harp.dBaseName,'Noise vs Wind Speed: High Frequency']);
    % Eliminate Bad Points in Noise vs wind Plots
    % editing based on function selectdata
    if ~exist('zTD','var')
        % overlap of all
        zTD = mintersect(isok{1,1}, isok{1,2}, isok{1,3}, isok{1,4}, isok{1,5}, isok{1,6});
    else
        zTD = mintersect(isok{1,1}, isok{1,2}, zTD);
        disp('using existing zTD')
    end
    if ~exist('zTDl','var')
        %     % overlap of 50 Hz and 100 Hz
        %     zTDm = intersect(isok{1,1}, isok{1,2});
        zTDl = [];
    else
        disp('using existing zTDl')
    end
    if ~exist('zTDm','var')
        %     % overlap of 50 Hz and 100 Hz
        %     zTDm = intersect(isok{1,1}, isok{1,2});
        zTDm = [];
    else
        disp('using existing zTDm')
    end
    disp('Done with cleaning');
    wnfignam20 = fullfile(p.harp.OutWinFig,[p.harp.dBaseName,'WindNoise_high']);
    figure(20);
    savefig(wnfignam20)
    
end

% plot for low frequency noise
if strcmp(p.usel,'y') %figure(200)
    figure(200); clf; set(200,'name',sprintf('Wind vs Noise'));
    h201 = subplot(4,2,1);
    plot(h201,wsnew(iwindl),mpwrtfl(if5l,inoisel),'ro'); %use 5 Hz
    legend(h201,'5 Hz','Location','northeast');
    grid on; hold on;
    xlabel('Wind Speed m/s');
    ylabel('dB re uPa^2/Hz');
    h202 = subplot(4,2,2);
    plot(h202,wsnew(iwindl),mpwrtfl(if10l,inoisel),'ro'); %use 10 Hz
    legend(h202,'10 Hz','Location','northeast');
    grid on; hold on;
    xlabel('Wind Speed m/s');
    ylabel('dB re uPa^2/Hz');
    h203 = subplot(4,2,3);
    plot(h203,wsnew(iwindl),mpwrtfl(if20l,inoisel),'ro'); %use 20Hz
    legend(h203,'20 Hz','Location','northeast');
    grid on; hold on;
    xlabel('Wind Speed m/s');
    ylabel('dB re uPa^2/Hz');
    h204 = subplot(4,2,4);
    plot(h204,wsnew(iwindl),mpwrtfl(if50l,inoisel),'ro'); %use 50 Hz
    legend(h204,'50 Hz','Location','northeast');
    grid on; hold on;
    xlabel('Wind Speed m/s');
    ylabel('dB re uPa^2/Hz');
    h205 = subplot(4,2,5);
    plot(h205,wsnew(iwindl),mpwrtfl(if100l,inoisel),'ro'); %use 100 Hz
    legend(h205,'100 Hz','Location','northeast');
    grid on; hold on;
    xlabel('Wind Speed m/s');
    ylabel('dB re uPa^2/Hz');
    h206 = subplot(4,2,6);
    plot(h206,wsnew(iwindl),mpwrtfl(if200l,inoisel),'ro'); %use 200Hz
    legend(h206,'200 Hz','Location','northeast');
    grid on; hold on;
    xlabel('Wind Speed m/s');
    ylabel('dB re uPa^2/Hz');
    h207 = subplot(4,2,7);
    plot(h207,wsnew(iwindl),mpwrtfl(if500l,inoisel),'ro'); %use 500 Hz
    legend(h207,'500 Hz','Location','northeast');
    grid on; hold on;
    xlabel('Wind Speed m/s');
    ylabel('dB re uPa^2/Hz');
    h208 = subplot(4,2,8);
    plot(h208,wsnew(iwindl),mpwrtfl(if1000l,inoisel),'ro'); %use 1000Hz
    legend(h208,'1000 Hz','Location','northeast');
    grid on; hold on;
    xlabel('Wind Speed m/s');
    ylabel('dB re uPa^2/Hz');
    subplot(4,2,1);
    title([p.harp.dBaseName,'Noise vs Wind Speed: Low Freq']);
    wnfignam200 = fullfile(p.harp.OutWinFig,[p.harp.dBaseName,'WindNoise_low']);
    figure(200);
    savefig(wnfignam200)
end

%% Loop to allow editing
revise = 'd';
while strcmp(revise,'d')
    if strcmp(p.use,'y') % figure 3
        wnfile = fullfile(p.harp.OutFolder,'WindNoiseMat',p.harp.OutName1);
        save(wnfile) % save all workspace
        wsfinal = wsnew(iwind(zTD));
        mpwfinal = mpwrtf(:,inoise(zTD));
        smpw = size(mpwfinal);
        nf = smpw(1);
        %
        figure(3); clf;
        plot(wsfinal',mpwfinal(if500,:),'ko'); %use 1 kHz noise
        hold on
        plot(wsfinal',mpwfinal(if1000,:),'bo'); %use 1 kHz noise
        plot(wsfinal,mpwfinal(if10k,:),'ro'); %use 1 %use 10 kH
        plot(wsfinal,mpwfinal(if20k,:),'go'); %use 1 %use 20 kH
        legend('500 Hz','1 kHz','10 kHz','20 kHz','Location','northwest');
        wnfignam3 = fullfile(p.harp.OutWinFig,[p.harp.dBaseName,'WindNoise']);
        figure(3);
        savefig(wnfignam3)
        %sort into speed bins
        [MPTF,lfor] = WindSort49(wsfinal,mpwfinal); % Mean Pressure TF corrected
        % Make TF Correction
        TFCorr = NaN(8,nf-1);
        
    end
    if strcmp(p.usem,'y') %figure 4
        wsfinalm = wsnew(iwindm(iXm(zTD)));
        mpwfinalm = mpwrtfm(:,inoisem(iXm(zTD)));
        smpwm = size(mpwfinalm);
        nfm = smpwm(1);
        figure(4); clf;
        plot(wsfinalm',mpwfinalm(iffif,:),'ko'); %use 50 Hz noise
        hold on
        plot(wsfinalm',mpwfinalm(ifhun,:),'bo'); %use 100Hz noise
        legend('50 Hz','100 Hz','Location','southeast');
        wnfignam4 = fullfile(p.harp.OutWinFig,[p.harp.dBaseName,'WindNoise_mid']);
        figure(4);
        savefig(wnfignam4)
        [MPTFm,lfor] = WindSort49(wsfinalm,mpwfinalm); % sort into speed
        %TF Correction
        TFCorrm = NaN(8,nfm-1); %
    end
    %     wsfinall = wsnew(iwindl(iXl(zTD)));
    %     mpwfinall = mpwrtfl(:,inoisem(iXl(zTD)));
    if strcmp(p.usel,'y') %figure 40
        wsfinall = wsnew(iwindl);
        mpwfinall = mpwrtfl(:,inoisel);
        smpwl = size(mpwfinall);
        nfl = smpwl(1);
        figure(40); clf;
        plot(wsfinall',mpwfinall(if200l,:),'ko'); %use 200 Hz noise
        hold on
        plot(wsfinall',mpwfinall(if500l,:),'bo'); %use 500Hz noise
        legend('200 Hz','500 Hz','Location','southeast');
        [MPTFl,lfor] = WindSort49(wsfinall,mpwfinall); % sort into speed
        %TF Corr low
        TFCorrl = NaN(8,nfl-1); %
    end
    %%
    if (~exist('depth') || isnan(depth))
        prompt = ' Please Enter Depth in m: ';
        depth = input(prompt);
    end
    % Theory is fnm starts with .01 kHz (need to x 1000)
    % Data is freq and freqm starts with 0 then 100 (Hz)
    % fnm is frequency for the noise model
    % nf = number freq samples; nfm for mid; nfl for low
    itf = 1; % increases with wind speed
    iplot = 1; iplotl = 1; iplotlo = 1;
    for  i = 2 : lfor    % start at i = 2 ss1 end i=9 ss8
        % Average MPTF: AMl AMm and AM start at 1Hz 10 Hz and 100 Hz
        if strcmp(p.use,'y') %
            smptf = size((MPTF{i}(2:nf,:)')); % 200 Hz to 30 kHz
            if smptf(1) > 1
                AM = mean(MPTF{i}(2:nf,:)');
            elseif smptf(1) == 1
                AM = MPTF{i}(2:nf,:)';
            end
            TFCorr(itf,1:nf-1) = kd(i,1:nf-1) - AM(1:nf-1); % first value is 100 Hz last highest freq
        end
        if strcmp(p.usem,'y') %
            smptfm = size((MPTFm{i}(2:nfm,:)')); %
            if smptfm(1) > 1
                AMm = mean(MPTFm{i}(2:nfm,:)'); % 20 Hz to 5 kHz
            elseif smptfm(1) == 1
                AMm = MPTFm{i}(2:nfm,:)'; %
            end
            TFCorrm(itf,1:100) = kdm(i,1:100) - AMm(1:100); % first value is 10 Hz last 1000 Hz
        end
        if strcmp(p.usel,'y') %
            smptfl = size((MPTFl{i}(2:nfl,:)')); %
            if smptfl(1) > 1
                AMl = mean(MPTFl{i}(2:nfl,:)'); % 2 Hz to 1 kHz
            elseif smptfl(1) == 1
                AMl = MPTFl{i}(2:nfl,:)'; %
            end
%             TFCorrl(itf,1:100) = kdm(i,1:100) - AMl(10:10:nfl-1); % first value is is 10 Hz last 1000 Hz
            TFCorrl(itf,1:(nfl-1)/10) = kdm(i,1:(nfl-1)/10) - AMl(10:10:nfl-1); % first value is is 10 Hz last 1000 Hz
        end
        itf = itf + 1;
        
        %% Freq Plot
        if strcmp(p.FrePlt,'on')
            if strcmp(p.use,'y') %
                if iplot ==1
                    ssFig = figure(6); clf;
                end
                figure(ssFig);
                subplot(4,2,iplot)  % 8 subplots = 4 x 2
                semilogx(freq(5:nf),MPTF{i}(5:nf,:)); % from 200 Hz to 30 kHz
                hold on
                semilogx(freqm(3:41),MPTFm{i}(3:41,:)); % from 20 Hz to 200 Hz
                semilogx(1000*fnm,kdp(i,:),'r','LineWidth',3); % theory as a line
                semilogx(freq(5:nf),AM(4:nf-1),'k','Linestyle',':','LineWidth',3); % from 200 Hz to 30 kHz
                semilogx(freqm(3:41),AMm(2:40),'k','Linestyle',':','LineWidth',3); % from 20 Hz to 100 Hz
                grid on
                ftxt =['Beaufort Force' ,num2str(ss(i))];
                text(1000,94,ftxt)
                v = [20 10e4 25 110];
                xticks([10 100 1000 10000 100000])
                axis(v)
                if iplot > 6
                    xlabel('Frequency [Hz]')
                end
                if any(iplot == [1,3,5,7])
                    ylabel('dB re uPa^2/Hz')
                end
                iplot = iplot + 1;
            end
            %
            if strcmp(p.usel,'y') %
                if strcmp(p.use,'y') %
                    % low freq plot
                    if iplotl ==1
                        ssFigl = figure(60); clf;
                    end
                    figure(ssFigl);
                    subplot(4,2,iplotl)  % 8 subplots = 4 x 2
                    semilogx(freq(5:nf),MPTF{i}(5:nf,:)); % from 400 Hz to 100 kHz
                    hold on
                    semilogx(freql(2:401),MPTFl{i}(2:401,:)); % from 10 Hz to 400 Hz
                    semilogx(1000*fnm,kdp(i,:),'r','LineWidth',3); % theory as a line
                    semilogx(freq(5:nf),AM(4:nf-1),'k','Linestyle',':','LineWidth',3); % from 400 Hz to end
                    semilogx(freql(2:401),AMl(1:400),'k','Linestyle',':','LineWidth',3); % from 10 Hz to 400 Hz
                    grid on
                    ftxt =['Beaufort Force' ,num2str(ss(i))];
                    text(700,94,ftxt)
                    v = [10 10e4 25 110];
                    xticks([10 100 1000 10000 100000])
                    axis(v)
                    if iplotl > 6
                        xlabel('Frequency [Hz]')
                    end
                    if any(iplotl == [1,3,5,7])
                        ylabel('dB re uPa^2/Hz')
                    end
                    iplotl = iplotl + 1;
                end
                % low only freq plot
                if iplotlo ==1
                    ssFiglo = figure(600); clf;
                end
                figure(ssFiglo);
                subplot(4,2,iplotlo)  % 8 subplots = 4 x 2
                semilogx(freql(2:nfl),MPTFl{i}(2:nfl,:)); % from 10 Hz to nfl Hz
                hold on
                semilogx(1000*fnm,kdp(i,:),'r','LineWidth',3); % theory as a line
                semilogx(freql(2:nfl),AMl(1:nfl-1),'k','Linestyle',':','LineWidth',3); % from 10 Hz to 400 Hz
                grid on
                ftxt =['Beaufort Force' ,num2str(ss(i))];
                text(70,94,ftxt)
                v = [10 nfl-1 50 110];
                xticks([10 100 1000])
                axis(v)
                if iplotlo > 6
                    xlabel('Frequency [Hz]')
                end
                if any(iplotlo == [1,3,5,7])
                    ylabel('dB re uPa^2/Hz')
                end
                iplotlo = iplotlo + 1;
            end
        end
    end
    if strcmp(p.use,'y') && strcmp(p.usem,'y') %
        % Save SS Figure
        ssfile = fullfile(p.harp.OutFolder,'VsFreqVsWind',p.harp.OutVsFreq);
        savefig(ssFig,ssfile)
        if strcmp(p.usel,'y') %
            ssfilel = fullfile(p.harp.OutFolder,'VsFreqVsWind',p.harp.OutVsFreql);
            savefig(ssFigl,ssfilel)
        end
        % REgress high
        if (fs0 == 200000 || fs0 == 320000)% Frequencies for plotting
            ifr = [.2, .5, 1, 2, 5, 10, 20, 30, 40, 50, 75, 100]; % freq in kHz
        elseif (fs0 == 64000 || fs0 == 96000)
            ifr = [.2, .5, 1, 2, 5, 10, 20, 30, 40]; % freq in kHz
        elseif fs0 == 48000 || fs0 == 50000
            ifr = [.2, .5, 1, 2, 5, 10, 20]; % freq in kHz
        end
        [SlopeLR,OffSetLR,LRr2,SlopeTS,OffSetTS,SlopeTSu,OffSetTSu,fTS] = WNRegress1(...
            p.harp.OutFolder,p.harp.OutVsWind1,p.harp.Proj,p.harp.Site,p.harp.Depl,ttitle,depth,...
            wsfinal,mpwfinal,ptime,dnew,kd,ms,fs0,ifr,freq,...
            dfreq,p.RegPlt,8);
        % REgress mid
        ifrm = [.02,.05,.1,.2,.3,.4,.5,.6,1];% Frequencies for plotting
        [SlopeLRm,OffSetLRm,LRr2m,SlopeTSm,OffSetTSm,SlopeTSum,OffSetTSum,fTSm] = WNRegress1(...
            p.harp.OutFolder,p.harp.OutVsWind2,p.harp.Proj,p.harp.Site,p.harp.Depl,ttitle,depth,...
            wsfinalm,mpwfinalm,ptimem,dnew,kdm,ms,fs0,ifrm,freqm,...
            dfreqm,p.RegPlt,7);
    end
    imaxSS = min(8,lfor); % max SS to use in TFCorr, ifor or ss=8
    if strcmp(p.usel,'y') %
        ssfilelo = fullfile(p.harp.OutFolder,'VsFreqVsWind',p.harp.OutVsFreqlo);
        savefig(ssFiglo,ssfilelo)
        % REgress low
        ifrl = [.005,.01,.02,.05,.1,.2,.3,.4,.5,.6,.8,1];% Frequencies for plotting
        [SlopeLRl,OffSetLRl,LRr2l,SlopeTSl,OffSetTSl,SlopeTSul,OffSetTSul,fTSl] = WNRegress1(...
            p.harp.OutFolder,p.harp.OutVsWind3,p.harp.Proj,p.harp.Site,p.harp.Depl,ttitle,depth,...
            wsfinall,mpwfinall,ptimel,dnew,kdm,ms,fs0l,ifrl,freql,...
            dfreql,p.RegPlt,70);
        % for low freq use only ss4 - ss8
        MTFCorrl = mean(TFCorrl(4:imaxSS,:),'omitnan');%starts with freq = 10 Hz
        figure(90); clf;
        semilogx(freql(2:10:nfl),MTFCorrl(1:(nfl-1)/10),'r-','LineWidth',3); %
        v = [10 nfl-1 -10 5];
        axis(v)
        grid on
        title([p.harp.dBaseName,' Hydrophone ',tf_file(1:3)])
        xlabel('Frequency [Hz]')
        ylabel('dB re uPa//counts');
        % make new TF
        % Default TF CORRECTION > 300 Hz < 20 kHz
        col = floor(300/10);  % 300 Hz start
        coh = floor((nfl-1)/10);  % mod tf cutoff frequencies in Hz
        freqlten = freql(11:10:nfl);
        % Transfer function correction vector
        Ptf = interp1(p.tf.freq,p.tf.uppc,freqlten,'linear','extrap');
        [TFold, TFnewl] = tfmakel49(nfl,col, coh, freqlten, Ptf, MTFCorrl);
        TFFigl = figure(100); clf;
        [TFFigl] = tffigmakel(TFFigl,TFnewl,TFold,tf_file,p.harp.dBaseName,col,coh);
    end
    if strcmp(p.use,'y') %
        % Make TF Correction
        % for mid freq use only ss4 - ss8
        MTFCorrm = mean(TFCorrm(4:imaxSS,:),'omitnan');%starts with freq = 10 Hz
        if isnan(MTFCorrm(1))
            MTFCorrm = TFCorrm(3,:);%s
            disp(' Used SS3 for mid')
        end
        % for high freq use only ss2 - ss8
        MTFCorr = mean(TFCorr(2:imaxSS,:),'omitnan');  %starts with freq = 100 Hz
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
        figure(9); clf;
        semilogx(freq(2:nf),MTFCorr(1:nf-1),'r','LineWidth',3); %
        hold on
        semilogx(freq(2:nf),MTFCorra(1:nf-1),'k:','LineWidth',3); %
        semilogx(freqm(2:101),MTFCorrm(1:100),'r--','LineWidth',3); %
        if strcmp(p.usel,'y')
            semilogx(freqm(2:100),MTFCorrl(1:99),'r-.','LineWidth',3); %
        end
        v = [10 1e5 -10 5];
        axis(v)
        grid on
        title([p.harp.dBaseName,' Hydrophone ',tf_file(1:3)])
        xlabel('Frequency [Hz]')
        ylabel('dB re uPa//counts')
        % Make New TF
        % Default TF CORRECTION > 300 Hz < 20 kHz
        col = floor(300/100);  % 300 Hz start
        coh = floor(20000/100);  % mod tf cutoff frequencies in Hz
        % Transfer function correction vector
        Ptf = interp1(p.tf.freq,p.tf.uppc,freq,'linear','extrap');
        [TFold, TFnew] = tfmake49(col, coh, freq, Ptf, MTFCorra,p.tf.tfn);
        %Make TF Figure
        TFFig = figure(10); clf;
        [TFFig] = tffigmake(TFFig,TFnew,TFold,tf_file,p.harp.dBaseName,col,coh);
    end
    %%
    revise = input('Revise Data: d ; Cutoff: c; Bad x; Quit q; ','s');
    if strcmp(revise,'d')
        disp('Revise Data')
        celnums = inputdlg({'Enter Freq', 'Add=a Subtact=s','edit l m h'}, ...
            'Data Edit', [1 20; 1 20; 1 20]);
        efreq = str2double(celnums{1});
        addsub = (celnums{2});
        lmh = celnums{3};
        % make figure to edit
        figure(1); clf; set(1,'name',sprintf('Wind vs Noise')); h1 = gca;
        grid on; hold on;
        legend(h1,[num2str(efreq),' Hz'],'Location','southeast');
        if strcmp(lmh,'l') && strcmp(p.usel,'y')
            if efreq == 50
                ifx = if50l;
            elseif efreq == 100
                ifx = if100l;
            elseif efreq == 500
                ifx = if500l;
            elseif efreq == 1000
                ifx = if1000l;
            else
                ifx = if1000l;
                disp([num2str(efreq),' not available for edit ... using 1000'])
            end
            plot(h1,wsnew(iwindl),mpwrtfl(ifx,inoisel),'o'); %use low Hz noise
            [zTDl] = addsub49(addsub,zTDl);

        elseif strcmp(lmh,'m') && strcmp(p.usem,'y')
            if efreq == 50
                ifx = iffif;
            elseif efreq == 100
                ifx = ifhun;
            elseif efreq == 500
                ifx = if500;
            elseif efreq == 1000
                ifx = if1000;
            else
                ifx = if1000;
                disp([num2str(efreq),' not available for edit ... using 1000'])
            end
                plot(h1,wsnew(iwindm),mpwrtfm(ifx,inoisem),'o'); %use mid select
                [zTDm] = addsub49(addsub,zTDm);
            
        elseif strcmp(lmh,'h') && strcmp(p.use,'y')
            if efreq == 500
                ifx = if500;
            elseif efreq == 1000
                ifx = if1000;
            elseif efreq == 10000
                ifx = if10k;
            elseif efreq == 20000
                ifx = if20k;
            else
                ifx = if1000;
                disp([num2str(efreq),' not available for edit ... using 1000'])
            end
            plot(h1,wsnew(iwind),mpwrtf(ifx,inoise),'o'); %use selected noise
            [zTD] = addsub49(addsub,zTD);
        end
        %
        close(1); close(3);
        close(4); close(5); close(6); close(7);
    elseif strcmp(revise,'c')
        cutlow = input('Low cutoff Hz: ');
        cuthigh = input('High cuttoff Hz: ');
        if strcmp(p.use,'y') %high freq
            col = floor(cutlow/100);
            coh = floor(cuthigh/100);
            [TFold, TFnew] = tfmake49(col, coh, freq, Ptf, MTFCorra,p.tf.tfn);
            figure(TFFig); clf;
            [TFFig] = tffigmake(TFFig,TFnew,TFold,tf_file,p.harp.dBaseName,col,coh);
        elseif  strcmp(p.usel,'y') % low freq
            col = floor(cutlow/10);  % 300 Hz start
            coh = floor(cuthigh/10);  % mod tf cutoff frequencies in Hz
            if col > 250
                col = 250;
            end
            if coh > 250
                coh = 250;
            end
            [TFold, TFnewl] = tfmakel49(nfl,col, coh, freqlten, Ptf, MTFCorrl);
            TFFigl = figure(100); clf;
            [TFFigl] = tffigmakel(TFFigl,TFnewl,TFold,tf_file,p.harp.dBaseName,col,coh);
        end
    elseif strcmp(revise,'x') % bad result move files to "bad" folder
        SaveTF = 'no';
        wnfilebad = fullfile(p.harp.OutFolder,'BAD',p.harp.OutName1);
        status1 = movefile(wnfile,wnfilebad);
        wnfignam2bad = fullfile(p.harp.OutBad,[p.harp.dBaseName,'WindNoisefit']);
        status2 = movefile([wnfignam2,'.fig'],wnfignam2bad);
        wnfignam3bad = fullfile(p.harp.OutBad,[p.harp.dBaseName,'WindNoise']);
        status3 = movefile([wnfignam3,'.fig'],wnfignam3bad);
        ssfilebad = fullfile(p.harp.OutBad,p.harp.OutVsFreq);
        status4 = movefile(ssfile,ssfilebad);
        VsWindfile = fullfile(p.harp.OutFolder,'VsFreqVsWind',OutVsWind);
        VsWindfilebad = fullfile(p.harp.OutBad,OutVsWind);
        status5 = movefile(VsWindfile,VsWindfilebad);
        if (status1 && status2 && status3 && status4 && status5)
            disp('Successful Move to BAD folder')
        else
            disp(' Failed move to BAD folder')
        end
    elseif strcmp(revise,'q')
        % keep revise ~= 'd'
    else
        revise = 'd';
    end
end
% save in inverse sensitivity tf format in original TF Folder
if strcmp(p.SaveTF,'yes')
    if strcmp(p.use,'y') %high fre
        tfcorrfile = fullfile(p.harp.OutFolder,'TFCorr',p.harp.OutTFCorr);
        fre = freq(2:1001);
        tfn = str2num(tf_file(1:3));
        save(tfcorrfile,'fre','MTFCorra','MTFCorr','TFCorr','MTFCorrm','TFCorrm','depth','tfn',...
            'SlopeLRm','OffSetLRm','LRr2m','SlopeTSm','OffSetTSm','fTSm','SlopeTSum','OffSetTSum',...
            'SlopeLR','OffSetLR','LRr2','SlopeTS','OffSetTS','fTS','SlopeTSu','OffSetTSu',...
            'col','coh');
        % save TF_Wind in Folder in Output
        tfnewfile = fullfile(p.harp.OutFolder,'TF_Wind',...
            [tf_file(1:3),'_',p.harp.Proj,p.harp.Site,p.harp.Depl,'_TFnew.tf']);
        save(tfnewfile,'TFnew','-ascii','-tabs');
        tfnewfig = fullfile(p.harp.OutFolder,'TF_Wind',...
            [tf_file(1:3),'_',p.harp.Proj,p.harp.Site,p.harp.Depl,'_TFnewfig']);
        savefig(TFFig,tfnewfig)
        tfnewfigpdf = fullfile(p.harp.OutFolder,'TF_Wind',...
            [tf_file(1:3),'_',p.harp.Proj,p.harp.Site,p.harp.Depl,'_TFnewfig.pdf']);
        saveas(TFFig,tfnewfigpdf)
    end
    if strcmp(p.usel,'y')
        % save TF_Wind in Folder in Output
        tfnewfilel = fullfile(p.harp.OutFolder,'TF_Wind',...
            [tf_file(1:3),'_',p.harp.Proj,p.harp.Site,p.harp.Depl,'_TFnewl.tf']);
        save(tfnewfilel,'TFnewl','-ascii','-tabs');
        tfnewfigl = fullfile(p.harp.OutFolder,'TF_Wind',...
            [tf_file(1:3),'_',p.harp.Proj,p.harp.Site,p.harp.Depl,'_TFnewfigl']);
        savefig(TFFigl,tfnewfigl)
        tfnewfigpdfl = fullfile(p.harp.OutFolder,'TF_Wind',...
            [tf_file(1:3),'_',p.harp.Proj,p.harp.Site,p.harp.Depl,'_TFnewfigl.pdf']);
        saveas(TFFigl,tfnewfigpdfl)
        
    end
end
%