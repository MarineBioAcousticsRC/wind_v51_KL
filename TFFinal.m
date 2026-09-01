% Compare Wind to LSTA -Batch Process
% v 52 modified from v45 single file 12/2020
% v45 - add mid band  11/2020
% JAH 10/2019
% derived from LTSAdailySpectra.m
% 141103 smw
% clear variables

%
%% Batch process WindNoise files -  get filenames
fnpath = 'H:\Wind_TF\Output\pub_TF\TF_Wind';
[fwn_filesX, fwn_pathname] = uigetfile(...
    fullfile(fnpath,'*.mat'),...
    'Pick TF(s)','MultiSelect','on');
% sort if multiple files
% fwn_filesX = sort(fwn_filesX);
% from  name, determine deployment and depth
lfwn = length(fwn_filesX);
datin = cell(lfwn,1);
datsum = nan(1000,lfwn);
anot = 0;
for indexf = 1 :  lfwn
    % load WindNoise.mat file
    ffile = cell2mat(fullfile(fwn_pathname,fwn_filesX(indexf)));
    if exist(ffile)
        datin{indexf,1} = load(ffile);
        dBaseName = strrep(fwn_filesX{indexf},'_WindNoise.mat','');
    else
        disp('No existing  file')
        return
    end
%     if indexf == 1
%         freX = datin{1,1}(:,1);
%     end
    freX = fre;
    fr = datin{indexf,1}(:,1);
    tf = datin{indexf,1}(:,2);
    Ptf = interp1(fr,tf,freX,'linear','extrap');
    datsum(:,indexf) = Ptf;
    anot = anot + 1;
end
datavg =mean(datsum');
figure;
semilogx(freX,datavg,'r','LineWidth',2); %
xlabel('Frequency [Hz]')
ylabel('Inverse Sensitivity [dB re uPa//counts]')
 axis([300,20000,40,88]);  
 hold on
    grid on
    cmap = lines(12); 

 figure
for i = 2: 6
    semilogx(fre,dhold(i,:),'Color',cmap(i-1,:),'LineWidth',2)
    hold on
        final = dhold(i,:) - xn(i,:);
    semilogx(fre,final,':','Color',cmap(i-1,:),'LineWidth',2)
  
end
title('Wind Valid TF Correction By Hydrophone/PreAmp')
xlabel('Frequency (Hz)')
ylabel('dB add to TF as correction')
legend('show','Location','northwest')
legend(...%['300 ','(',num2str(length(x300)),')'],...
    ['400 corrected ','(',num2str(length(xseries{2,1})),')'],...
    ['400 initial'],...
    ['500 corrected ','(',num2str(length(xseries{3,1})),')'],...
      ['500 initial'],...
    ['600 corrected ','(',num2str(length(xseries{4,1})),')'],...
      ['600 initial'],...
    ['700 corrected ','(',num2str(length(xseries{5,1})),')'],...
      ['700 initial'],...
    ['800 corrected ','(',num2str(length(xseries{6,1})),')'],...
  ['800 initial']);
%     ['1200 ','(',num2str(length(i1200)),')'],...
%     ['1400 ','(',num2str(length(i1400)),')']);
ax = gca;
ax.XLim = ([100 50000]);
ax.YLim = ([-8 8]);


