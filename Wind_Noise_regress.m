clear
OutFolder = 'H:\Wind_TF\Output';
% get  file names and tf file name
[fn_files, fn_pathname] = uigetfile( 'Pick WindNoise files',...
    'MultiSelect','on');
% Proj = 'SOCAL';
% Site = 'CINMSC';
% Short = 'C';
% Depl = '17';
nfiles = length(fn_files);
for i = 1 : nfiles
    load([OutFolder,'\',Proj,Site,Depl,'_WindNoise.mat']);
    RegPath = fullfile('H:\Wind_TF\Regress',[Proj,Site,Depl,'_',...
        harpDataSummary.Depth_m{deplMatchIdx},'_Reg.mat']);
    %
    x = .4 : .1 : .8;
    SlopeLR= []; OffSetLR=[];
    SlopeTS= []; OffSetTS=[];
    for i = 1 : 10 % every kHz
        %y = -100*(x - .7) + 42;
        % reduce sig figures to make times match
        xp = round(ptime .* 100)./100;
        xw = round(dnew' .* 100)./100;
        [~,inoise,iwind] = intersect(xp,xw);
        figure(99); % Wind versus Noise plot
        ax = gca;
        semilogx(wsnew(iwind),mpwrtf(i*10+1,inoise)-(i*5),'.') %use 1 kHz noise
        ax.XLim = ([1 14]);
        hold on
        xlabel('Wind Speed m/s');
        ylabel('Pressure Spectrum Level [dB re uPa^2/Hz]');
        logws = log10(wsnew);
        % eliminate points above line
        %     isok = find(mpwrtf((i*10)+1,inoise) > ...
        %         (-80*(logws(iwind) - .7) + (52 - i)));
        isok = find(logws(iwind) > .7);
        %range for wind speed ss1 and above
        %     isokw = find( wsnew(iwind) > 1.6 );
        logws = logws(iwind(isok));
        lmpwrtf = mpwrtf((i*10)+1,inoise(isok));
        %
        %     plot(logws,lmpwrtf,'o') %use 1 kHz noise
        %     hold on
        [fitresult, gof] = createFit2(logws, lmpwrtf);
        SlopeLR(i)= fitresult.p1;
        OffSetLR(i)= fitresult.p2;
        fr(i) = i;
        % Theil Sen SLope
        dataMat = [logws; lmpwrtf];
        [Slope,OffSet] = TheilSen(dataMat');
        SlopeTS= [SlopeTS, Slope];
        OffSetTS = [OffSetTS, OffSet];
        %     WNRegress = {
    end
    save(RegPath,'Proj','Site','Depl','depth',...
        'SlopeLR','OffSetLR','SlopeTS','OffSetTS','fr');
end