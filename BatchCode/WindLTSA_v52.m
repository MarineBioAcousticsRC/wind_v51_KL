% Compare Wind to LSTA -Batch Process
% v 52 modified from v45 single file 12/2020
% v45 - add mid band  11/2020
% JAH 10/2019
% derived from LTSAdailySpectra.m
% 141103 smw
clear variables
RegPlt = 'off'; % save regression plots off or on
FrePlt = 'off'; % savew freq plots for each sea state off or on
WndPlt = 'off'; % save wind speed plots for each frequency off or on
SaveTF = 'yes'; % save new TF
global PARAMS
%
%% Batch process WindNoise files -  get filenames
fnpath = 'H:\Wind_TF\Output\pub_TF\WindNoiseMat';
[fwn_filesX, fwn_pathname] = uigetfile(...
    fullfile(fnpath,'*.mat'),...
    'Pick WindNoise(s)','MultiSelect','on');
% sort if multiple files
% fwn_filesX = sort(fwn_filesX);
% from  name, determine deployment and depth
lfwn = length(fwn_filesX);
for indexf = 1 : 2 : lfwn
    % load WindNoise.mat file
    ffile = cell2mat(fullfile(fwn_pathname,fwn_filesX(indexf)));
    if exist(ffile)
        hindex = indexf;
        load(ffile);
        indexf = hindex;
        dBaseName = strrep(fwn_filesX{indexf},'_WindNoise.mat','');
    else
        disp('No existing High WindNoise file')
        return
    end
    % load mid file
    ffilem = cell2mat(fullfile(fwn_pathname,fwn_filesX(indexf+1)));
    if exist(ffilem)
        load(ffilem);
        dBaseNamem = strrep(fwn_filesX{indexf+1},'_WindNoise_mid.mat','');
        if ~strcmpi(dBaseName,dBaseNamem)
            disp(['No match ',dBaseName,' ',dBaseNamem]);
            return
        end
    else
        disp('No existing Mid WindNoise file')
        return
    end
    OutVsFreq = [dBaseName,'_VsFreq.fig'];
    OutVsWind1 = [dBaseName,'_VsWind.fig'];
    OutVsWind2 = [dBaseName,'_VsWind_mid.fig'];
    OutTFCorr = [dBaseName,'_TFCorr','.mat'];
    % Correct Outfolder
    PARAMS.harp.OutFolder = 'H:\Wind_TF\Output\pub_TF';
    OutFolder = 'H:\Wind_TF\Output\pub_TF';
    PARAMS.harp.band = 'mid'; % high mid or low
    OutWinFig = ['H:\Wind_TF\Output\pub_TF\VsFreqVsWind\'];
    OutBad =  ['H:\Wind_TF\Output\pub_TF\BAD'];
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
        ifthr = find(freq < 30000 + dfreq/2 & freq > 30000 - dfreq/2); % 30Khz
        iffrt = find(freq < 40000 + dfreq/2 & freq > 40000 - dfreq/2); % 40Khz
        iffff = find(freq < 50000 + dfreq/2 & freq > 50000 - dfreq/2); % 50Khz
        ifsix = find(freq < 60000 + dfreq/2 & freq > 60000 - dfreq/2); % 60Khz
        ifsev = find(freq < 70000 + dfreq/2 & freq > 70000 - dfreq/2); % 70Kh
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
    % make wind agree for mid and high
    [~,iX,iXm] = intersect(iwind,iwindm);
    % make figures
    isok = cell(1,6); % array to hold edited data
    figure(2); clf; set(2,'name',sprintf('Wind vs Noise'));
    set(gcf,'position',[20 500 600 450]);
    h1 = subplot(3,2,1);
    plot(h1,wsnew(iwindm(iXm)),mpwrtfm(iffif,inoisem(iXm)),'ro'); %use 50 Hz
    legend(h1,'50 Hz','Location','southeast');
    grid on; hold on;
    [isok{1,1}] = createFit4(wsnew(iwindm(iXm)),mpwrtfm(iffif,inoisem(iXm)),...
        wsnew(iwindm(iXm)),mpwrtfm(iffif,inoisem(iXm)),h1 );
    %
    h2 = subplot(3,2,2);
    plot(h2,wsnew(iwindm(iXm)),mpwrtfm(ifhun,inoisem(iXm)),'ro'); %use 500 Hz
    legend(h2,'100 Hz','Location','southeast');
    grid on; hold on;
    [isok{1,2}] = createFit4(wsnew(iwindm(iXm)),mpwrtfm(ifhun,inoisem(iXm)),...
        wsnew(iwindm(iXm)),mpwrtfm(ifhun,inoisem(iXm)),h2 );
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
    % plot for high frequency noise
    figure(20); clf; set(2,'name',sprintf('Wind vs Noise'));
    h21 = subplot(3,2,1);
    plot(h21,wsnew(iwind),mpwrtf(iftwe,inoise),'ro');%use 20 kH
    legend(h21,'20 kHz','Location','southeast');
    grid on; hold on;
    h22 = subplot(3,2,2);
    plot(h22,wsnew(iwind),mpwrtf(ifthr,inoise),'ro');%use 30 kH
    legend(h22,'30 kHz','Location','southeast');
    grid on; hold on;
    h23 = subplot(3,2,3);
    plot(h23,wsnew(iwind),mpwrtf(iffrt,inoise),'ro');%use 40 kH
    legend(h23,'40 kHz','Location','southeast');
    grid on; hold on;
    h24 = subplot(3,2,4);
    plot(h24,wsnew(iwind),mpwrtf(iffff,inoise),'ro');%use 50 kH
    legend(h24,'50 kHz','Location','southeast');
    grid on; hold on;
    h25 = subplot(3,2,5);
    plot(h25,wsnew(iwind),mpwrtf(ifsix,inoise),'ro');%use 50 kH
    legend(h25,'60 kHz','Location','southeast');
    grid on; hold on;
    h26 = subplot(3,2,6);
    plot(h26,wsnew(iwind),mpwrtf(ifsev,inoise),'ro');%use 50 kH
    legend(h26,'70 kHz','Location','southeast');
    grid on; hold on;
    subplot(3,2,1)
    xlabel('Wind Speed m/s');
    ylabel('Spectrum Level [dB re uPa^2/Hz]');
    title([dBaseName,'Noise vs Wind Speed: High Frequency']);
    %% Eliminate Bad Points in Noise vs wind Plots
    % editing based on function selectdata
    % for batch keep zTD previous editing and add isok fopr m
    zTD = mintersect(isok{1,1}, isok{1,2}, zTD);
    % if ~exist('zTDm','var')
    %     % overlap of 50 Hz and 100 Hz
    %     zTDm = intersect(isok{1,1}, isok{1,2});
    % else
    %     disp('using existing zTDm')
    % end
    disp('Done with cleaning');
    revise = 'd';
    while strcmp(revise,'d')
        wnfile = fullfile(PARAMS.harp.OutFolder,'WindNoiseMat',PARAMS.harp.OutName1);
%         save(wnfile) % save all workspace
        wsfinal = wsnew(iwind(zTD));
        mpwfinal = mpwrtf(:,inoise(zTD));
        wsfinalm = wsnew(iwindm(iXm(zTD)));
        mpwfinalm = mpwrtfm(:,inoisem(iXm(zTD)));
        figure(3); clf;
        plot(wsfinal',mpwfinal(iffiv,:),'ko'); %use 1 kHz noise
        hold on
        plot(wsfinal',mpwfinal(ifone,:),'bo'); %use 1 kHz noise
        plot(wsfinal,mpwfinal(iften,:),'ro'); %use 1 %use 10 kH
        plot(wsfinal,mpwfinal(iftwe,:),'go'); %use 1 %use 20 kH
        legend('500 Hz','1 kHz','10 kHz','20 kHz','Location','northwest');
        figure(4); clf;
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
        wnfignam4 = fullfile(OutWinFig,[dBaseName,'WindNoise_mid']);
        figure(4);
        savefig(wnfignam4)
        wnfignam20 = fullfile(OutWinFig,[dBaseName,'WindNoise_high']);
        figure(20);
        savefig(wnfignam20)
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
%         a=2.8; b=100; aof=1.5; bof=100; cof=12; %new model parameters
%         nfacl = 1000; mfacl = 1000; mfacf = 100; %Knudsen8
          a=2; b=600; aof=0; bof=100; cof=12; %Knudsen 8
        nfacl = 1000; mfacl = 1000; mfacf = 150; mfaca = 3;%
        [kdp,ss,fnm,ms] = NoiseModelnew(depth,a,b,aof,bof,cof,nfacl,mfacl,mfacf,mfaca);  % Knudsen8
        fm = .01 : .01 : 1; % 10 Hz - 1 khz
        kdm = zeros(11,100);
        for i = 1:11
            kdm(i,:) = interp1([fnm(1:10),fnm(12:20)],...
                [kdp(i,1:10),kdp(i,12:20)],fm); %10 Hz -1000 Hz
        end
        kd = kdp(:,11:end);
        ttitle = ['Noise Model ',num2str(depth),' m ',...
            dBaseName,' Hyd ',tf_file(1:3)];
        % Theory is fnm starts with .01 kHz (need to x 1000)
        % Data is freq and freq mstarts with 0 then 100 (Hz)
        % fnm is frequency for the noise model
        itf = 1; % increases with wind speed
        TFCorr = NaN(8,nf-1); TFCorrm = NaN(8,500); % hard wired nfm = 501
        iplot = 1; % 
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
                itf = itf + 1;
                if strcmp(FrePlt,'on')
                    if iplot ==1
                        ssFig = figure(6); clf;
                    end
                    figure(ssFig);
                    subplot(4,2,iplot)  % 9 subplots = 3 x 3
                    semilogx(freq(5:nf),MPTF{i}(5:nf,:)); % from 200 Hz to 30 kHz
                    hold on
                    semilogx(freqm(3:41),MPTFm{i}(3:41,:)); % from 20 Hz to 200 Hz
                    semilogx(1000*fnm,kdp(i,:),'r','LineWidth',3); % theory as a line
                    semilogx(freq(5:nf),AM(4:nf-1),'k','Linestyle',':','LineWidth',3); % from 200 Hz to 30 kHz
                    semilogx(freqm(3:41),AMm(2:40),'k','Linestyle',':','LineWidth',3); % from 20 Hz to 100 Hz
                    xlabel('Frequency [Hz]')
                    ylabel('dB re uPa^2/Hz')
                    grid on
                    title(['Beaufort Force' ,num2str(ss(i))]);
                    v = [20 10e4 25 90];
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
            end
        end
        % Save SS Figure
        ssfile = fullfile(OutFolder,'VsFreqVsWind',OutVsFreq);
        savefig(ssFig,ssfile)
        % Frequencies for plotting
        if (fs0 == 200000 || fs0 == 320000)
            ifr = [.2, .5, 1, 2, 5, 10, 20, 30, 40, 50, 75, 100]; % freq in kHz
        elseif (fs0 == 64000 || fs0 == 96000)
            ifr = [.2, .5, 1, 2, 5, 10, 20, 30, 40]; % freq in kHz
        elseif fs0 == 48000 || fs0 == 50000
            ifr = [.2, .5, 1, 2, 5, 10, 20]; % freq in kHz
        end
        ifrm = [.02,.05,.1,.2,.3,.4,.5,.6,1];
        % REgress
        % mid
        [SlopeLRm,OffSetLRm,LRr2m,SlopeTSm,OffSetTSm,SlopeTSum,OffSetTSum,fTSm] = WNRegress1(...
            OutFolder,OutVsWind2,Proj,Site,Depl,ttitle,depth,...
            wsfinalm,mpwfinalm,ptimem,dnew,kdm,ms,fs0,ifrm,freqm,...
            dfreqm,RegPlt,7);
        % high
        [SlopeLR,OffSetLR,LRr2,SlopeTS,OffSetTS,SlopeTSu,OffSetTSu,fTS] = WNRegress1(...
            OutFolder,OutVsWind1,Proj,Site,Depl,ttitle,depth,...
            wsfinal,mpwfinal,ptime,dnew,kd,ms,fs0,ifr,freq,...
            dfreq,RegPlt,8);
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
        figure(9); clf;
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
        [TFold, TFnew] = tfmake(col, coh, freq, Ptf, MTFCorra,tfn);
        %Make TF Figure
        TFFig = figure(10); clf;
        [TFFig] = tffigmake(TFFig,TFnew,TFold,tf_file,dBaseName,col,coh);
        %%
        %         revise = input('Revise Data: d ; Cutoff: c; Bad x; other key end  ','s');
        revise = 'n'; % for batch processing
    end
    
    % save in inverse sensitivity tf format in original TF Folder
    if strcmp(SaveTF,'yes')
        tfcorrfile = fullfile(OutFolder,'TFCorr',OutTFCorr);
        fre = freq(2:1001);
        tfn = str2num(tf_file(1:3));
        save(tfcorrfile,'fre','MTFCorra','MTFCorr','TFCorr','MTFCorrm','TFCorrm','depth','tfn',...
            'SlopeLRm','OffSetLRm','LRr2m','SlopeTSm','OffSetTSm','fTSm','SlopeTSum','OffSetTSum',...
            'SlopeLR','OffSetLR','LRr2','SlopeTS','OffSetTS','fTS','SlopeTSu','OffSetTSu',...
            'col','coh');
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
end
%