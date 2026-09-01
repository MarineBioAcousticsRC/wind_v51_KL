% WindTimeSeriesv4.m
% KL 260804 - updated to run faster. Based off of WindTimeSeriesv3z.m
% KL 260806 - added site vs. CCMP grid-point check figure
%           - user input pulled to top; supports looping multiple sites
%             within the same region over the same year range(s)
%
% Jah Extract Wind time series from CCMP data
% Oct 2021 added ERA5 option
% added 2004 in Aug 2022
% Oct 8, 2019
%
% --- Aug 2026: performance pass ---
% 1) Was reading the FULL global uwnd/vwnd grid (ncread with no
%    start/count) for every single day just to pull out one point.
%    Now uses the low-level netcdf.* interface with start/count so only
%    the single grid cell x 4 timesteps is transferred, which matters a
%    lot since files live on a network drive (Z:).
% 2) Each file used to be opened twice (once per variable) via two
%    separate high-level ncread calls. Now opens the file once with
%    netcdf.open and reads both variables off the same file handle,
%    halving the per-file network open overhead.
% 3) Day loop used to run 1:31 every month and rely on CCMP_Variant
%    returning 'n' for invalid dates (e.g. Feb 30/31). Now bounded with
%    eomday(yr,month) so it never attempts invalid dates.
% Logic/outputs are otherwise unchanged from the original.
%
clear;

%% ========================== USER INPUT ============================= %%
yearRange = 2024:2025;      % <-- deployment year(s). e.g. 2016:2018, or [2017 2019] - for single year, can do 2017:2017
Proj      = 'GofMX';          % <-- region
sites = {'Y5B','Y5C','Y5D','SF','SJ'};
% sites     = {'HP','PR','SW','SZ'};         % <-- one or more site names, e.g. {'HP','PR','SW'}

outpath = 'C:\Users\Kieran Lenssen\Documents\GitHub\KLcode\wind\WindTimeSeries_Results'; % where to save processed data

%% ======================== END USER INPUT ============================ %%

wmod = 'CCMP';
drivelet = 'Z'; % mounted frosty drive 
pre = [drivelet,':\Wind_deltaTF\Wind_Model\CCMP\']; % where raw wind model data lives
pre0 = '\v11l30_2004';
mid0 = '\analysis_';
post0 = '_v11l30flk.nc';
mid1 = '\CCMP_Wind_Analysis_';
post1 = '_V02.0_L3.0_RSS.nc';
mid2 = '\CCMP_RT_Wind_Analysis_';
post2 = '_V02.1_L3.0_RSS.nc';

% wmod = 'ERA5';
% pre = 'H:\Wind_Model\ERA5\';
% mid = '\';
% post = '.nc';

for yr = yearRange
        year = num2str(yr);
    for iSite = 1:numel(sites)
        site = sites{iSite};
    
        outdir = fullfile(outpath,Proj,num2str(yr));  % Output file directory
    if ~isfolder(outdir)
            disp(['Make new folder: ',outdir])
            mkdir(outdir);
    end
        disp([Proj,site,' ',year]);
    % deployment locations for each site
         [slat,slon] = WhichProjSite(Proj,site);
    % convert to East Lon
        slon = 360 - slon;
    %pre = '/Volumes/CzikoAudio1/WIND/CCMP/';
    %pre = '/Users/jah 1 2/Ddirectory/Whale/WIND/CCMP/';
    % get latitude and longitude loction from first file
        [f,mid,post,lat,lon] = CCMP_Variant(...
            pre,pre0,year,'01','01',mid0,mid1,mid2,post0,post1,post2);
    % find point near deployment site
        slat25 = (round((slat+.125) * 4))/4 - .125;
        slon25 = (round((slon+.125) * 4))/4 - .125;
    % Difference with wind site?
        disp([' Del-Lat = ',num2str(slat - slat25),' deg']);
        disp([' Del-Lon = ',num2str(slon - slon25),' deg']);
        ilat = find(lat == slat25);
        ilon = find(lon == slon25);
    % --- Site vs. CCMP grid-point check figure ---
    % Quick visual sanity check, run before the (slow) day loop below, showing
    % the desired deployment location against the actual CCMP grid point being
    % pulled: a zoomed-in view of the grid cells themselves (with the other
    % nearby CCMP points and their cell boundaries), and a zoomed-out regional
    % view for broader context.
        to_std_lon = @(x) x - 360*(x>180); % East 0-360 -> standard signed lon
        slon_std    = to_std_lon(slon);
        slon25_std  = to_std_lon(slon25);
        lon_std_all = to_std_lon(lon); % full CCMP lon axis, standard convention
    % great-circle offset between desired site and grid point used
        R_km = 6371;
        dLat = deg2rad(slat25 - slat);
        dLon = deg2rad(slon25_std - slon_std);
        ahav = sin(dLat/2)^2 + cos(deg2rad(slat))*cos(deg2rad(slat25))*sin(dLon/2)^2;
        dist_km = 2*R_km*atan2(sqrt(ahav),sqrt(1-ahav));
        figLoc = figure('Name',[Proj,site,' Site vs CCMP grid point']);
    % zoomed-in panel: nearby CCMP grid points with their 0.25-deg cell
    % boundaries, and the specific cell actually used highlighted
        subplot(1,2,1)
        hold on
        buf = 0.6; % deg, half-width of the zoomed-in view
        searchBuf = buf + 0.2; % a bit wider so edge cells aren't cut off
        nearLonIdx = find(lon_std_all >= slon25_std-searchBuf & lon_std_all <= slon25_std+searchBuf);
        nearLatIdx = find(lat >= slat25-searchBuf & lat <= slat25+searchBuf);
        hOther = gobjects(0);
    for iLa = nearLatIdx(:)'
    for iLo = nearLonIdx(:)'
    if iLa == ilat && iLo == ilon
    continue % the used cell is drawn separately below, on top
    end
                cLon = lon_std_all(iLo);
                cLat = lat(iLa);
                rectangle('Position',[cLon-.125, cLat-.125, .25, .25], ...
    'EdgeColor',[.75 .75 .75]);
                hOther(end+1) = plot(cLon,cLat,'.','Color',[.6 .6 .6],'MarkerSize',14); %#ok<AGROW>
    end
    end
        rectangle('Position',[slon25_std-.125, slat25-.125, .25, .25], ...
    'EdgeColor','b','LineWidth',2);
        hDesired = plot(slon_std,slat,'rx','MarkerSize',12,'LineWidth',2);
        hUsed = plot(slon25_std,slat25,'bo','MarkerSize',10,'LineWidth',2);
        legHandles = [hDesired, hUsed];
        legLabels = {'Desired site','CCMP point used'};
    if ~isempty(hOther)
            legHandles = [legHandles, hOther(1)];
            legLabels = [legLabels, {'Other CCMP points'}];
    end
        legend(legHandles, legLabels, 'Location','southoutside')
        axis equal
        xlim([slon25_std-buf, slon25_std+buf]);
        ylim([slat25-buf, slat25+buf]);
        xlabel('Longitude (deg)'); ylabel('Latitude (deg)');
        title({[Proj,site,' - Zoomed In'],['Offset: ',num2str(dist_km,'%.2f'),' km']});
        box on
    % zoomed-out panel: regional context, with coastline if available
        subplot(1,2,2)
        hold on
    try
            load coastlines coastlat coastlon
            plot(coastlon,coastlat,'k-');
    catch
            disp('Coastline data (load coastlines) not available - skipping basemap.')
    end
        hDesired2 = plot(slon_std,slat,'rx','MarkerSize',12,'LineWidth',2);
        hUsed2 = plot(slon25_std,slat25,'bo','MarkerSize',10,'LineWidth',2);
        axis equal
        bufOut = 5; % deg
        xlim([slon25_std-bufOut, slon25_std+bufOut]);
        ylim([slat25-bufOut, slat25+bufOut]);
        xlabel('Longitude (deg)'); ylabel('Latitude (deg)');
        title([Proj,site,' - Regional View']);
        legend([hDesired2, hUsed2], {'Desired site','CCMP point used'}, 'Location','southoutside')
        grid on
        box on
        fsLoc = fullfile(outdir,[Proj,site,'_sitecheck']);
        saveas(figLoc,fsLoc,'pdf');
%         saveas(figLoc,fsLoc,'fig'); % editable version for later review
        saveas(figLoc,fsLoc,'png'); % quick-view raster version
%         save(fsLoc,'Proj','site','year','slat','slon_std','slat25','slon25_std','dist_km');
    % --- end site vs. CCMP grid-point check figure ---
        dnvec = zeros(4*365,1);  ivec = 0;
        uwvec = dnvec;  vwvec = dnvec;
    for month = 1:12
    if month < 10
                ml = num2str(month);
                m = ['0',ml];
    else
                m = num2str(month);
    end
        ndays = eomday(yr,month);
    for day = 1:ndays
    if day < 10
                    dl = num2str(day);
                    d = ['0',dl];
    else
                    d = num2str(day);
    end
                [f,mid,post,lat,lon] = CCMP_Variant(...
            pre,pre0,year,m,d,mid0,mid1,mid2,post0,post1,post2);
    if ~strcmp(f,'n')
    % Open the file once and pull only the single grid point (ilon,ilat)
    % across all 4 timesteps for both variables, instead of reading the
    % full global grid via ncread. Big win on a network drive.
    try
                        ncid = netcdf.open(f,'NOWRITE');
                        tihr = netcdf.getVar(ncid,netcdf.inqVarID(ncid,'time'));
                        uwnd_pt = netcdf.getVar(ncid,netcdf.inqVarID(ncid,'uwnd'),...
                            [ilon-1 ilat-1 0],[1 1 4]);
                        vwnd_pt = netcdf.getVar(ncid,netcdf.inqVarID(ncid,'vwnd'),...
                            [ilon-1 ilat-1 0],[1 1 4]);
                        netcdf.close(ncid);
    catch ME
                        disp(['Read failed for ',f,': ',ME.message]);
                        tihr = [];
    end
    if ~isempty(tihr)
    for i = 1:4
                        ivec = ivec + 1;
                        dnvec(ivec) = datenum([1987,0,1,tihr(i),0,0]);
    %test date
    if i == 1
                            dntest = datenum([yr,month,day,0,0,0]);
    if dntest ~= dnvec(ivec)
                                disp(['Date Prob ',num2str(dntest),' ',num2str(dnvec(ivec))]);
    end
    end
                        uwvec(ivec) = double(uwnd_pt(i));
                        vwvec(ivec) = double(vwnd_pt(i));
    end
    end
    else
                    disp(['Not Valid Date:  ',year,m,d]);
    end
    end
    end
    % plot wind speed
        figure
        subplot(2,1,1)
        wspeed = sqrt(uwvec.^2 + vwvec.^2);
    % take out bad data
        isok = find(wspeed > 0);
        wspeed = wspeed(isok);
        dnvec = dnvec(isok);
        uwvec = uwvec(isok);
        vwvec = vwvec(isok);
    %
        plot(dnvec,wspeed);
        datetick('x','mmm')
        title([Proj,site,' Wind Speed ',num2str(year),'  lat= ',num2str(slat25),...
    '  lon= ',num2str(slon25)]);
        ylabel('Wind Speed in m/s');
        xlabel(' Month ');
    %plot wind direction
        subplot(2,1,2)
        wdir = 180*atan2(vwvec,uwvec)/pi; % v is north u is east
        wmetdir = wdir;
        idir = find (wdir < 0); % meterological convention 0-360 deg
        wmetdir(idir) = 360 + wdir(idir);
        plot(dnvec,wmetdir);
        datetick('x','mmm')
        title([Proj,site,' Wind Direction ',num2str(year),'  lat= ',num2str(slat25),...
    '  lon= ',num2str(slon25)]);
        ylabel('Meterological Wind Direction re: North');
        xlabel(' Month ');
    %save results
        fs = fullfile(outdir,[Proj,site,'windvec']);
        save(fs,'Proj','site','year','slat25','slon25','dnvec','uwvec','vwvec',...
    'wspeed','wmetdir');
        saveas(gcf,fs,'pdf');
    %
    end % site loop
end % year loop