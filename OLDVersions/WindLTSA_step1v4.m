% Compare Wind to LSTA
% JAH 10/2019
% derived from LTSAdailySpectra.m
% 141103 smw
clear variables
calavg = 'no'; % calculate LTSA Average ? othewise read in previous
global PARAMS
PARAMS.harp.Proj = 'GofMX';
PARAMS.harp.Site = 'DC';
PARAMS.harp.Short = '03';
PARAMS.harp.Depl = '03';
PARAMS.harp.band = 'high'; % high mid or low
PARAMS.harp.harpDataSummaryCSV = 'H:\Wind_TF\Code\HARPdataSummary.csv';
PARAMS.harp.harpDataSummary = readtable(PARAMS.harp.harpDataSummaryCSV);
PARAMS.harp.WindFolder = ['H:\Wind_Data\',PARAMS.harp.Proj,'\'];
PARAMS.ltsa.LTSAFolder = ['G:\LTSA\',PARAMS.harp.Proj,'\',PARAMS.harp.Site];
PARAMS.tf.TFsFolder = 'H:\Harp_TF\';
PARAMS.tf.TFsFolderOld = 'H:\Harp_TF\OLD\';
PARAMS.harp.OutFolder = 'H:\Wind_TF\Output';
PARAMS.harp.OutName = [PARAMS.harp.Proj,PARAMS.harp.Site,PARAMS.harp.Depl,...
    '_WindNoise','.mat'];
% rm_fifo = 0;    % remove FIFO via interpolation on spectra. 0=no, 1=yes
% fsflag = 1;     % sample rate flag for FIFO removal 1=80kHz, 0=all other
PARAMS.harp.NA = 5;     % number of time slices (spectral averages) to read per raw file
PARAMS.harp.tres = 2;   % time bin resolution 0 = month, 1 = days, 2 = hours
if strcmp(calavg,'yes') % calculate WindNoise.mat file ?
    calLTSA;
end
% get WindNoise.mat file 
load(fullfile(PARAMS.harp.OutFolder,PARAMS.harp.OutName));
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
% REgress
[SlopeLR,OffSetLR,SlopeTS,OffSetTS] = WNRegress(...
    Proj,Site,Depl,depth,wsnew,mpwrtf,ptime,dnew,fs0);
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
[kd] = wenz(depth);
% Theory is f starts with 100
% Data is freq starts with 0
for  i = 3 : 7    % start at i = 3 ss2 end i=7 ss6
    if ~isempty(MPTF{i})
        figure
        semilogx(freq(2:201),MPTF{i}(2:201,:)); % from 100 Hz to 100 kHz
        hold on
        smptf = size((MPTF{i}(2:201,:)'));
        if smptf(1) > 1
            AM = mean(MPTF{i}(2:201,:)');
        elseif smptf(1) == 1
            AM = MPTF{i}(2:201,:)';
        end
        semilogx(freq(2:201),AM,'r','LineWidth',3); % from 100 Hz to 100 kHz
        semilogx(f(1:200).*1000,kd(i,1:200),'k','LineWidth',3); % theory as a line
        hold off
        xlabel('Frequency [Hz]')
        ylabel('Pressure Spectrum Level [dB re uPa^2/Hz]')
        grid on
        title(['Sea State' ,num2str(ss(i))]);
        v = [100 4e4 25 90];
        axis(v)
        TFCorr(i,:) = kd(i,1:200) - AM; % first value is 100 Hz
        %         semilogx(freq(2:201),TFCorr(i,:))
        %         v = [100 2e4 -5 5];
        %         axis(v)
        %         hold on
    end
end
MTFCorr = mean(TFCorr); %starts with freq = 100 Hz
nMT = isnan(MTFCorr); % correct Nan
inMT = find(nMT > 0);
if (~isempty(inMT))
    for i = 1 : length(inMT)
        MTFCorr(inMT(i))=(MTFCorr(inMT(i)-1)+MTFCorr(inMT(i)+1))/2 ;
    end
end
figure
semilogx(freq(2:201),MTFCorr,'r','LineWidth',3); %
v = [100 2e4 -5 5];
axis(v)
grid on
hold on
% Make New TF
% MAKE TF CORRECTION > 1 kHz < 10 kHz
% note freq = (count -1)*100 Hz
iPtf = find(PARAMS.tf.freq > 0 & PARAMS.tf.freq < 100); % part below 100Hz
miP = max(iPtf);
TFnew = [PARAMS.tf.freq(iPtf)',PARAMS.tf.uppc(iPtf)'];% adds < 100 Hz data
TFnew(miP+1:miP+1000,:) = [freq(2:1001)',Ptf(2:1001)']; % begin at 100 Hz
TFold = TFnew;
TFnew(miP+1:miP+4,2) = TFnew(miP+1:miP+4,2) + MTFCorr(5); % for 100 Hz - 400 Hz
TFnew(miP+5:miP+100,2) = TFnew(miP+5:miP+100,2) + MTFCorr(5:100)'; % for 500 Hz - 10 kHz
TFnew(miP+101:end,2) = TFnew(miP+101:end,2) + MTFCorr(100); % for > 10 kHz
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
