function [kd] = wenz(depth)
%JAH 12-2019
% theoreticalOceanNoise.m
% 080423 smw  from Don Ross Notes:
% + 56 dB re uPa^2 / Hz
% + 19*log10(ss) for 0.5 < seastate (ss) < 6
% - 17*log10(f) for 0.5 kHz < freqeuncy (f) < 25 kHz (ie Knudsen)
% a = 56.*ones(lenss,lenf);
% b = (19*log10(ss))'*ones(1,lenf);
% c = ones(lenss,1) * (-17*log10(f));
% % Pressure Spectrum Level (power)
% p = a + b + c;
% now using "Improved Knudsen"
ms = [1, 2.5, 4.5, 6.7, 9.4, 12.3, 15.5, 19, 22.6, 26.5];
ss = [.5, 1,2,3,4,5,6,7,8,9];
lenss = length(ss);
f = .1 : .1 : 100;
lenf = length(f);
nl = zeros(length(ms),length(f));
nl = zeros(length(ms),length(f));
% Approximation for Knudson curves
n = 0.5;  m= 1/2;
for i = 1:3 % wind less than 5 m/s
    for iif = 1:4 % 100-400 Hz
        nl(i,iif) = 57.4 + (n *20* log10(ms(i))) + 8 * log10(f(iif)) ;% m = 0.8
    end
    for iif = 5:9 % 500-1000 Hz
        nl(i,iif) = 52.5 + (n *20* log10(ms(i))) - m*10 * log10(f(iif)) ;
    end
    for iif = 10:length(f) % > 1000 Hz
        nl(i,iif) = 52.5 + (n *20* log10(ms(i))) - 16 * log10(f(iif)) ; %m = 1.6
    end
end
n = 1.25;
for i = 4:5 % wind > than 5 m/s  and < 15 m/s
    for iif = 1:4 % 100-400 Hz
        nl(i,iif) = 47.4 + (n *20* log10(ms(i))) + 10 * log10(f(iif)) ; %m=1
    end
    for iif = 5:9 % 500-1000 Hz
        nl(i,iif) = 42 + (n *20* log10(ms(i))) - m*10 * log10(f(iif)) ;
    end
    for iif = 10:99 % 1000 Hz - 10000 Hz
        nl(i,iif) = 42 + (n *20* log10(ms(i))) - 16 * log10(f(iif)) ; %m = 1.6
        %  -0.05*n*iif/length(f)) attempt at high freq decrease in n
    end
    for iif = 100:length(f) % 10000 Hz - 100000 Hz
        nl(i,iif) = 42 + (n *20* log10(ms(i))) - 16 * log10(f(iif)) ; %m = 1.6
    end
end
for i = 6 % wind > than 12 m/s
    for iif = 1:4 % 100-400 Hz
        nl(i,iif) = 47.4 + (n *20* log10(ms(i))) + 10 * log10(f(iif)) ; %m=1
    end
    for iif = 5:9 % 500-1000 Hz
        nl(i,iif) = 42 + (n *20* log10(ms(i))) - m*10 * log10(f(iif)) ;
    end
    for iif = 10:99 % 1000 Hz - 10000 Hz
        nl(i,iif) = 42 + (n *20* log10(ms(i))) - 16 * log10(f(iif)) ; %m = 1.6
    end
    for iif = 100:length(f) % 12000 Hz - 100000 Hz
        nfac = (depth/1000)*0.8*n*(iif-100)/length(f);
        nl(i,iif) = 42 + ((n - nfac) *20* log10(ms(i))) - 16 * log10(f(iif)); %m = 1.6
        %  no wind dependence > 10 kHz for > 15 m/s
    end
end
for i = 7:length(ms) % wind > than 12 m/s
    for iif = 1:4 % 100-400 Hz
        nl(i,iif) = 47.4 + (n *20* log10(ms(i))) + 10 * log10(f(iif)) ; %m=1
    end
    for iif = 5:9 % 500-1000 Hz
        nl(i,iif) = 42 + (n *20* log10(ms(i))) - m*10 * log10(f(iif)) ;
    end
    for iif = 10:59 % 1000 Hz - 10000 Hz
        nl(i,iif) = 42 + (n *20* log10(ms(i))) - 16 * log10(f(iif)) ; %m = 1.6
    end
    for iif = 60:length(f) % 9000 Hz - 100000 Hz
        nfac = (depth/1000)*1*n*(iif-60)/(length(f));
        nl(i,iif) = 42 + ((n - nfac) *20* log10(ms(i))) - 16 * log10(f(iif)) ; %m = 1.6
        %  no wind dependence > 10 kHz for > 15 m/s
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% depth dependance correction to Knudsen spectra
% numerically solve eqn (3)->(4) from Kurahshi and Gratta 2007
% or similarly eqn (10)->(12) Short 2005 IEEE
% depth of hydrophone:
h = depth;   % [meters
% start,end step angle [rad]
ti = 0;
to = pi/2;
dt = to/90;
% alpha -> sound absorbtion coefficient
alpha = 0.036 * f.^(3/2);    % [dB/km] f => [kHz]
% alpha * h
alphah = alpha * h/1000;
% e^-ah
eah = 10.^(-alphah/10);
% loop over angle (theta)
Joah = 0;
Joo= 0;
for t = ti:dt:to
    ct = cos(t);
    sct = sec(t);
    st = sin(t);
    po = ct * st;
    pc = po * eah.^sct;
    Joah = Joah + pc;
    Joo = Joo + po;
end
% depth dependance correction to Knudsen spectra
ddc = 10 .* log10(Joah ./ Joo);
kd = nl + ones(lenss,1)*ddc; % Only 25 percent of theoretical 
% ss = 1 is force = 2 etc
% Optional plot
% plot Knudsen curves
figure
for i = 1: length(ms)
    semilogx(1000*f, kd(i,:),'k','LineWidth',2);
    if i == 1
        hold on
    end
end
i=5;
semilogx(1000*f, kd(i,:),'r','LineWidth',2); % ss = 4 is log10(ms) = 1
% Thermal Noise curve
for iif = 1:length(f)
    nt(iif) = -15 + 20 * log10(f(iif));
end
semilogx(1000*f, nt,'k','LineWidth',2);
axis([100,100000,10,95]);
hold off
xlabel('Frequency [Hz]')
ylabel('Pressure Spectrum Level [dB re uPa^2/Hz]')
title(['Noise Model for ',num2str(depth),' m depth'])
grid on
end

