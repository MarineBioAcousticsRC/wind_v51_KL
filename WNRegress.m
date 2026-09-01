function [SlopeLR,OffSetLR,SlopeTS,OffSetTS,fTS] = WNRegress(...
    OutFolder,OutVsWind,Proj,Site,Depl,ttitle,depth,...
    wsfinal,mpwfinal,ptime,dnew,kd,ms,fs0,ifr,freq,dfreq,RegPlt)
% Calculate regression of Noise versus Wind speed
warning('off')
% RegPlt = 'on';  % turn on and off plotting in regression createfit
cutoff = 0.7; % log wind m/s as cutoff for regression 0.7 = 5 m/s
lifr = length(ifr);
%lms = length(ms);
SlopeLR= zeros(1,lifr); OffSetLR = zeros(1,lifr);
SlopeTS= zeros(1,lifr); OffSetTS = zeros(1,lifr);
fTS = zeros(1,lifr);
bad = zeros(1,lifr);
% TFCorrWS = zeros(lifr,lms);
% % bins for TFCorrWS
% lgms = log10(ms);
% binws = zeros(1,lms+1);
% for i = 2: lms
% binws(i) = (lgms(i-1) + lgms(i))/2;
% end
% binws(1) = -100; 
% binws(lms+1) = 100;
for ix = 1:length(ifr) % every kHz or every 100Hz or custom set of freq
    % choose freq band
    if (fs0 == 200000 || fs0 == 320000 || fs0 == 64000 || ...
            fs0 == 96000 || fs0 == 48000)
        fTS(ix) = ifr(ix)*1000;  %in Hz
        ip = find(freq > ifr(ix)*1000 - dfreq/2 & ...
        freq < ifr(ix)*1000 + dfreq/2 );
    elseif fs0 == 10000
        fTS(ix) = ifr(ix)*100;  %in Hz
        ip = find(freq > ifr(ix)*100 - dfreq/2 & ...
        freq < ifr(ix)*100 + dfreq/2 );
    end
    if isempty(ip)
        disp(' Check Frequency Bin Resolution of LTSA');
        return
    end
    % reduce sig figures to make times match
    xp = round(ptime .* 100)./100;
    xw = round(dnew' .* 100)./100;
    [~,inoise,iwind] = intersect(xp,xw);
    Xla = 'Log10(m/s';
    xlabel(Xla);
    Yla = 'dBPa^2/Hz';
    ylabel(Yla);
    Tit = [num2str(fTS(ix)),'Hz'];
    %
    logws = log10(wsfinal);
    mlogws = max(logws);
    %     Wbins = discretize(logws,binws);
    %     Wb1 = find(Wbins == 1);
%      MPTF{1} = mpwrtf(:,inoise(Wb1));
    % eliminate points below cutoff windspeed
    isok = find(logws > cutoff);
    logwsok = logws(isok);
    llogwsok = length(logwsok);
    lmpwrtfok = mpwfinal(ip,:);
    lmpwrtf = mpwfinal(ip,:);
    %
    [fitresult,~,std95,ir,irhigh] = createFit2(logwsok,lmpwrtfok);
    % Plot fit with data.
    if strcmp(RegPlt,'on')
        if ix == 1
            RFig = figure( 'Name', 'Regress Noise vs Log10Wind' );
            subplot(3,3,ix)
            for ims = 1 : length(ifr)-1
                plot(log10(ms),kd(:,ifr(ims)*10))
                hold on
                ax = gca;
                ax.XLim = ([0 mlogws]);  % JAH was 0.5 mlogws
                ax.YLim = ([20 80]);
            end
            title(ttitle);
        end
        figure(RFig);
        subplot(3,3,ix+1)
        plot(logws,lmpwrtf,'.k')
        hold on
        ax = gca;
        p = plot(fitresult, logwsok,lmpwrtfok, 'predobs' );
        legend('hide')
        set(p,'Linewidth',2)
        if ix < 5
            ax.YLim = ([60-(ix-1)*10 100-(ix-1)*10]);
        elseif ix == 5
            ax.YLim = ([30 70]);
        elseif ix == 6
            ax.YLim = ([30 60]);
        elseif ix == 7
            ax.YLim = ([30 60]);
        else
            ax.YLim = ([10 40]);
        end
        ax.XLim = ([0 mlogws]);  % JAH was 0.5 mlogws
        % Label axes
        xlabel(Xla)
        ylabel(Yla)
        title(Tit)
        hold on
        grid on
        % add model
        plot(log10(ms(1:11)),kd(1:11,ip),'y','Linewidth',2);
        plot(log10(ms(1:11)),kd(1:11,ip),':k','Linewidth',2);
    end
    %
    SlopeLR(ix)= fitresult.p1;
    OffSetLR(ix)= fitresult.p2;
    pcnt = 100.*(llogwsok - length(ir))./llogwsok;
    disp([num2str(fTS(ix)),' Hz  Removed = ',num2str(pcnt),...
        ' pcnt high residual >',num2str(std95),' dB']);
    % Theil Sen SLope on data < std95
    siz = size(logwsok(ir));
    if ( siz(1) < siz(2))
        dataMat = [logwsok(ir); lmpwrtfok(ir)];
    else
        dataMat = [logwsok(ir)'; lmpwrtfok(ir)];
    end
    [Slope,OffSet] = TheilSen(dataMat');
    SlopeTS(ix) = Slope;
    OffSetTS(ix) = OffSet;
    if SlopeTS(ix) < 15
        disp([Proj,' ',Site,' ',Depl,' ',num2str(depth),...
            ' BAD SLOPE ',num2str(SlopeLR(ix))])
        bad(ix) = 1;
    end
    dSlope = SlopeLR(ix)-SlopeTS(ix);
    if (abs(dSlope) > 2 )
        disp([Proj,' ',Site,' ',Depl,' ',num2str(depth),...
            ' SLOPE Difference ',num2str(dSlope)])
    end
end
% Save SS Figure
if strcmp(RegPlt,'on')
    VsWindfile = fullfile(OutFolder,'VsFreqVsWind',OutVsWind);
    savefig(RFig,VsWindfile)
end
end


%