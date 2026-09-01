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
a=2; b=100; aof=2; bof=100; cof=12; %new model parameters
%
%% Import TFCorr file names
tfcorrpath = 'H:\Wind_TF\Output\newest_TF\TFCorr';
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
TFCnan = nan(nfiles,1000); TFCnanC = TFCnan;
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
    cohk(k) = coh;
    TFCnan(k,col:coh) = MTFCorra(col:coh);
    Slope(k,:) = SlopeTS(1:8);
    Slopem(k,:) = SlopeTSm(1:8);
    tfnum(k) = tfn;
    if strcmp(changeNM,'y')
        [kd1] = NoiseModelnew(depth,2,400,5,100,12);  % original
        [kd2] = NoiseModelnew(depth,a,b,aof,bof,cof);  % new
        deltakd = kd2(5,:) - kd1(5,:); % assume ss = 4
        TFC(k,:) = TFC(k,:) + deltakd(1:1000); % first value i
        TFCnan(k,col:coh) =  TFCnan(k,col:coh) + ...
            deltakd(col:coh);
    end
end
%%
% Correct Hydrophones by series
[x400] = find(tfnum >= 400 & tfnum < 500 ); % high gain above xover
[x500] = find(tfnum >= 500 & tfnum < 600 ); % 2 kHz xover
[x600] = find(tfnum >= 600 & tfnum < 697 ); % 2 kHz xover
[x700] = find(tfnum >= 697 & tfnum < 780 ); % 20 kHz xover
[x800] = find(tfnum >= 780 & tfnum < 1000 ); % single sensor no xover
% make plots with TF number
% x(1,:) = mean(TFC(x300,:)); % when 300 series are included
x(2,:) = mean(TFC(x400,:));
x(3,:) = mean(TFC(x500,:));
x(4,:) = mean(TFC(x600,:));
x(5,:) = mean(TFC(x700,:));
x(6,:) = mean(TFC(x800,:));
% x(7,:) = mean(TFC(x900,:));
% xn(1,:) = mean(TFCnan(x300,:),'omitnan');
xn(2,:) = mean(TFCnan(x400,:),'omitnan');
xn(3,:) = mean(TFCnan(x500,:),'omitnan');
xn(4,:) = mean(TFCnan(x600,:),'omitnan');
xn(5,:) = mean(TFCnan(x700,:),'omitnan');
xn(6,:) = mean(TFCnan(x800,:),'omitnan');
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
    ['400 ','(',num2str(length(x400)),')'],...
    ['500 ','(',num2str(length(x500)),')'],...
    ['600 ','(',num2str(length(x600)),')'],...
    ['700 ','(',num2str(length(x700)),')'],...
    ['800 ','(',num2str(length(x800)),')']);
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
title('Wind Valid TF Correction By Hydrophone/PreAmp')
xlabel('Frequency (Hz)')
ylabel('dB add to TF as correction')
legend('show','Location','northwest')
legend(...%['300 ','(',num2str(length(x300)),')'],...
    ['400 ','(',num2str(length(x400)),')'],...
    ['500 ','(',num2str(length(x500)),')'],...
    ['600 ','(',num2str(length(x600)),')'],...
    ['700 ','(',num2str(length(x700)),')'],...
    ['800 ','(',num2str(length(x800)),')']);
%     ['1200 ','(',num2str(length(i1200)),')'],...
%     ['1400 ','(',num2str(length(i1400)),')']);
ax = gca;
ax.XLim = ([100 50000]);
ax.YLim = ([-8 8]);
%
 [TFCnanC] = corrHydro(TFCnan,x400,xn(2,:),colk,cohk);
 [TFCnanC] = corrHydro(TFCnan,x500,xn(3,:),colk,cohk);
 [TFCnanC] = corrHydro(TFCnan,x600,xn(4,:),colk,cohk);
 [TFCnanC] = corrHydro(TFCnan,x700,xn(5,:),colk,cohk);
 [TFCnanC] = corrHydro(TFCnan,x800,xn(6,:),colk,cohk); 

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
m(1,:) = mean(TFC(i200,:));
m(2,:) = mean(TFC(i400,:));
m(3,:) = mean(TFC(i600,:));
m(4,:) = mean(TFC(i800,:));
m(5,:) = mean(TFC(i1000,:));
m(6,:) = mean(TFC(i1200,:));
m(7,:) = mean(TFC(i1400,:));
mn(1,:) = mean(TFCnanC(i200,:),'omitnan');
mn(2,:) = mean(TFCnanC(i400,:),'omitnan');
mn(3,:) = mean(TFCnanC(i600,:),'omitnan');
mn(4,:) = mean(TFCnanC(i800,:),'omitnan');
mn(5,:) = mean(TFCnanC(i1000,:),'omitnan');
mn(6,:) = mean(TFCnanC(i1200,:),'omitnan');
mn(7,:) = mean(TFCnanC(i1400,:),'omitnan');

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
for i = 1:7
    semilogx(fre,mn(i,:),'LineWidth',2)
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
%%
% plot wind slope parameter
if strcmp(plotslope, 'y')
    % Plot slope versus Wind Speed /20
    SlopeFig = figure;
    subplot(5,1,1)
    ntext = ['Slope vs Wind, n= ',num2str(k)];
    title(ntext);
    hold on;
    for i = 1 : 5 % use 500 Hz - 20000 Hz
        subplot(5,1,i)
        S20 = Slope(:,i+1)/20;
        stdS20 = std(S20);
        mS20 = mean(S20);
        [B,TF] = rmoutliers(S20,'quartiles');
        histogram(S20,100);
        ax = gca;
        ax.XLim = ([0 2]);
        mtext =[num2str(fTS(i+1)),' Hz'];
        text(0.02*ax.XLim(2),0.85*ax.YLim(2),mtext)
        mtext =['med= ',num2str(median(S20))];
        text(0.8*ax.XLim(2),0.85*ax.YLim(2),mtext)
    end
    SlopeFigm = figure;
    subplot(5,1,1)
    ntext = ['Slope vs Wind, n= ',num2str(k)];
    title(ntext);
    hold on;
    for i = 1 : 5 % use 50 Hz - 400 Hz
        subplot(5,1,i)
        S20 = Slopem(:,i+1)/20;
        stdS20 = std(S20);
        mS20 = mean(S20);
        [B,TF] = rmoutliers(S20,'quartiles');
        histogram(S20,100);
        ax = gca;
        ax.XLim = ([0 2]);
        mtext =[num2str(fTSm(i+1)),' Hz'];
        text(0.02*ax.XLim(2),0.85*ax.YLim(2),mtext)
        mtext =['med= ',num2str(median(S20))];
        text(0.8*ax.XLim(2),0.85*ax.YLim(2),mtext)
    end
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
end

