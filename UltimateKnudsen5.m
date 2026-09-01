%Ambient Noise Curve
%With Acknowldegement to Donald Ross and Gordon Wenz
%J Hildebrand 1-26-2008, 1-2020
%
clear all;
depth = 100;
% frequency in kHz
f = .1 : .1 : 100;
%make plot
FFig = figure;
x = 100:100000;
y = ones(size(x));
semilogx(x,y);
hold on;
grid on;
ms = [1, 2.5, 4.5, 6.7, 9.4, 12.3, 15.5, 19, 22.6, 26.5, 30.5];
ss = [.5, 1,2,3,4,5,6,7,8,9, 10];
fWi = [100, 500, 1000, 5000, 10000, 20000, 30000, 100000];
nl = zeros(length(ms),length(f));
% Approximation for Knudson curves
n = 0.5; m= 1; off = 50;
for iw = 1 % wind less than 1 m/s
    for iif = 1:4 % freq 100-400 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off+6.4 + (n*20* log10(ms(iw))) + 7 *m* log10(f(iif)) ;% m = 0.8
    end
    for iif = 5:9 % 500-900 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off+0.3 + (n*20* log10(ms(iw))) -  10.5*m* log10(f(iif)) ; %9.5
    end
    for iif = 10:40 %  1000 Hz - 4000 Hz
        if iif < 13
            ofac = exp(-depth/100)*10*(12-iif)/12;
        end
        nl(iw,iif) = ofac+ off+0.1 + (n*20* log10(ms(iw))) - 10.4 *m* log10(f(iif)) ; %m = 1.6
    end
    for iif = 41:100 %  4100 Hz - 10000 Hz
        nl(iw,iif) = off+2 + (n*20* log10(ms(iw))) - 13.5 *m* log10(f(iif)) ; %m = 1.6
    end
    for iif = 101:length(f) % > 10000 Hz
        nl(iw,iif) = off+2 + (n*20* log10(ms(iw))) - 13.5 *m* log10(f(iif)) ; %m = 1.6
    end
end
n = 1; m= 1; off = 50;
for iw = 2 % wind 1 - 2.5 m/s
    for iif = 1:4 % freq 100-400 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off+1.4 + (n*20* log10(ms(iw))) + 7 *m* log10(f(iif)) ;% m = 0.8
    end
    for iif = 5:9 % 500-900 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-4.7 + (n*20* log10(ms(iw))) - 10.7*m* log10(f(iif)) ;%11.5
    end
    for iif = 10:40 %  1000 Hz - 4000 Hz
        if iif < 13
            ofac = exp(-depth/100)*10*(12-iif)/12;
        end
        nl(iw,iif) = ofac +off-5 + (n*20* log10(ms(iw))) - 10.2 *m* log10(f(iif)) ; %m = 1.6
    end
    for iif = 41:100 %  4100 Hz - 10000 Hz
        nl(iw,iif) = off-3 + (n*20* log10(ms(iw))) - 13.5 *m* log10(f(iif)) ; %m = 1.6
    end
    for iif = 101:length(f) % > 10000 Hz
        nl(iw,iif) = off-3 + (n*20* log10(ms(iw))) - 13.5 *m* log10(f(iif)) ; %m = 1.6
    end
end
n = 1; m= 1; off = 50;
for iw = 3 % wind 2.5 - 4.5 m/s
    for iif = 1:4 % freq 100-400 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-1 + (n*20* log10(ms(iw))) + 7 *m* log10(f(iif)) ;% m = 0.8
    end
    for iif = 5:9 % 500-900 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-6.8 + (n*20* log10(ms(iw))) - 10*m* log10(f(iif)) ;%9.3
    end
    for iif = 10:40 %  1000 Hz - 4000 Hz
        if iif < 13
            ofac = exp(-depth/100)*10*(12-iif)/12;
        end
        nl(iw,iif) = ofac +off-7 + (n*20* log10(ms(iw))) - 8.7 *m* log10(f(iif)) ; %m = 1.6
    end
    for iif = 41:100 %  4100 Hz - 10000 Hz
        nl(iw,iif) = off-4 + (n*20* log10(ms(iw))) - 13.5 *m* log10(f(iif)) ; %m = 1.6
    end
    for iif = 101:length(f) % > 10000 Hz
        nl(iw,iif) = off-4. + (n*20* log10(ms(iw))) - 13.5 *m* log10(f(iif)) ; %m = 1.6
    end
end
n = 1.25; m= 1; off = 40;
for iw = 4 % wind 4.5 - 6.7 m/s
    for iif = 1:4 % 100-400 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off+3. + (n *22* log10(ms(iw))) + 7 *m* log10(f(iif)) ; %m=1
    end
    for iif = 5:9 % 500-900 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-0.1 + (n *20* log10(ms(iw))) -  7*m* log10(f(iif)) ;%7.5
    end
    for iif = 10:40 % 1000 Hz - 4000 Hz
        if iif < 13
            ofac = exp(-depth/100)*10*(12-iif)/12;
        end
        nl(iw,iif) = ofac +off-0.4 + (n *20* log10(ms(iw))) - 10.2 *m* log10(f(iif)) ; %m = 1.6
    end
    n = 1.0;
    for iif = 41:200 % 4100 Hz - 20000 Hz
        nl(iw,iif) = off+5.75 + (n *20* log10(ms(iw))) - 13.5 *m* log10(f(iif)) ; %m = 1.6
    end
    for iif = 201:length(f) % 20000 Hz - 100000 Hz
        nfac = (depth/1000+ 0.04*exp(-depth/400))*0.3*n*(iif-201)/length(f);
        nl(iw,iif) = off+5.7 + ((n - nfac) *20* log10(ms(iw))) - 13.5 *m* log10(f(iif));%m = 1.6
    end
end
n=1.25; m= 1; off = 40;
for iw = 5 % wind 6.7 - 9.4 m/s
    for iif = 1:4 % 100-400 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off+1.1 + (n *23* log10(ms(iw))) + 7 *m* log10(f(iif)) ; %m=1
    end
    for iif = 5:9 % 500-900 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off+0 + (n *20* log10(ms(iw))) - 6*m* log10(f(iif)) ;%5
    end
    for iif = 10:40 % 1000 Hz - 4000 Hz
        if iif < 13
            ofac = exp(-depth/100)*10*(12-iif)/12;
        end
        nl(iw,iif) = ofac +off-0.3 + (n *20* log10(ms(iw))) - 12.5 *m* log10(f(iif)) ; %m = 1.6
    end
    n = 1.0;
    for iif = 41:200 % 4100 Hz - 20000 Hz
        nl(iw,iif) = off+5.5 + (n *20* log10(ms(iw))) - 14 *m* log10(f(iif)) ; %m = 1.6
    end
    for iif = 201:length(f) % 20000 Hz - 100000 Hz
        nfac = (depth/1000+ 0.08*exp(-depth/400))*0.3*n*(iif-201)/length(f);
        nl(iw,iif) = off+5.5 + ((n - nfac) *20* log10(ms(iw))) - 14 *m* log10(f(iif));%m = 1.6
    end
end
n=1.25; m= 1; off = 40;
for iw = 6 % wind 9.4 - 12.3 m/s
    for iif = 1:4 % 100-400 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off+0.25 + (n *23* log10(ms(iw))) + 7 *m* log10(f(iif)) ; %m=1
    end
    for iif = 5:9 % 500-900 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-0.12 + (n *20* log10(ms(iw))) - 6*m* log10(f(iif)) ;
    end
    for iif = 10:40 % 1000 Hz - 4000 Hz
        if iif < 13
            ofac = exp(-depth/100)*10*(12-iif)/12;
        end
        nl(iw,iif) = ofac +off-0.3 + (n *20* log10(ms(iw))) - 13.7 *m* log10(f(iif)) ; %m = 1.6
    end
    n = 1.0;
    for iif = 41:100 % 4100 Hz - 10000 Hz
        nl(iw,iif) = off+5.6 + (n *20* log10(ms(iw))) - 14.5 *m* log10(f(iif)) ; %m = 1.6
    end
    for iif = 101:length(f) % 10000 Hz - 100000 Hz
        nfac = (depth/1000+ 0.17*exp(-depth/400))*0.7*n*(iif-101)/length(f);
        nl(iw,iif) = off+5.65 + ((n - nfac) *20* log10(ms(iw))) - 14.5 *m* log10(f(iif)); %m = 1.6
        %  no wind dependence > 10 kHz for > 15 m/s
    end
end
n=1.25; m= 1; off = 40;
for iw = 7 % wind > than 12 m/s
    for iif = 1:4 % 100-400 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-0.4 + (n *23* log10(ms(iw))) + 7 *m* log10(f(iif)) ; %m=1
    end
    for iif = 5:9 % 500-900 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-.3 + (n *20* log10(ms(iw))) - 5*m* log10(f(iif)) ;
    end
    for iif = 10:40 % 1000 Hz - 4000 Hz
        if iif < 13
            ofac = exp(-depth/100)*10*(12-iif)/12;
        end
        nl(iw,iif) = ofac +off-.3 + (n *20* log10(ms(iw))) - 14.5 *m* log10(f(iif)) ; %m = 1.6
    end
    n = 1.0;
    for iif = 41:61 % 4100 Hz - 6000 Hz
        nl(iw,iif) = off+5.75 + (n *20* log10(ms(iw))) - 14.5 *m* log10(f(iif)) ; %m = 1.6
    end
    for iif = 62:length(f) % 6000 Hz - 100000 Hz
        nfac(iif) = (depth/1000+ 0.24*exp(-depth/400))*1.2*n*(iif-62)/(length(f));
        nl(iw,iif) = off+5.85 + ((n - nfac(iif)) *20* log10(ms(iw))) - 14.5 *m* log10(f(iif)) ; %m = 1.6
    end
end
n=1.25; m= 1; off = 40;
for iw = 8 % wind > than 12 m/s
    for iif = 1:4 % 100-400 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-0.65 + (n *23* log10(ms(iw))) + 7 *m* log10(f(iif)) ; %m=1
    end
    for iif = 5:9 % 500-900 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-.3 + (n *20* log10(ms(iw))) - 6*m * log10(f(iif)) ;
    end
    for iif = 10:40 % 1000 Hz - 4000 Hz
        if iif < 13
            ofac = exp(-depth/100)*10*(12-iif)/12;
        end
        nl(iw,iif) = ofac +off-.3 + (n *20* log10(ms(iw))) - 14.5 *m* log10(f(iif)) ; %m = 1.6
    end
    n = 1.0;
    for iif = 41:length(f) % 4100 Hz - 100000 Hz
        nfac(iif) = (0.6*exp(-depth/400) + depth/1000)*1.8*n*(iif-41)/(length(f));
        nl(iw,iif) = off+6.1 + ((n - nfac(iif)) *20* log10(ms(iw))) - 14.5 *m* log10(f(iif)) ; %m = 1.6
        %  no wind dependence > 10 kHz for > 15 m/s
    end
end
n=1.25; m= 1; off = 40;
for iw = 9 % wind > than 12 m/s
    for iif = 1:4 % 100-400 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-0.9 + (n *23* log10(ms(iw))) + 7 *m* log10(f(iif)) ; %m=1
    end
    for iif = 5:9 % 500-900 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-.3 + (n *20* log10(ms(iw))) - 6*m* log10(f(iif)) ;
    end
    for iif = 10:40 % 1000 Hz - 4000 Hz
        if iif < 13
            ofac = exp(-depth/100)*10*(12-iif)/12;
        end
        nl(iw,iif) = ofac +off-.3 + (n *20* log10(ms(iw))) - 14.5 *m* log10(f(iif)) ; %m = 1.6
    end
    n= 1.0;
    for iif = 41:length(f) % 4100 Hz - 100000 Hz
        nfac(iif) = (depth/1000+ 1*exp(-depth/400))*2.2*n*(iif-41)/(length(f));
        nl(iw,iif) = off+6.4 + ((n - nfac(iif)) *20* log10(ms(iw))) - 14.5 *m* log10(f(iif)) ; %m = 1.6
        %  no wind dependence > 10 kHz for > 15 m/s
    end
end
n=1.25; m= 1; off = 40;
for iw = 10 % wind > than 12 m/s
    for iif = 1:4 % 100-400 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-1.15 + (n *23* log10(ms(iw))) + 7 *m* log10(f(iif)) ; %m=1
    end
    for iif = 5:9 % 500-900 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-.3 + (n *20* log10(ms(iw))) - 6*m* log10(f(iif)) ;
    end
    for iif = 10:40 % 1000 Hz - 4000 Hz
        if iif < 13
            ofac = exp(-depth/100)*10*(12-iif)/12;
        end
        nl(iw,iif) = ofac +off-.3 + (n *20* log10(ms(iw))) - 14.5 *m* log10(f(iif)) ; %m = 1.6
    end
    n=1.0;
    for iif = 41:length(f) % 4100 Hz - 100000 Hz
        nfac(iif) = (depth/1000+ 1.6*exp(-depth/400))*2.5*n*(iif-41)/(length(f));
        nl(iw,iif) = off+6.85 + ((n - nfac(iif)) *20* log10(ms(iw))) - 14.5 *m* log10(f(iif)) ; %m = 1.6
        %  no wind dependence > 10 kHz for > 15 m/s
    end
end
n=1.25; m= 1; off = 40;
for iw = 11 % wind > than 12 m/s
    for iif = 1:4 % 100-400 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-1.5 + (n *23* log10(ms(iw))) + 7 *m* log10(f(iif)) ; %m=1
    end
    for iif = 5:9 % 500-900 Hz
        ofac = exp(-depth/100)*10*(12-iif)/12;
        nl(iw,iif) = ofac + off-.3 + (n *20* log10(ms(iw))) - 6*m* log10(f(iif)) ;
    end
    for iif = 10:40 % 1000 Hz - 4000 Hz
        if iif < 13
            ofac = exp(-depth/100)*10*(12-iif)/12;
        end
        nl(iw,iif) = ofac +off-.3 + (n *20* log10(ms(iw))) - 14.5 *m* log10(f(iif)) ; %m = 1.6
    end
    n = 1.0;
    for iif = 41:length(f) % 4100 Hz - 100000 Hz
        nfac(iif) = (depth/1000+ 1.8*exp(-depth/400))*2.7*n*(iif-41)/(length(f));
        nl(iw,iif) = off+7.15 + ((n - nfac(iif)) *20* log10(ms(iw))) - 14.5 *m* log10(f(iif)) ; %m = 1.6
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
kd = nl + ones(length(ms),1)*ddc; % theoretical noise level with ss
% 15 percent of the theoretical depth correction

% plot Knudsen curves
for i = 1: length(ms)
    semilogx(1000*f, kd(i,:),'k','LineWidth',2);
end
i=5;
semilogx(1000*f, kd(i,:),'r','LineWidth',2); % ss = 5 is log10(ms) = 1
% Thermal Noise curve
nt = zeros(1,length(f));
for iif = 1:length(f)
    nt(iif) = -15 + 20 * log10(f(iif));
end
semilogx(1000*f, nt,'k','LineWidth',2);
axis([100,100000,10,95]);
%legend('show','Location','northeast')
%
% %combine kd and nt
for j = 1 : length(kd(:,1))
    for i = 1 : length(nt)
        if kd(j,i) < nt(i)
            kd(j,i) = nt(i);
        end
    end
end
%
% % Wind speed curves
WFig = figure;
for i = 1 : length(fWi)
    plot(log10(ms),kd(:,fWi(i)/100),'LineWidth',2,'DisplayName',...
        num2str(fWi(i)))
    hold on
    %     plot(log10(ms),kd(:,fWi(i)/100),'LineWidth',2)
end
legend('show','Location','northwest')
%
ncol = zeros(11000,1);
x = ncol;
y = ncol;
ix = 1;
for i = 1 : length(ms)
    for j = 1 : length(f)
        x(ix) = ms(i);
        y(ix) = f(j);
        ncol(ix) = nl(i,j);
        ix = ix + 1;
    end
end
% %
% figure(FFig);
% %Nystuen for shallow water
% ref = ['Nystuen'];
% % just above ss3
% wdata = [7, 7];
% lwdata = log10(wdata);
% ndata = [62,46];
% fdata = [1000,10000];
% semilogx(fdata,ndata,':g','Linewidth',3);
% % just above ss2
% wdata = [5, 5];
% lwdata = log10(wdata);
% ndata = [58,42.5];
% fdata = [1000,10000];
% semilogx(fdata,ndata,':g','Linewidth',3);
% % just above ss1
% wdata = [3, 3];
% lwdata = log10(wdata);
% ndata = [54,38.5];
% fdata = [1000,10000];
% semilogx(fdata,ndata,':g','Linewidth',3);
% % legend('show')
% %Ross BTL 1954 For deep water
% % ref = ['Ross'];
% % % ss6
% % wdata = [15.5, 15.5];
% % lwdata = log10(wdata);
% % ndata = [68,51];
% % fdata = [1000,10000];
% % semilogx(fdata,ndata,':b','Linewidth',3);
% % % ss4
% % wdata = [9.4, 9.4];
% % lwdata = log10(wdata);
% % ndata = [64,46];
% % fdata = [1000,10000];
% % semilogx(fdata,ndata,':b','Linewidth',3);
% % % ss3
% % wdata = [6.7, 6.7];
% % lwdata = log10(wdata);
% % ndata = [61,43];
% % fdata = [1000,10000];
% % semilogx(fdata,ndata,':b','Linewidth',3);
% % % ss2
% % wdata = [4.5, 4.5];
% % lwdata = log10(wdata);
% % ndata = [58,40];
% % fdata = [1000,10000];
% % semilogx(fdata,ndata,':b','Linewidth',3);
% % % ss1
% % wdata = [2.5, 2.5];
% % lwdata = log10(wdata);
% % ndata = [54,35];
% % fdata = [1000,10000];
% % semilogx(fdata,ndata,':b','Linewidth',3);
% WFig = figure;
% % hold on
% 500 Hz
txt = ['\leftarrow ',num2str(1)];
text(0,53.5,txt)
txt = ['\leftarrow ',num2str(2)];
text(0.4,56.5,txt)
txt = ['\leftarrow ',num2str(3)];
text(0.65,60.6,txt)
txt = ['\leftarrow ',num2str(4)];
text(0.83,63.75,txt)
txt = ['\leftarrow ',num2str(5)];
text(0.97,66.53,txt)
txt = ['\leftarrow ',num2str(6)];
text(1.09,68.95,txt)
txt = ['\leftarrow ',num2str(7)];
text(1.19,70.96,txt)
% mod 500 Hz
txt = ['\leftarrow X'];% 3 d=1.5
text(0.64,59.1,txt)
txt = ['\leftarrow X'];% 4 d=1
text(0.83,62.75,txt)
txt = ['\leftarrow X'];% 5 d= 0.5
text(0.97,66.03,txt)
% % 1000 Hz
% txt = ['\leftarrow ',num2str(1)];
% text(0,51.99,txt)
% txt = ['\leftarrow ',num2str(2)];
% text(0.4,54.95,txt)
% txt = ['\leftarrow ',num2str(3)];
% text(0.65,59.06,txt)
% txt = ['\leftarrow ',num2str(4)];
% text(0.83,62.24,txt)
% txt = ['\leftarrow ',num2str(5)];
% text(0.97,65.02,txt)
% txt = ['\leftarrow ',num2str(6)];
% text(1.09,67.44,txt)
% txt = ['\leftarrow ',num2str(7)];
% text(1.19,69.45,txt)
% mod 1000 Hz
txt = ['\leftarrow *'];
text(0.4,52.95,txt)
txt = ['\leftarrow *'];
text(0.65,56.06,txt)
txt = ['\leftarrow *'];
text(0.83,60.24,txt)
txt = ['\leftarrow *'];
text(0.97,64.02,txt)
txt = ['\leftarrow *'];
text(1.09,67,txt)
% 5000 Hz
txt = ['\leftarrow ',num2str(1)];
text(0,42.49,txt)
txt = ['\leftarrow ',num2str(2)];
text(0.4,45.44,txt)
txt = ['\leftarrow ',num2str(3)];
text(0.65,49.55,txt)
txt = ['\leftarrow ',num2str(4)];
text(0.83,52.76,txt)
txt = ['\leftarrow ',num2str(5)];
text(0.97,55.1,txt)
txt = ['\leftarrow ',num2str(6)];
text(1.09,57.18,txt)
txt = ['\leftarrow ',num2str(7)];
text(1.19,59.34,txt)
%20000 Hz
txt = ['\leftarrow ',num2str(7)];
text(1.19,49.8,txt)
txt = ['\leftarrow o'];
text(1.19,48.8,txt)
txt = ['\leftarrow ',num2str(8)];
text(1.279,51.5,txt)
txt = ['\leftarrow o'];
text(1.279,49.5,txt)
txt = ['\leftarrow ',num2str(9)];
text(1.354,49.28,txt)
txt = ['\leftarrow o'];
text(1.354,46.28,txt)
%30000 Hz
txt = ['\leftarrow ',num2str(9)];
text(1.354,43.28,txt)
txt = ['\leftarrow o'];
text(1.354,39.28,txt)
% txt = ['\leftarrow Freq ',num2str(fWi(1))];
% text(0.05,56,txt)
% linex = [.7 , .7];
% liney = [20, 80];
% plot(linex,liney,'Linewidth',3);
% linex = [1.2, 1.2];
% plot(linex,liney,'Linewidth',3);