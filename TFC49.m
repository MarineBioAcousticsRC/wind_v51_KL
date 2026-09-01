function [] = TFC49(TFCorr)
% make TF Correction
%Moved to function July 2021
itf = itf + 1;
if strcmp(p.FrePlt,'on')
    if iplot ==1
        ssFig = figure(6); clf;
    end
    figure(ssFig);
    subplot(4,2,iplot)  % 8 subplots = 4 x 2
    semilogx(freq(5:nf),MPTF{i}(5:nf,:)); % from 200 Hz to 30 kHz
    hold on
    semilogx(freqm(3:41),MPTFm{i}(3:41,:)); % from 20 Hz to 200 Hz
    semilogx(1000*fnm,kdp(i,:),'r','LineWidth',3); % theory as a line
    semilogx(freq(5:nf),AM(4:nf-1),'k','Linestyle',':','LineWidth',3); % from 200 Hz to 30 kHz
    semilogx(freqm(3:41),AMm(2:40),'k','Linestyle',':','LineWidth',3); % from 20 Hz to 100 Hz
    grid on
    ftxt =['Beaufort Force' ,num2str(ss(i))];
    text(1000,94,ftxt)
    v = [20 10e4 25 110];
    xticks([10 100 1000 10000 100000])
    axis(v)
    if iplot > 6
        xlabel('Frequency [Hz]')
    end
    if any(iplot == [1,3,5,7])
        ylabel('dB re uPa^2/Hz')
    end
    iplot = iplot + 1;
    % low freq plot
    if iplotl ==1
        ssFigl = figure(60); clf;
    end
    figure(ssFigl);
    subplot(4,2,iplotl)  % 8 subplots = 4 x 2
    semilogx(freq(5:nf),MPTF{i}(5:nf,:)); % from 400 Hz to 100 kHz
    hold on
    semilogx(freql(2:401),MPTFl{i}(2:401,:)); % from 10 Hz to 400 Hz
    semilogx(1000*fnm,kdp(i,:),'r','LineWidth',3); % theory as a line
    semilogx(freq(5:nf),AM(4:nf-1),'k','Linestyle',':','LineWidth',3); % from 400 Hz to end
    semilogx(freql(2:401),AMl(1:400),'k','Linestyle',':','LineWidth',3); % from 10 Hz to 400 Hz
    grid on
    ftxt =['Beaufort Force' ,num2str(ss(i))];
    text(700,94,ftxt)
    v = [10 10e4 25 110];
    xticks([10 100 1000 10000 100000])
    axis(v)
    if iplotl > 6
        xlabel('Frequency [Hz]')
    end
    if any(iplotl == [1,3,5,7])
        ylabel('dB re uPa^2/Hz')
    end
    iplotl = iplotl + 1;
    % low only freq plot
    if iplotlo ==1
        ssFiglo = figure(600); clf;
    end
    figure(ssFiglo);
    subplot(4,2,iplotlo)  % 8 subplots = 4 x 2
    semilogx(freql(2:1001),MPTFl{i}(2:1001,:)); % from 10 Hz to 400 Hz
    hold on
    semilogx(1000*fnm,kdp(i,:),'r','LineWidth',3); % theory as a line
    semilogx(freql(2:1001),AMl(1:1000),'k','Linestyle',':','LineWidth',3); % from 10 Hz to 400 Hz
    grid on
    ftxt =['Beaufort Force' ,num2str(ss(i))];
    text(70,94,ftxt)
    v = [10 1000 50 110];
    xticks([10 100 1000])
    axis(v)
    if iplotlo > 6
        xlabel('Frequency [Hz]')
    end
    if any(iplotlo == [1,3,5,7])
        ylabel('dB re uPa^2/Hz')
    end
    iplotlo = iplotlo + 1;
end
