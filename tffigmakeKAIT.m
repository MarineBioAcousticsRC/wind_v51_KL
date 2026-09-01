function [TFFig] = tffigmakeKAIT(TFFig,TFnew,TFwind,TFold,tf_file,...
    dBaseName,kaitFr,kaitTF)
global p
% make TF Fig
%JAh Sept 2020
%
figure(TFFig);
semilogx(TFnew(:,1),TFnew(:,2),'k','LineWidth',4); %
hold on
semilogx(TFwind(10:end,1),TFwind(10:end,2),'r:','LineWidth',3); %
semilogx(TFold(10:end,1),TFold(10:end,2),'b:','LineWidth',3); 
semilogx(kaitFr,kaitTF,'y:','LineWidth',3); %

tflegend = replace(tf_file,'_','.');
legend('TFnew','WindTF',tflegend,'KaitTF','TFnew','AutoUpdate','off','Location','Northwest');
%
xlim([10,100000]);
title([dBaseName,' Hydrophone ',tf_file(1:3)])
xlabel('Frequency [Hz]')
ylabel('Inverse Sensitivity [dB re uPa//counts]')
grid on