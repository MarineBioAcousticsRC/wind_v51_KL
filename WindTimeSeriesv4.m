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
yearRange = 2023:2024;      % <-- deployment year(s). e.g. 2016:2018, or [2017 2019] - for single year, can do 2017:2017
Proj      = 'GofMX';          % <-- region
sites = {'Y4A','Y4B','Y4D'};
% sites     = {'HP','PR','SW','SZ'};         % <-- one or more site names, e.g. {'HP','PR','SW'}

outpath = 'C:\Users\Kieran Lenssen\Documents\GitHub\wind_v51_KL\WindTimeSeries_Results'; % where to save processed data

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
    % --- resolve the CCMP file variant and the lat/lon axes ONCE ---
    % Was: CCMP_Variant called again for every single day of the year, which
    % cost 3 exist() stats plus 2 ncread opens per day on Z: - and the lat/lon
    % it returned were thrown away, since ilat/ilon are fixed below. Now the
    % variant and the axes are resolved once and the daily filename is built
    % directly, with a per-day fallback if a year ever mixes variants.
        [ccmpVariant,f,lat,lon] = ccmpResolveYear(...
            pre,pre0,year,yr,mid0,mid1,mid2,post0,post1,post2);
    if ccmpVariant < 0
            warning('No CCMP file found anywhere in %s - skipping %s%s %s.', ...
                fullfile(pre,year),Proj,site,year);
    continue
    end
        fprintf(' CCMP file variant %d, e.g. %s\n',ccmpVariant,f);
    % find point near deployment site
        slat25 = (round((slat+.125) * 4))/4 - .125;
        slon25 = (round((slon+.125) * 4))/4 - .125;
    % Difference with wind site?
        disp([' Del-Lat = ',num2str(slat - slat25),' deg']);
        disp([' Del-Lon = ',num2str(slon - slon25),' deg']);
        ilat = find(lat == slat25);
        ilon = find(lon == slon25);
    if isempty(ilat) || isempty(ilon)
            warning(['Site %s%s does not land on a CCMP grid point ', ...
                '(slat25 = %g, slon25 = %g) - skipping %s.'], ...
                Proj,site,slat25,slon25,year);
    continue
    end
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
        nDaysYr = 365 + (eomday(yr,2) == 29);   % 366 in a leap year
        dnvec = zeros(4*nDaysYr,1);  ivec = 0;
        uwvec = dnvec;  vwvec = dnvec;
    % progress readout, one line per month. Months are uneven and February
    % moves with leap years, so days/month is not a fixed number - the line
    % prints the actual count for that month, and the estimate below is
    % based on months completed rather than days, which keeps it honest.
        tYear = tic;
        monthNames = {'Jan','Feb','Mar','Apr','May','Jun', ...
                      'Jul','Aug','Sep','Oct','Nov','Dec'};
        nMissYear = 0;
        fprintf('  %-4s %-8s %8s %10s %9s\n', ...
    'mon','days','samples','elapsed','remaining');
    for month = 1:12
            tMonth = tic;
            nGotMon = 0;  nMissMon = 0;
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
    % build the day's filename from the variant resolved above - one
    % exist() instead of three, and no lat/lon re-read
                f = ccmpFileName(ccmpVariant,pre,pre0,year,m,d, ...
                    mid0,mid1,mid2,post0,post1,post2);
                haveFile = (exist(f,'file') == 2);   % one stat, not three
    if ~haveFile
    % rare: a year that mixes variants. Fall back to the full search.
                    f = CCMP_Variant(pre,pre0,year,m,d, ...
                        mid0,mid1,mid2,post0,post1,post2);
                    haveFile = ~strcmp(f,'n');
    end
    if haveFile
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
                        nGotMon = nGotMon + 1;
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
                    nMissMon = nMissMon + 1;
                    disp(['Not Valid Date:  ',year,m,d]);
    end
    end
    % ---- end of month: progress line ----
            nMissYear = nMissYear + nMissMon;
            tEl  = toc(tYear);
            tRem = tEl/month * (12 - month);
    if nMissMon > 0
                missTxt = sprintf('%d/%d*',nGotMon,ndays);
    else
                missTxt = sprintf('%d/%d',nGotMon,ndays);
    end
            fprintf('  %-4s %-8s %8d %8.1f s %7.1f s\n', ...
                monthNames{month},missTxt,ivec,tEl,tRem);
    end
    if nMissYear > 0
            fprintf(['  * %d day(s) had no CCMP file this year - see the ', ...
    '"Not Valid Date" lines above\n'],nMissYear);
    end
        fprintf('  %s%s %s done: %d samples in %.1f s\n', ...
            Proj,site,year,ivec,toc(tYear));
    % plot wind speed
        figTS = figure;
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
        saveas(figTS,fs,'pdf');

    % ---------------- Polar wind direction figure ----------------
    % Ported from WindTimeSeries_NDBC.m so CCMP years get the same view.
    % Angle = met direction (from N, clockwise compass sense).
    % Radius = day-of-year, so January is near the centre and December is
    % out at the rim. Colour = wind speed.
    % No thinning here: CCMP is 6-hourly, ~1460 points a year, so every
    % point is plotted. The buoy version uses skip = 6 because 10-minute
    % data would otherwise fill the disc solid.
        figPolar = figure('Name',[Proj,site,' CCMP Polar Wind ',year]);
        doy   = dnvec - datenum(yr,1,1);    % days since Jan 1
        rPlot = sqrt(doy);                  % area-proportional radius
        theta = deg2rad(wmetdir);
        polarscatter(theta,rPlot,12,wspeed,'filled');
        axP = gca;
        axP.ThetaZeroLocation = 'top';
        axP.ThetaDir          = 'clockwise';
        colormap(axP,'turbo');   % or parula, jet, cool, hot, etc.
        cb = colorbar; cb.Label.String = 'Wind speed (m/s)';
    % ticks at sqrt of each month-start day so the labels land correctly
        monthStarts = datenum(yr,1:12,1) - datenum(yr,1,1);
        axP.RTick      = sqrt(monthStarts(1:3:end));   % Jan, Apr, Jul, Oct
        axP.RTickLabel = {'Jan','Apr','Jul','Oct'};
        title({[Proj,site,' CCMP Wind Direction ',year], ...
    'angle = met dir (from N), radius = month, colour = speed'});
        fsPolar = fullfile(outdir,[Proj,site,'_CCMP_polarwind_',year]);
        saveas(figPolar,fsPolar,'png');
        fprintf('  Saved polar plot: %s.png\n',fsPolar);
    %
    end % site loop
end % year loop

%% ===================== local functions ================================
function f = ccmpFileName(variant,pre,pre0,year,m,d, ...
    mid0,mid1,mid2,post0,post1,post2)
%CCMPFILENAME  Build a CCMP filename for one day, for a known variant.
% Mirrors the three name patterns CCMP_Variant.m tests, so the daily loop
% can skip its three exist() calls and two lat/lon reads.
switch variant
    case 0
        f = fullfile(pre,year,[pre0,m,mid0,year,m,d,post0]);
    case 1
        f = fullfile(pre,year,[mid1,year,m,d,post1]);
    case 2
        f = fullfile(pre,year,[mid2,year,m,d,post2]);
    otherwise
        f = '';
end
end

function [variant,f,lat,lon] = ccmpResolveYear(pre,pre0,year,yr, ...
    mid0,mid1,mid2,post0,post1,post2)
%CCMPRESOLVEYEAR  Which CCMP naming variant does this year use, and its axes.
% Probes days until a file turns up - Jan 1 is not guaranteed to exist -
% then reads the latitude/longitude vectors once for the whole year.
% Variant numbering and the search order match CCMP_Variant.m: 1, then 2,
% then 0. Returns variant = -1 if nothing is found all year.
variant = -1; f = ''; lat = []; lon = [];
for month = 1:12
    m = sprintf('%02d',month);
    for day = 1:eomday(yr,month)
        d = sprintf('%02d',day);
        for v = [1 2 0]
            cand = ccmpFileName(v,pre,pre0,year,m,d, ...
                mid0,mid1,mid2,post0,post1,post2);
            if exist(cand,'file') == 2
                variant = v;
                f = cand;
                if v == 0
                    lat = ncread(f,'lat');
                    lon = ncread(f,'lon');
                else
                    lat = ncread(f,'latitude');
                    lon = ncread(f,'longitude');
                end
                return
            end
        end
    end
end
end
