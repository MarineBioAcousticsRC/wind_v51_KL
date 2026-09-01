% theoreticalOceanNoise.m
% 080423 smw
%
% from Don Ross Notes:
% + 56 dB re uPa^2 / Hz
% + 19*log10(ss) for 0.5 < seastate (ss) < 6
% - 17*log10(f) for 0.5 kHz < freqeuncy (f) < 25 kHz (ie Knudsen)
% ss = 1:1:6;
ss = [0.5,1:1:6];
lenss = length(ss);
f = 1:1:100;
lenf = length(f);

a = 56.*ones(lenss,lenf);
b = (19*log10(ss))'*ones(1,lenf);
c = ones(lenss,1) * (-17*log10(f));
% Pressure Spectrum Level (power)
p = a + b + c;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% depth dependance correction to Knudsen spectra
%
% numerically solve eqn (3)->(4) from Kurahshi and Gratta 2007
% or similarly eqn (10)->(12) Short 2005 IEEE
%
% 080307 smw
% depth of hydrophone:
h = 1000;   % [meters]
% surface dipole n = 2
% n = 2;  % not really used, just take cosine below
% start, end, step frequencies [kHz]
% fi = 10;
% fo = 100;
% df = 1;
% start,end step angle [rad]
ti = 0;
to = pi/2;
dt = to/90;
%
count = 0;
% loop over frequencies
% for f = fi:df:fo
% counter
count = count + 1;
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
%     ddc(count) = 10 .* log10(Joah ./ Joo);
ddc = 10 .* log10(Joah ./ Joo);
% end


figure(11)
% plot(f,p)
semilogx(f.*1000,p)
xlabel('Frequency [Hz]')
ylabel('Pressure Spectrum Level [dB re uPa^2/Hz]')
title('Theoretical Ambient Ocean Noise')
grid on
v = [10 2e5 0 90];
axis(v)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(12)
% fplt = 1000.*[fi:df:fo];
% semilogx(fplt,ddc)
semilogx(f.*1000,ddc)
xlabel('Frequency [Hz]')
ylabel('Correction [dB]')
str = [];
str{1} = 'Depth Dependance Correction to Knudsen Spectra';
str{2} = ['Depth = ',num2str(h),' meters'];
title(str)
grid on
v = [10 2e5 -80 10];
axis(v)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(13)
% kd = p + ones(6,1)*ddc;
kd = p + ones(7,1)*ddc;
semilogx(f.*1000,kd,f.*1000,Ln,'k')
hold on
semilogx(f.*1000,p,'--')
hold off
xlabel('Frequency [Hz]')
ylabel('Pressure Spectrum Level [dB re uPa^2/Hz]')
str{1} = 'Theoretical Ambient Ocean Noise';
str{2} = 'Knudsen (ss = 0.5 - 6) + Depth Dependance';
str{3} = ['Depth = ',num2str(h),' meters'];
title(str)
grid on
legend(num2str(ss'))
ang = 20;
text(5e3,2,'Water Molecular','Rotation',ang)
text(5e3,-3,'Thermal Noise','Rotation',ang)
% v = [1 2e5 -10 80];
v = [1e3 1e5 -10 80];
axis(v)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(14)
os1 = 70;
semilogx(f.*1000,os1-kd)
xlabel('Frequency [Hz]')
ylabel('Gain')
str{1} = 'Optimal Gain for Theoretical Ambient Ocean Noise';
str{2} = 'Knudsen (ss = 0.5 - 6) + Depth Dependance';
str{3} = ['Depth = ',num2str(h),' meters'];
title(str)
grid on
v = [1 2e5 -10 80];
axis(v)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(15)
% kd = p + ones(6,1)*ddc;
kd = p + ones(7,1)*ddc;
plot(f.*1000,kd,f.*1000,Ln,'k')
xlabel('Frequency [Hz]')
ylabel('Pressure Spectrum Level [dB re uPa^2/Hz]')
str{1} = 'Theoretical Ambient Ocean Noise';
str{2} = 'Knudsen (ss = 0.5 - 6) + Depth Dependance';
str{3} = ['Depth = ',num2str(h),' meters'];
title(str)
grid on
% v = [1 2e5 -10 80];
v = [1e3 50e3 -10 80];
axis(v)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add to plot to inverse sensitivity plot
figure(20)
os2 = 15;
I = find(Ln>kd(1,:));
out = kd(1,:);
out(I) = Ln(I);
semilogx(f.*1000,out+os2)
