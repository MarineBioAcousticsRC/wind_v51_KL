% Calculate regression of Noise versus Wind speed
clear
warning('off')
RegPlt = 'on';  % turn on and off plotting in regression createfit
% choose Frequency band
% band = 'mid';
band = 'low';
% get  file names and tf file name
[fn_f, fn_p] = uigetfile( 'Pick WindNoise files',...
    'MultiSelect','on');
RegPath = strrep(fn_p,'Output','Regress');
nfiles = length(fn_f);
c = cell(1);  index = 1;
for ifi = 1 : nfiles
    disp(fn_f{ifi});
    load([fn_p,fn_f{ifi}]);
    RegFile = strrep([fn_p,fn_f{ifi}],'Output','Regress');
    RegFile = strrep(RegFile,'WindNoise','Regress');
    %
%     x = .4 : .1 : .8;
    SlopeLR= []; OffSetLR=[];
    SlopeTS= []; OffSetTS=[];
    bad = 0;
    for i = 1 : 10 % every kHz or every 100Hz
       % choose freq band
        if strcmp(band,'mid')
            ip = i*10;
             fr(i) = i*1000;  %in Hz
        elseif strcmp(band,'low')
            ip = i;
             fr(i) = i*100;  %in Hz
        end
        % reduce sig figures to make times match
        xp = round(ptime .* 100)./100;
        xw = round(dnew' .* 100)./100;
        [~,inoise,iwind] = intersect(xp,xw);
        figure(99); % Wind versus Noise plot
        ax = gca;
        semilogx(wsnew(iwind),mpwrtf(ip+1,inoise)-(i*5),'.') %use 1 kHz noise
        ax.XLim = ([1 25]);
        hold on
        Xla = 'Log10(Wind Speed) m/s';
        xlabel(Xla);
        Yla = 'Pressure Spectrum Level [dB re uPa^2/Hz]';
        ylabel(Yla);
        title([Proj,' ',Site,' ',Depl])
        Tit = [Proj,' ',Site,' ',Depl,' ',num2str(fr(i)),'Hz'];
        logws = log10(wsnew);
        % eliminate points 
        isok = find(logws(iwind) > .7);
        logws = logws(iwind(isok));
        llogws = length(logws);
        lmpwrtf = mpwrtf((ip)+1,inoise(isok));
        %
        [fitresult,gof,std95,ir] = createFit2(logws,lmpwrtf,RegPlt, Xla, Yla, Tit);
        SlopeLR(i)= fitresult.p1;
        OffSetLR(i)= fitresult.p2;
        pcnt = 100.*(llogws - length(ir))./llogws;
        disp(['Removed = ',num2str(pcnt),...
            ' pcnt high residual >',num2str(std95),' dB']);
        % Theil Sen SLope
        dataMat = [logws(ir); lmpwrtf(ir)];
        [Slope,OffSet] = TheilSen(dataMat');
        SlopeTS= [SlopeTS, Slope];
        OffSetTS = [OffSetTS, OffSet];
        if (SlopeLR(i) < 9 && strcmp(band,'mid'))
            disp([Proj,' ',Site,' ',Depl,' ',num2str(depth),...
                ' BAD SLOPE ',num2str(SlopeLR(i))])
            bad = 1;
        end
        dSlope = SlopeLR(i)-SlopeTS(i);
        if (abs(dSlope) > 2 )
            disp([Proj,' ',Site,' ',Depl,' ',num2str(depth),...
                ' SLOPE Difference ',num2str(dSlope)])
        end
    end
    clf(99)
    if bad == 0
    save(RegFile,'Proj','Site','Depl','depth',...
        'SlopeLR','OffSetLR','SlopeTS','OffSetTS','fr');
    c{index} = {Proj,Site,Depl,depth,SlopeLR,OffSetLR,SlopeTS,OffSetTS,fr};
    index = index +1;
    else
        bad = 0;
    end
end
if (strcmp(band,'mid'))
    cmid = c;
    save(fullfile(RegPath,'RegOutMid'),'cmid');
elseif (strcmp(band,'low'))
    clow = c;
    save(fullfile(RegPath,'RegOutLow'),'clow');
end
close(99)

%