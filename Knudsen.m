%Ambient Noise Curve
%With Acknowldegement to Donald Ross and Gordon Wenz
%J Hildebrand 1-26-2008
%

clear all;
% frequency in kHz
f = 1 : .1 : 100;
% attenuation
a = 0.036* f.^(3/2);
% tl = - 60 - 20*log10(r) - a*r;
% above equation assume distnace r in km
r = 1;
tl = - a*r;
%make plot
figure (1);
x = 1000:100000;
y = ones(size(x));
semilogx(x,y);
axis([1000,100000,10,80]);
hold on;
grid on;
ss = [0, .5, 1, 2, 3, 4, 5, 6];
% Approximation for Knudson curves
for i = 1:length(ss)
    for iif = 1:length(f)
        nl(i,iif) = 56 + (19 * log10(ss(i))) - (17 * log10(f(iif))) + tl(iif);
    end
end
% plot Knudsen curves
for i = 1: length(ss)
    semilogx(1000*f, nl(i,:),'k','LineWidth',2);
end

% % Thermal Noise curve
% for iif = 1:length(f)
%     nt(iif) = -15 + 20 * log10(f(iif));
% end
% semilogx(1000*f, nt,'k','LineWidth',2);
% axis([10,100000,0,120]);
% 
% % Add the Wenz curves
% %wc = xlsread('C:\Documents and Settings\HARP\Desktop\wenz\p20007774g195001.xls');
% % Max prevaling Noise curve for Wenz
% %semilogx(wc(:,1),wc(:,2));
% %load Wenz_digall.mat
% %semilogx(data(:,1),data(:,2),'k--');
% 
% % These are the low-freq in the absence of ships,  Wenz lines
% %clear data
% %load Wenz_dig.mat
% %for i = 26:42
% %    data(i,6) = data(i,6) - (2 * (42 - i)/16)
% %end
% %plot of the sea state data
% %semilogx(data(:,1),data(:,2),'k--');
% %semilogx(data(:,1),data(:,3),'y');
% % semilogx(data(:,1),data(:,4)+2);
% % semilogx(data(:,1),data(:,5)+3);
% % semilogx(data(:,1),data(:,6)+2);
% % semilogx(data(:,1),data(:,7));
% %semilogx(data(:,1),data(:,8),'b');
% legend({'Noise','Sea State .5','Sea State 1','Sea State 2',...
%     'Sea State 4','Sea State 6','Sea State 7'},...
%     'Position',[0.6735 0.7223 0.2082 0.1785]);
% 
% %Point Sur and San Nic Mean Noise low frequency
% sur = xlsread('C:\Documents and Settings\HARP\Desktop\wenz\ptsur.xls');
% nic = xlsread('C:\Documents and Settings\HARP\Desktop\wenz\sannic.xls');
% semilogx(sur(1:125,1), sur(1:125,2),'k','LineWidth',2)
% %semilogx(sur(:,1), sur(:,3),'r--','LineWidth',3)
% semilogx(nic(1:185,1), nic(1:185,2),'k','LineWidth',2)
% %semilogx(nic(:,1), nic(:,3),'b--','LineWidth',3)
% xlabel('Frequency (Hz)')
% ylabel('Spectrum Level [dB re: 1µPa2/Hz]')
% 
% % Cato 2001
% cato = xlsread('C:\Documents and Settings\HARP\Desktop\digitizs_curves\cato.xls');
% semilogx(cato(1:780,1),cato(1:780,2)+2.3,'k','LineWidth',2);% 5 kts ss1
% semilogx(cato(1:780,1),cato(1:780,3)+1.2,'k','LineWidth',2);% 10 kts ss2
% semilogx(cato(1:780,1),cato(1:780,4)+0.5,'k','LineWidth',2);% 20 kts ss4
% semilogx(cato(1:780,1),cato(1:780,5),'k','LineWidth',2);% 30 kts ss6
% % semilogx(cato(:,1),cato(:,9),'k');% low level
% % semilogx(cato(1005:end,1),cato(1005:end,6),'k');% shrimps
% % semilogx(cato(500:1118,1),cato(500:1118,7),'k');% evening chorus
% % semilogx(cato(1005:end,1),cato(1005:end,8),'k');% shrimps inshore
% % semilogx(cato(1:1005,1),cato(1:1005,10),'k');% fish chorus
% % semilogx(cato(1:472,1),cato(1:472,11),'r');% arafura
% % semilogx(cato(1:472,1),cato(1:472,12),'k');% remote deep
% % semilogx(cato(1:472,1),cato(1:472,13),'k');% indian
% % semilogx(cato(1:472,1),cato(1:472,14),'k');% tasman
% 
% %Ross curves
% % ross = xlsread('C:\Documents and Settings\HARP\Desktop\digitizs_curves\ross.xls');
% % semilogx(ross(1:332,1),ross(1:332,2)+1,'g');% proxy for ss1
% % semilogx(ross(1:332,1),ross(1:332,2)+7,'g');% 10 kts ss2
% % semilogx(ross(1:332,1),ross(1:332,3)+2,'g');% 20 kts ss4
% % semilogx(ross(1:332,1),ross(1:332,4)+2.5,'g');% 30 kts ss6
% %semilogx(ross(:,1),ross(:,5),'g');% 40 kts ss7
% %semilogx(ross(:,1),ross(:,6),'r');% 15 kts ss3
% %semilogx(ross(:,1),ross(:,7),'b');% 50 kts ss8.5
% 
% % eel pt curves
% % eel = xlsread('C:\Documents and Settings\HARP\Desktop\digitizs_curves\eelpt.xls');
% % semilogx(eel(:,1),eel(:,2),'r');% 2000 mean ships
% % semilogx(eel(:,1),eel(:,3),'k');% 2000 mean NO ships
% 
% % coastal regions curves
% %  coastal = xlsread('C:\Documents and Settings\HARP\Desktop\digitizs_curves\coastal.xls');
% % semilogx(coastal(:,1),coastal(:,2),'k');% gulf mexico
% % semilogx(coastal(63:end,1),coastal(63:end,3),'k');% north sea
% % semilogx(coastal(48:end,1),coastal(48:end,4),'g');% bering sea
% % semilogx(coastal(72:end,1),coastal(72:end,5),'b');% norw sea
% % semilogx(coastal(34:end,1),coastal(34:end,6),'m');% scotia sea
% % semilogx(coastal(:,1),coastal(:,7),'c');% socal eel
% 
