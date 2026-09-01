% Average TF Corr data
% results of WindLTSAv45 - analysis of wind noise
% JAH 12-2019
% 11-2020 select only valid part of TFCorr
% TFCorr variables: 'fre','MTFCorra','MTFCorr','TFCorr','MTFCorrm','TFCorrm',
% Valid parts of MTF: 'col','coh'
% Depth and TFNumber: 'depth','tfn'
% ThielSen Slope: 'SlopeTSm','OffSetTSm','fTSm','SlopeTS','OffSetTS','fTS'
%
clear all;
plotslope = 'n'; % make plots with wind speed slope
changeNM = 'y';  % change the Noise Model
         a=2.8; b=600; aof=0; bof=100; cof=12; %new model parameters
        nfacl = 1000; mfacl = 1000; mfacf = 150; mfaca = 3;%
%% Import TFCorr file names
tfcorrpath = 'H:\Wind_TF\Output\pub_TF\TFCorr';
[fn_files, fn_pathname] = uigetfile(...
    fullfile(tfcorrpath,'*.mat'),...
    'Pick TFCorr(s)','MultiSelect','on');
% sort if multiple files selecte
fn_files = sort(fn_files);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(fn_files) % then it's a cell full of filenames
    fn = cell(length(fn_files),1);
    for k = 1:length(fn_files)
        fn{k} = fullfile(fn_pathname, fn_files{k});
        %         disp(fn{k});
    end
else % it's just one file, but put into cell
    fn = cell(1,1);
    fn{1} = fullfile(fn_pathname,fn_files);
    %     disp(fn);
end
nfiles = length(fn);
% initialize files
TFC = zeros(nfiles,1000);% 1000 = maximum length of MFTCorr for 100kHz
TFCnan = nan(nfiles,1000); 
colk = zeros(1,nfiles); cohk = zeros(1,nfiles);
Slope = zeros(nfiles,8);  Slopem = zeros(nfiles,8);
TFCWS = zeros(8,18,nfiles);
d = zeros(1,nfiles);
tfnum = zeros(1,nfiles);
disp(['Calculating Averages for: ',num2str(nfiles),' files']);
for k = 1:nfiles    % loop over files
    load(fn{k});
    d(k) = depth;
    TFC(k,:) = MTFCorr(1:1000);
    colk(k) = col;
    if col < 3
        col = 3;
        colk(k) = 3;
    end
    cohk(k) = coh;
    if coh > 200
        coh = 200;
        cohk(k) = 200;
    end
    TFCnan(k,col:coh) = MTFCorra(col:coh);
    Slope(k,:) = SlopeTS(1:8);
    Slopem(k,:) = SlopeTSm(1:8);
    tfnum(k) = tfn;
    if strcmp(changeNM,'y')
        [kd1] = NoiseModelnew(depth,2.8,600,0,100,12,1000,1000,150,3);  % Knudsen8
        [kd2] = NoiseModelnew(depth,a,b,aof,bof,cof,nfacl,mfacl,mfacf,mfaca);  % new
        deltakd = kd2(5,:) - kd1(5,:); % assume ss = 4
        TFC(k,:) = TFC(k,:) + deltakd(1:1000); % first value i
        TFCnan(k,col:coh) =  TFCnan(k,col:coh) + ...
            deltakd(col:coh);
    end
    %
    OffLR(k,:) = OffSetLR;
end
%
% Electronic Noise
enfig = figure(2); set(2,'name',sprintf('Electronic Noise Level'));
[stfn, isort] = sort(tfnum);
plot(stfn,OffLR(isort,9),'ro')
hold on
plot(stfn,OffLR(isort,10),'bo')
plot(stfn,OffLR(isort,11),'go')
legend('50 kHz','60 kHz','75 kHz','Location','southeast');
xlabel('TF Number');
ylabel('Electronic Noise Level [dB re uPa^2/Hz]');
% save tf numbers
% tfsavefile = fullfile(fn_pathname,'tfsave')
% save(
%%
xseries = cell(6,1);  lx = [];
% Correct Hydrophones by series
[xseries{2,1}] = find(tfnum >= 400 & tfnum < 500 ); % high gain above xover
[xseries{3,1}] = find(tfnum >= 500 & tfnum < 600 ); % 2 kHz xover
[xseries{4,1}] = find(tfnum >= 600 & tfnum < 697 ); % 2 kHz xover
[xseries{5,1}] = find(tfnum >= 697 & tfnum < 780 ); % 20 kHz xover
[xseries{6,1}] = find(tfnum >= 780 & tfnum < 1000 ); % single sensor no xover
lx(2) = length(xseries{2,1});
lx(3) = length(xseries{3,1});
lx(4) = length(xseries{4,1});
lx(5) = length(xseries{5,1});
lx(6) = length(xseries{6,1});
% make plots with TF number
% x(1,:) = mean(TFC(x300,:)); % when 300 series are included
x(2,:) = mean(TFC(xseries{2,1},:));
x(3,:) = mean(TFC(xseries{3,1},:));
x(4,:) = mean(TFC(xseries{4,1},:));
x(5,:) = mean(TFC(xseries{5,1},:));
x(6,:) = mean(TFC(xseries{6,1},:));
% x(7,:) = mean(TFC(x900,:));
% xn(1,:) = mean(TFCnan(x300,:),'omitnan');
xn(2,:) = mean(TFCnan(xseries{2,1},:),'omitnan');
xn(3,:) = mean(TFCnan(xseries{3,1},:),'omitnan');
xn(4,:) = mean(TFCnan(xseries{4,1},:),'omitnan');
xn(5,:) = mean(TFCnan(xseries{5,1},:),'omitnan');
xn(6,:) = mean(TFCnan(xseries{6,1},:),'omitnan');
NFig = figure;
for i = 2:6
    semilogx(fre,x(i,:),'LineWidth',2)
    hold on
    grid on
end
title('Entire TF Correction By Hydrophone/PreAmp')
xlabel('Frequency (Hz)')
ylabel('dB add to TF as correction')
legend('show','Location','northwest')
legend(...%['300 ','(',num2str(length(x300)),')'],...
    ['400 ','(',num2str(length(xseries{2,1})),')'],...
    ['500 ','(',num2str(length(xseries{3,1})),')'],...
    ['600 ','(',num2str(length(xseries{4,1})),')'],...
    ['700 ','(',num2str(length(xseries{5,1})),')'],...
    ['800 ','(',num2str(length(xseries{6,1})),')']);
%     ['1200 ','(',num2str(length(i1200)),')'],...
%     ['1400 ','(',num2str(length(i1400)),')']);
ax = gca;
ax.XLim = ([100 50000]);
ax.YLim = ([-8 8]);
%
NFignan = figure;
for i = 2:6
    semilogx(fre,xn(i,:),'LineWidth',2)
    hold on
    grid on
end
title('Wind TF Correction By Hydrophone/PreAmp')
xlabel('Frequency (Hz)')
ylabel('dB add to TF as correction')
legend('show','Location','northwest')
legend(...%['300 ','(',num2str(length(x300)),')'],...
    ['400 ','(',num2str(length(xseries{2,1})),')'],...
    ['500 ','(',num2str(length(xseries{3,1})),')'],...
    ['600 ','(',num2str(length(xseries{4,1})),')'],...
    ['700 ','(',num2str(length(xseries{5,1})),')'],...
    ['800 ','(',num2str(length(xseries{6,1})),')']);
%     ['1200 ','(',num2str(length(i1200)),')'],...
%     ['1400 ','(',num2str(length(i1400)),')']);
ax = gca;
ax.XLim = ([100 50000]);
ax.YLim = ([-8 8]);
%
% NFignan2 = figure;
% for i = 2:6
%     subplot(5,1,i-1)
%     for j = 1 : lx(i) 
%         semilogx(fre,xn(i,:),'k','LineWidth',2)
%      hold on
%         semilogx(fre,TFCnan(xseries{i,1}(1,j), :),'LineWidth',0.5)
%         fn_files{1,xseries{i,1}(1,j)}
%         pause
%         hold off
%     end
%     grid on
%     ax = gca;
%     ax.XLim = ([100 50000]);
%     ax.YLim = ([-8 8]);
% end
%
TFChold = TFCnan;
[TFCnan] = corrHydro(TFCnan,xseries{2,1},xn(2,:),colk,cohk);
[TFCnan] = corrHydro(TFCnan,xseries{3,1},xn(3,:),colk,cohk);
[TFCnan] = corrHydro(TFCnan,xseries{4,1},xn(4,:),colk,cohk);
[TFCnan] = corrHydro(TFCnan,xseries{5,1},xn(5,:),colk,cohk);
[TFCnan] = corrHydro(TFCnan,xseries{6,1},xn(6,:),colk,cohk);
%
%%
% Divide data into depth bins
[i200] = find(d < 200);
[i400] = find(d >= 200 & d < 400 );
[i600] = find(d >= 400 & d < 600 );
[i800] = find(d >= 600 & d < 800 );
[i1000] = find(d >= 800 & d < 1000 );
[i1200] = find(d >= 1000 & d < 1200 );
[i1400] = find(d >= 1200  );
%
m(1,:) = mean(TFChold(i200,:));
m(2,:) = mean(TFChold(i400,:));
m(3,:) = mean(TFChold(i600,:));
m(4,:) = mean(TFChold(i800,:));
m(5,:) = mean(TFChold(i1000,:));
m(6,:) = mean(TFChold(i1200,:));
m(7,:) = mean(TFChold(i1400,:));
mn(1,:) = mean(TFCnan(i200,:),'omitnan');
mn(2,:) = mean(TFCnan(i400,:),'omitnan');
mn(3,:) = mean(TFCnan(i600,:),'omitnan');
mn(4,:) = mean(TFCnan(i800,:),'omitnan');
mn(5,:) = mean(TFCnan(i1000,:),'omitnan');
mn(6,:) = mean(TFCnan(i1200,:),'omitnan');
mn(7,:) = mean(TFCnan(i1400,:),'omitnan');

%%
% plot of TFCorr mean with depth
DFig = figure;
for i = 1:7
    semilogx(fre,m(i,:),'LineWidth',2)
    hold on
    grid on
end
title('TF Correction By Deployment Depth')
xlabel('Frequency (Hz)')
ylabel('dB add to TF as correction')
legend('show','Location','northwest')
legend(['200 ','(',num2str(length(i200)),')'],...
    ['400 ','(',num2str(length(i400)),')'],...
    ['600 ','(',num2str(length(i600)),')'],...
    ['800 ','(',num2str(length(i800)),')'],...
    ['1000 ','(',num2str(length(i1000)),')'],...
    ['1200 ','(',num2str(length(i1200)),')'],...
    ['1400 ','(',num2str(length(i1400)),')']);
ax = gca;
ax.XLim = ([100 50000]);
ax.YLim = ([-5 5]);
%
DFignan = figure;
lmn = length(mn);
for i = 1:7
%     subplot(7,1,i)
    semilogx(fre(1:lmn),mn(i,:),'LineWidth',2)
    hold on
    grid on
    ax = gca;
    ax.XLim = ([100 50000]);
    ax.YLim = ([-2 2]);
end
mna = (mn.^2);
mnas = sum(mna,'omitnan');
mnass = sqrt(sum(mnas,'omitnan'));
%
title(['TF Correction By Deployment Depth ',num2str(mnass),' error'])
xlabel('Frequency (Hz)')
ylabel('dB add to TF as correction')
legend('show','Location','northeast')
legend(['200 ','(',num2str(length(i200)),')'],...
    ['400 ','(',num2str(length(i400)),')'],...
    ['600 ','(',num2str(length(i600)),')'],...
    ['800 ','(',num2str(length(i800)),')'],...
    ['1000 ','(',num2str(length(i1000)),')'],...
    ['1200 ','(',num2str(length(i1200)),')'],...
    ['1400 ','(',num2str(length(i1400)),')']);
ax = gca;
ax.XLim = ([100 50000]);
ax.YLim = ([-5 5]);

%%
% plot wind slope parameter
if strcmp(plotslope, 'y')
    % Plot slope versus Wind Speed /20
    SlopeFigm = figure;
    subplot(5,1,1)
    ntext = ['Slope vs Wind, n= ',num2str(k)];
    title(ntext);
    hold on;
    mS20 = []; stdS20 = []; mB = [] ; stdB = []; sfreq = [];
    for i = 1 : 5 % use 50 Hz - 400 Hz
        subplot(5,1,i)
        S20 = Slopem(:,i+1)/20;
        stdS20(i) = std(S20);
        mS20(i) = median(S20);
        sfreq(i) = fTSm(i+1);
%         [B,TF] = rmoutliers(S20,'quartiles');
        histogram(S20,100);
%         mB(i) = median(B);
%         stdB(i) = std(B);
        ax = gca;
        ax.XLim = ([0 2]);
        mtext =[num2str(fTSm(i+1)),' Hz'];
        text(0.02*ax.XLim(2),0.85*ax.YLim(2),mtext)
        mtext =['med= ',num2str(mS20(i))];
        text(0.8*ax.XLim(2),0.85*ax.YLim(2),mtext)
        mtext =['std= ',num2str(stdS20(i))];
        text(0.8*ax.XLim(2),0.65*ax.YLim(2),mtext)
    end
    SlopeFig = figure;
    subplot(5,1,1)
    ntext = ['Slope vs Wind, n= ',num2str(k)];
    title(ntext);
    hold on;
    for i = 1 : 5 % use 500 Hz - 20000 Hz
        subplot(5,1,i)
        S20 = Slope(:,i+1)/20;
        stdS20(5+i) = std(S20);
        mS20(5+i) = median(S20);
        sfreq(5+i) = fTS(i+1);
%         [B,TF] = rmoutliers(S20,'quartiles');
        histogram(S20,100);
        ax = gca;
        ax.XLim = ([0 2]);
        mtext =[num2str(fTS(i+1)),' Hz'];
        text(0.02*ax.XLim(2),0.85*ax.YLim(2),mtext)
        mtext =['med= ',num2str(mS20(5+i))];
        text(0.8*ax.XLim(2),0.85*ax.YLim(2),mtext)
         mtext =['std= ',num2str(stdS20(5+i))];
        text(0.8*ax.XLim(2),0.65*ax.YLim(2),mtext)
    end
    sfile = fullfile('H:\Wind_TF\Output\pub_TF\TFCorr\stats','windslope');
    save(sfile,'sfreq','mS20','stdS20')
    %Plots of Wind Slope for Depth
    dip = 5; % dimension of plot
    DF200 = figure;
    dFig(DF200,dip,i200,Slope,'Wind Slope at Depth 200',fTS);
    DF400 = figure;
    dFig(DF400,dip,i400,Slope,'Wind Slope at Depth 400',fTS);
    DF600 = figure;
    dFig(DF600,dip,i600,Slope,'Wind Slope at Depth 600',fTS);
    DF800 = figure;
    dFig(DF800,dip,i800,Slope,'Wind Slope at Depth 800',fTS);
    DF1000 = figure;
    dFig(DF1000,dip,i1000,Slope,'Wind Slope at Depth 1000',fTS);
    DF1200 = figure;
    dFig(DF1200,dip,i1200,Slope,'Wind Slope at Depth 1200',fTS);
    DF1400 = figure;
    dFig(DF1400,dip,i1400,Slope,'Wind Slope at Depth 1400',fTS);
    %
    DF200m = figure;
    dFig(DF200m,dip,i200,Slopem,'Wind Slope at Depth 200',fTSm);
    DF400m = figure;
    dFig(DF400m,dip,i400,Slopem,'Wind Slope at Depth 400',fTSm);
    DF600m = figure;
    dFig(DF600m,dip,i600,Slopem,'Wind Slope at Depth 600',fTSm);
    DF800m = figure;
    dFig(DF800m,dip,i800,Slopem,'Wind Slope at Depth 800',fTSm);
    DF1000m = figure;
    dFig(DF1000m,dip,i1000,Slopem,'Wind Slope at Depth 1000',fTSm);
    DF1200m = figure;
    dFig(DF1200m,dip,i1200,Slopem,'Wind Slope at Depth 1200',fTSm);
    DF1400m = figure;
    dFig(DF1400m,dip,i1400,Slopem,'Wind Slope at Depth 1400',fTSm);
    %
end
% for i = 1:k
%     disp([fn_files(i),' ',num2str(tfnum(i))])
% end
