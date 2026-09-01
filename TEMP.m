i45 = find(mpwrtf(101,inoise) > 40 & mpwrtf(101,inoise) < 45);
N45 = mpwrtf(101,inoise(i45));
mN45 = mean(N45);
W45 = wsnew(iwind(i45));
mW45 = mean(W45);
%smoothed version
[fitresult,gof] = createFit(wsnew(iwind),mpwrtf(101,inoiwsnewse) );
yD = feval(fitresult, wsnew(iwind) );
figure(3)
plot(wsnew(iwind),yD,'k','LineWidth',3); %

Wfig = figure; % Wind versus Noise plot
semilogx(wsnew(iwind),mpwrtf(11,inoise),'o') %use 1 kHz noise
hold on
semilogx(wsnew(iwind),mpwrtf(101,inoise),'ro') %use 1 kH
xlabel('Wind Speed m/s');
ylabel('Pressure Spectrum Level [dB re uPa^2/Hz]');
title([dBaseName,'Noise @1000 Hz']);
legend('1 kHz','10 kHz','Location','southeast');
%save wind vs no

ax = gca;
ax.XLim = [1 25]

