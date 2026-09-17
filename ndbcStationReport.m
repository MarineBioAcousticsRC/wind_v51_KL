function T = ndbcStationReport(station,folder,makePlot)
%NDBCSTATIONREPORT  Coverage, downtime and payload changes from NDBC files.
%
%   ndbcStationReport                       % defaults below
%   ndbcStationReport('46053',folder)
%   T = ndbcStationReport(...)              % results as a table
%   ndbcStationReport(station,folder,false) % no figure
%
%   NDBC does not publish a downtime log or a payload-change history for a
%   station, so this works it out from the downloaded files instead. For
%   every <station>h<year>.txt in the folder it reports:
%
%     Rows        data rows in the file
%     IntMin      median sampling interval, minutes
%     CovPct      percent of the year actually covered, given that interval
%     Gaps6h      number of gaps longer than 6 hours
%     MaxGapD     longest gap in days, and when it started
%     BadPct      percent of rows with a fill value for wind speed
%
%   A CHANGE IN IntMin IS THE PAYLOAD-UPGRADE SIGNATURE. Older NDBC
%   payloads reported hourly; newer ones (ARES, SCOOP) report every 10
%   minutes. The year that interval drops is the year the station was
%   upgraded - it will not be written down anywhere else.
%
%   This reads all three NDBC layouts correctly (17-column pre-2005,
%   18-column 2005-2006 without '#', 18-column 2007+ with '#'), which
%   WindTimeSeries_NDBC.m deliberately does not - see getNDBCstdmet.m.
%   So the coverage numbers here are trustworthy even for old years that
%   the main reader should not be pointed at.
%
%   KL 2026-09

%% ======================= SETTINGS - edit here =========================
stationDefault = '46053';
baseFolder     = 'Z:\Wind_deltaTF\Wind_Data\NDBC_Buoy\raw';
gapHours       = 6;      % a gap longer than this is counted
WSPD_FILL      = 99.0;
%% ======================================================================

if nargin < 1 || isempty(station),  station  = stationDefault; end
if nargin < 2 || isempty(folder),   folder   = fullfile(baseFolder,station); end
if nargin < 3 || isempty(makePlot), makePlot = true; end
station = char(station);

d = dir(fullfile(folder,[station,'h*.txt']));
if isempty(d)
    error('ndbcStationReport:noFiles', ...
        'No %sh*.txt files in:\n  %s\nRun getNDBCstdmet first.',station,folder);
end

yrs = zeros(numel(d),1);
for k = 1 : numel(d)
    t = regexp(d(k).name,'h(\d{4})\.txt$','tokens','once');
    if isempty(t), yrs(k) = NaN; else, yrs(k) = str2double(t{1}); end
end
keep = ~isnan(yrs);
d = d(keep);  yrs = yrs(keep);
[yrs,iSort] = sort(yrs);  d = d(iSort);
n = numel(yrs);

fprintf('\n=== NDBC %s: coverage and downtime from the data ===\n',station);
fprintf('Folder: %s\n',folder);
fprintf('%s\n',repmat('-',1,96));
fprintf('%-6s %8s %7s %8s %7s %9s %-12s %7s  %s\n', ...
    'YEAR','ROWS','INT_min','COV_%','GAPS>6h','MAXGAP_d','GAP STARTS','BAD_%','NOTE');

Rows=zeros(n,1); IntMin=nan(n,1); CovPct=nan(n,1); Gaps6h=zeros(n,1);
MaxGapD=nan(n,1); GapStart=cell(n,1); BadPct=nan(n,1); Note=cell(n,1); Cols=zeros(n,1);

for k = 1 : n
    f = fullfile(d(k).folder,d(k).name);
    [dn,wspd,nc] = readAnyNDBC(f);
    Cols(k) = nc;  Note{k} = '';  GapStart{k} = '';
    if isempty(dn)
        fprintf('%-6d %8s  (unreadable)\n',yrs(k),'-');
        continue
    end
    Rows(k) = numel(dn);
    dn = sort(dn);

    dt = diff(dn);
    dt = dt(dt > 0);
    if isempty(dt)
        IntMin(k) = NaN;
    else
        IntMin(k) = median(dt)*24*60;
    end

    % coverage against a full year at the observed interval
    nDaysYr = 365 + (eomday(yrs(k),2) == 29);
    if ~isnan(IntMin(k)) && IntMin(k) > 0
        expected = nDaysYr*24*60 / IntMin(k);
        CovPct(k) = 100*Rows(k)/expected;
    end

    % gaps
    gapThresh = gapHours/24;
    ig = find(dt > gapThresh);
    Gaps6h(k) = numel(ig);
    if ~isempty(ig)
        [mx,imx] = max(dt(ig));
        MaxGapD(k) = mx;
        % dn index of the sample the gap starts after
        idxAll = find(diff(dn) > gapThresh);
        GapStart{k} = datestr(dn(idxAll(imx)),'yyyy-mm-dd');
    else
        MaxGapD(k) = 0;
    end

    if ~isempty(wspd)
        BadPct(k) = 100*mean(wspd == WSPD_FILL | isnan(wspd));
    end

    if nc < 18
        Note{k} = '17-col pre-2005 layout';
    end

    fprintf('%-6d %8d %7.1f %8.1f %7d %9.2f %-12s %7.1f  %s\n', ...
        yrs(k),Rows(k),IntMin(k),CovPct(k),Gaps6h(k),MaxGapD(k), ...
        GapStart{k},BadPct(k),Note{k});
end
fprintf('%s\n',repmat('-',1,96));

T = table(yrs,Rows,IntMin,CovPct,Gaps6h,MaxGapD,GapStart,BadPct,Cols, ...
    'VariableNames',{'Year','Rows','IntMin','CovPct','Gaps6h','MaxGapD', ...
    'GapStart','BadPct','Cols'});

%% ---------- what changed, and when -------------------------------------
iv = round(IntMin);
chg = find(diff(iv) ~= 0 & ~isnan(iv(1:end-1)) & ~isnan(iv(2:end)));
if isempty(chg)
    fprintf('Sampling interval steady at %g min across all years.\n',iv(1));
else
    fprintf('SAMPLING INTERVAL CHANGES (payload upgrades are the usual cause):\n');
    for k = chg(:)'
        fprintf('   %d -> %d : %g min becomes %g min\n', ...
            yrs(k),yrs(k+1),iv(k),iv(k+1));
    end
end

worst = CovPct < 90;
if any(worst)
    fprintf('\nYears under 90%% coverage:\n');
    for k = find(worst)'
        fprintf('   %d : %.1f%% covered, longest gap %.1f days from %s\n', ...
            yrs(k),CovPct(k),MaxGapD(k),GapStart{k});
    end
else
    fprintf('\nEvery year is above 90%% coverage.\n');
end

fprintf(['\nNote: NDBC lists this station''s anemometer height on its ', ...
    'station page.\n      A 3-m buoy sits near 4-5 m, not the 10 m that ', ...
    'model winds\n      such as CCMP are referenced to - see the header ', ...
    'of this file.\n\n']);

%% ---------- figure ------------------------------------------------------
if makePlot
    fg = figure('Name',['NDBC ',station,' coverage and sampling'], ...
        'NumberTitle','off','Color','w');
    subplot(2,1,1)
    b = bar(yrs,CovPct,'FaceColor',[0.30 0.45 0.65],'EdgeColor','none');
    hold on
    yline(90,'r--','90%','LineWidth',1.2);
    ylabel('Coverage [%]'); ylim([0 105]); grid on; box on
    title(['NDBC ',station,' - percent of each year actually recorded']);
    set(b,'HandleVisibility','off');

    subplot(2,1,2)
    stairs(yrs,IntMin,'-o','LineWidth',1.8,'Color',[0.75 0.35 0.10], ...
        'MarkerFaceColor','w');
    ylabel('Sampling interval [min]'); xlabel('Year'); grid on; box on
    title('Interval drops mark a payload upgrade');
end

if nargout == 0
    clear T
end
end

% =======================================================================
function [dn,wspd,nCols] = readAnyNDBC(f)
%READANYNDBC  Read any era of NDBC standard met. Returns time and wind speed.
% 17 cols (<=2004): YY MM DD hh        WD(5)  WSPD(6)
% 18 cols (2005+) : YY MM DD hh mm   WDIR(6)  WSPD(7)
dn = []; wspd = []; nCols = 0;
[nHdr,nCols] = peekNDBC(f);
if nCols == 0
    return
end
fid = fopen(f,'r');
if fid < 0
    nCols = 0;
    return
end
C = textscan(fid,repmat('%f',1,nCols),'HeaderLines',nHdr, ...
    'CollectOutput',true,'TreatAsEmpty',{'MM'});
fclose(fid);
if isempty(C) || isempty(C{1})
    return
end
M = C{1};
M = M(all(~isnan(M(:,1:4)),2),:);      % keep rows with a usable date
if isempty(M)
    return
end
if nCols >= 18
    mn = M(:,5);  iw = 7;
else
    mn = zeros(size(M,1),1);  iw = 6;
end
yy = M(:,1);
yy(yy < 100) = yy(yy < 100) + 1900;    % very old files used 2-digit years
dn   = datenum([yy, M(:,2), M(:,3), M(:,4), mn, zeros(size(mn))]);
wspd = M(:,iw);
end

% =======================================================================
function [nHdr,nCols] = peekNDBC(f)
%PEEKNDBC  How many header lines, and how many columns in a data row.
nHdr = 0; nCols = 0;
fid = fopen(f,'r');
if fid < 0
    return
end
c = onCleanup(@() fclose(fid)); %#ok<NASGU>
while true
    ln = fgetl(fid);
    if ~ischar(ln), return; end
    s = strtrim(ln);
    if isempty(s)
        nHdr = nHdr + 1;
        continue
    end
    if s(1) == '#' || ~isempty(regexp(s,'^[A-Za-z]','once'))
        nHdr = nHdr + 1;                % header, either era
        continue
    end
    nCols = numel(strsplit(s));         % first data row
    return
end
end
