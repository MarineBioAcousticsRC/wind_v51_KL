% Average TF Corr data
%JAH 12-2019
% get TFCorr file names
clear all;
changeNM = 'y';  % change the Noise Model
[fn_files, fn_pathname] = uigetfile( ...
    {'*.mat'},'Pick TFCorr(s)',...
    'MultiSelect','on');
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
TFC = zeros(nfiles,1000);% 1000 = maximum length of MFTCorr for 100kHz
Slope = zeros(nfiles,8);
TFCWS = zeros(8,18,nfiles);
d = zeros(1,nfiles);
tfnum = zeros(1,nfiles);
disp(['Calculating Averages for: ',num2str(nfiles),' files']);
for k = 1:nfiles    % loop over files
    load(fn{k});
    d(k) = depth;
    TFC(k,:) = MTFCorr(1:1000);
    Slope(k,:) = SlopeTS(1:8);
    tfnum(k) = tfn;
    if strcmp(changeNM,'y')
         [kd1] = NoiseModelnew(depth,0,400,10,100);  % original
         [kd2] = NoiseModelnew(depth,2,400,5,100);  % new 
         deltakd = kd2(5,:) - kd1(5,:); % assume ss = 4
         TFC(k,:) = TFC(k,:) + deltakd(1:1000); % first value i
    end
end
% remove 300 hydrophones - have bad TF
[x300] = find(tfnum >= 400);
d = d(x300);
TFC = TFC(x300,:);
tfnum = tfnum(x300);
Slope = Slope(x300,:);
% Plot slope
SlopeFig = figure;
for i = 1 : 5 % exclude 100 Hz and 100 kHz
subplot(5,1,i)
S20 = Slope(:,i+1)/20;
stdS20 = std(S20);
mS20 = mean(S20);
[B,TF] = rmoutliers(S20,'quartiles');
histogram(S20,100)
ax = gca;
ax.XLim = ([0 2]);  
xlim 
 mtext =['med= ',num2str(median(S20)];
 text(0.1*ax.XLim(2),0.5*ax.YLim(2),mtext)
end
ntext = ['n= ',num2str(length(S20))];
text(0.8*ax.XLim(2),0.5*ax.YLim(2),ntext)
% Correct 700 series TF
[x700] = find(tfnum >= 697 & tfnum < 780 );
for i = 10:100
    c700(i) = 2*(i-10)/(100-10);
end
c700(1:9) = 0;
c700(100:1000) = 2;
for n = 1 : length(x700)
TFC(x700(n),:) = TFC(x700(n),:) - c700;
end
% make plot with depth
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
%
for i = 1 : 6 % exclude 100 Hz and 100 kHz
subplot(6,1,i)
histogram(Slope(i200,i+1)/20,100)
ax = gca;
ax.XLim = ([0 2]);  
xlim 
title('Depth 200')
end
for i = 1 : 6 % exclude 100 Hz and 100 kHz
subplot(6,1,i)
histogram(Slope(i400,i+1)/20,100)
ax = gca;
ax.XLim = ([0 2]);  
xlim 
title('Depth 400')
end
for i = 1 : 6 % exclude 100 Hz and 100 kHz
subplot(6,1,i)
histogram(Slope(i600,i+1)/20,100)
ax = gca;
ax.XLim = ([0 2]);  
xlim 
title('Depth 600')
end
for i = 1 : 6 % exclude 100 Hz and 100 kHz
subplot(6,1,i)
histogram(Slope(i800,i+1)/20,100)
ax = gca;
ax.XLim = ([0 2]);  
xlim 
title('Depth 800')
end
for i = 1 : 6 % exclude 100 Hz and 100 kHz
subplot(6,1,i)
histogram(Slope(i1000,i+1)/20,100)
ax = gca;
ax.XLim = ([0 2]);  
xlim 
title('Depth 1000')
end
for i = 1 : 6 % exclude 100 Hz and 100 kHz
subplot(6,1,i)
histogram(Slope(i1200,i+1)/20,100)
ax = gca;
ax.XLim = ([0 2]);  
xlim 
title('Depth 1200')
end
% mw(:,:,1) = mean(TFCWS(:,:,i200),3,'omitnan');
% mw(:,:,2) = mean(TFCWS(:,:,i400),3,'omitnan');
% mw(:,:,3) = mean(TFCWS(:,:,i600),3,'omitnan');
% mw(:,:,4) = mean(TFCWS(:,:,i800),3,'omitnan');
% mw(:,:,5) = mean(TFCWS(:,:,i1000),3,'omitnan');
% mw(:,:,6) = mean(TFCWS(:,:,i1200),3,'omitnan');
% mw(:,:,7) = mean(TFCWS(:,:,i1400),3,'omitnan');
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
ax.YLim = ([-10 10]);
% make plot with TF number
% [x300] = find(tfnum < 400);
[x400] = find(tfnum >= 400 & tfnum < 500 );
[x500] = find(tfnum >= 500 & tfnum < 600 );
[x600] = find(tfnum >= 600 & tfnum < 697 );
[x700] = find(tfnum >= 697 & tfnum < 780 );
[x800] = find(tfnum >= 780 & tfnum < 1000 );
% [i900] = find(tfnum >= 900  );
% x(1,:) = mean(TFC(x300,:));
x(2,:) = mean(TFC(x400,:));
x(3,:) = mean(TFC(x500,:));
x(4,:) = mean(TFC(x600,:));
x(5,:) = mean(TFC(x700,:));
x(6,:) = mean(TFC(x800,:));
% x(7,:) = mean(TFC(x900,:));
NFig = figure;
for i = 2:6
    semilogx(fre,x(i,:),'LineWidth',2)
    hold on
    grid on
end
title('TF Correction By Hydrophone/PreAmp Number')
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
ax.YLim = ([-10 10]);
%
% Make plot in Wind Speed Space
% ifr = [.1, .5, 1, 5, 10, 20, 30, 100]; % selected freq in kHz
ifr = [.1,.2,.3,.4,.5,.6,.7,.8,.9,1,2,5,10,15,20,25,30,100];% selected freq in kHz
ms = [1, 2.5, 4.5, 6.7, 9.4, 12.3, 15.5, 19, 22.6, 26.5, 30.5];
% c = {'Blue','Brown','Cyan','Green','Magenta','Orange','Purple','Red'};
c = {'Black','Blue','BlueViolet','Brown','Cyan','DarkBlue','DarkGreen',...
        'DarkMagenta','DarkSalmon','Yellow','Gray','Green','LightBlue',...
        'LightSeaGreen','Magenta','Orange','Purple','Red'};
% for ims = 1 : length(ifr) - 1
%     figure( 'Name', ['Noise vs Log10Wind at',num2str(ifr(ims)*1000), ' Hz']);
%     for idepth = 1:7
%         plot(log10(ms(2:9)),mw(:,ims,idepth),'color',rgb(c{idepth}))
%         hold on
%         ax = gca;
%         ax.XLim = ([0.2 1.4]);  % JAH was 0.5 mlogws
%         if ims == 1
%             ax.YLim = ([-30 10]);
%         else
%             ax.YLim = ([-10 10]);
%         end
%         title(['TF Correction for Log10Wind at ',num2str(ifr(ims)*1000), ' Hz']);
%         xlabel('Log10(WindSpeed)')
%         ylabel('dB add to TF as correction')
%     end
%     mmw = mean(mw(:,ims,1:7),3);
%     plot(log10(ms(2:9)),mmw,':k','Linewidth',2);
%     legend('show','Location','northwest')
%     legend(['200 ','(',num2str(length(i200)),')'],...
%         ['400 ','(',num2str(length(i400)),')'],...
%         ['600 ','(',num2str(length(i600)),')'],...
%         ['800 ','(',num2str(length(i800)),')'],...
%         ['1000 ','(',num2str(length(i1000)),')'],...
%         ['1200 ','(',num2str(length(i1200)),')'],...
%         ['1400 ','(',num2str(length(i1400)),')']);
%     % 0 line
%     wdata = [0.2, 1.4];
%     ndata = [0,0];
%     plot(wdata,ndata,'k','Linewidth',2);
%     grid on
% end
% % 700 Series
% c7off = -1; acor = 5; 
% c700 = c7off * ones(1,1000);
% for i = 10:100
%     c700(i) = c700(i) + acor*(i-10)/(100-10);
% end
% c700(100:1000) = acor + c7off;
% % Correct Hydrophones
% for n = 1 : length(x700)
%     TFC(x700(n),:) = TFC(x700(n),:) - c700;
%     TFCnan(x700(n),colk(x700(n)):cohk(x700(n))) = ...
%         TFCnan(x700(n),colk(x700(n)):cohk(x700(n))) - ...
%         c700(colk(x700(n)):cohk(x700(n)));
% end
% % 800 Series
% c8off = -1; 
% c800 = c8off * ones(1,1000);
% % Correct Hydrophone
% for n = 1 : length(x800)
%     TFC(x800(n),:) = TFC(x800(n),:) - c800;
%     TFCnan(x800(n),colk(x800(n)):cohk(x800(n))) = ...
%         TFCnan(x800(n),colk(x800(n)):cohk(x800(n))) - ...
%         c800(colk(x800(n)):cohk(x800(n)));
% end

