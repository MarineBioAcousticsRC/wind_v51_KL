function T = getNDBCstdmet(station,years,outFolder,overwrite)
%GETNDBCSTDMET  Download NDBC historical standard meteorological data.
%
%   getNDBCstdmet                       station and years from the settings below
%   getNDBCstdmet(station,years)        e.g. getNDBCstdmet('46053',2006:2025)
%   getNDBCstdmet(station,years,folder)
%   getNDBCstdmet(station,years,folder,overwrite)   overwrite = true re-fetches
%   T = getNDBCstdmet(...)              returns the summary as a table
%
%   Saves one plain-text file per year, named <station>h<year>.txt, into
%   <outFolder>. That is exactly the name and location WindTimeSeries_NDBC.m
%   expects for its inpath, so pointing that script at the same folder is all
%   that is needed afterwards.
%
%   Already-downloaded years are skipped unless overwrite is true, so the
%   function is safe to re-run to fill gaps or to top up a later year.
%
%   Source (verified 2026-09-17):
%     https://www.ndbc.noaa.gov/view_text_file.php?filename=<st>h<yr>.txt.gz
%                                                 &dir=data/historical/stdmet/
%   That endpoint serves the decompressed text, so no gunzip is needed. The
%   .gz via download_data.php is used as a fallback if it ever stops working.
%
%   FILE FORMAT WARNING
%   NDBC changed the standard met layout twice, and WindTimeSeries_NDBC.m is
%   written for the modern one only (2 header lines, 18 columns, WSPD in
%   column 7):
%
%     years    header lines   '#'   columns   mm col   WSPD in
%     <=2004        1          no      17       no      col 6
%     2005-2006     1          no      18       yes     col 7
%     2007+         2         yes      18       yes     col 7
%
%   So a 2004-or-earlier file read by WindTimeSeries_NDBC would take WSPD as
%   direction and GST as wind speed - no error, just a wind series biased
%   high by the gust factor. This function reports the detected column count
%   for every file and refuses to leave a <=2004 file in place silently: it
%   downloads it, flags it loudly, and marks it UNSAFE in the summary.
%
%   KL 2026-09

%% ======================= SETTINGS - edit here =========================
stationDefault = '46053';           % East Santa Barbara
yearsDefault   = 2025;         % 46053 has data 1994-2025
% One folder per station, matching the inpath convention in
% WindTimeSeries_NDBC.m. <station> is filled in below.
baseFolder     = 'Z:\Wind_deltaTF\Wind_Data\NDBC_Buoy\raw';
timeoutSec     = 60;
nRetries       = 3;
%% ======================================================================

if nargin < 1 || isempty(station),   station   = stationDefault; end
if nargin < 2 || isempty(years),     years     = yearsDefault;   end
if nargin < 3 || isempty(outFolder), outFolder = fullfile(baseFolder,station); end
if nargin < 4 || isempty(overwrite), overwrite = false;          end
station = char(station);

if ~isfolder(outFolder)
    [ok,msg] = mkdir(outFolder);
    if ~ok
        error('getNDBCstdmet:mkdir','Could not create:\n  %s\n  %s',outFolder,msg);
    end
    fprintf('Created %s\n',outFolder);
end

fprintf('\n=== NDBC standard met download ===\n');
fprintf('Station : %s\n',station);
fprintf('Years   : %d to %d (%d)\n',min(years),max(years),numel(years));
fprintf('Folder  : %s\n',outFolder);
fprintf('User    : %s   %s\n',getenvOr('USERNAME','UNKNOWN'), ...
    datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('%s\n',repmat('-',1,78));
fprintf('%-6s %-10s %10s %8s %8s  %s\n', ...
    'YEAR','STATUS','BYTES','ROWS','COLS','NOTE');

wopts = weboptions('Timeout',timeoutSec);

n = numel(years);
yr_ = zeros(n,1); status_ = cell(n,1); bytes_ = zeros(n,1);
rows_ = zeros(n,1); cols_ = zeros(n,1); note_ = cell(n,1);

for k = 1 : n
    yr   = years(k);
    yrS  = num2str(yr);
    fn   = [station,'h',yrS,'.txt'];
    dest = fullfile(outFolder,fn);

    yr_(k) = yr;  note_{k} = '';

    if exist(dest,'file') == 2 && ~overwrite
        d = dir(dest);
        [nr,nc] = peekFormat(dest);
        status_{k} = 'have';  bytes_(k) = d.bytes;
        rows_(k) = nr;  cols_(k) = nc;
        note_{k} = formatNote(yr,nc);
        report(yr,status_{k},bytes_(k),nr,nc,note_{k});
        continue
    end

    [okDl,tmpFile,errMsg] = fetchYear(station,yrS,wopts,nRetries);
    if ~okDl
        status_{k} = 'MISSING';  note_{k} = errMsg;
        report(yr,status_{k},0,0,0,errMsg);
        continue
    end

    % sanity-check before it is allowed to land in the folder
    [nr,nc,why] = validateFile(tmpFile);
    if nr == 0
        delete(tmpFile);
        status_{k} = 'BAD';  note_{k} = why;
        report(yr,status_{k},0,0,0,why);
        continue
    end

    movefile(tmpFile,dest,'f');
    d = dir(dest);
    status_{k} = 'ok';  bytes_(k) = d.bytes;
    rows_(k) = nr;  cols_(k) = nc;
    note_{k} = formatNote(yr,nc);
    report(yr,status_{k},bytes_(k),nr,nc,note_{k});
end

fprintf('%s\n',repmat('-',1,78));
T = table(yr_,status_,bytes_,rows_,cols_,note_, ...
    'VariableNames',{'Year','Status','Bytes','Rows','Cols','Note'});

nOK   = sum(strcmp(status_,'ok'));
nHave = sum(strcmp(status_,'have'));
nBad  = sum(ismember(status_,{'MISSING','BAD'}));
fprintf('%d downloaded, %d already present, %d unavailable\n',nOK,nHave,nBad);

iUnsafe = find(cols_ > 0 & cols_ < 18);
if ~isempty(iUnsafe)
    fprintf(2,['\n*** %d file(s) are in the pre-2005 17-column layout ***\n', ...
        '*** WindTimeSeries_NDBC.m WILL MISREAD THESE: it would take   ***\n', ...
        '*** WSPD as direction and GST as wind speed, with no error.   ***\n'], ...
        numel(iUnsafe));
    fprintf(2,'    Affected years: %s\n',num2str(yr_(iUnsafe)'));
    fprintf(2,'    Either drop these years or have the reader taught the old layout.\n');
end

iMiss = find(ismember(status_,{'MISSING','BAD'}));
if ~isempty(iMiss)
    fprintf('\nNo data for: %s\n',num2str(yr_(iMiss)'));
    fprintf('(gaps in a station''s record are normal - check station_history on NDBC)\n');
end

fprintf('\nNext: in WindTimeSeries_NDBC.m set\n');
fprintf('    stationID = ''%s'';\n',station);
fprintf('    inpath    = ''%s'';\n',outFolder);
fprintf('    yearRange = %d:%d;   %% adjust to the years marked ok/have above\n\n', ...
    min(years),max(years));

if nargout == 0
    clear T
end
end

% =======================================================================
function [ok,tmpFile,errMsg] = fetchYear(station,yrS,wopts,nRetries)
%FETCHYEAR  Pull one year, primary endpoint then gz fallback.
ok = false;  errMsg = '';
tmpFile = [tempname,'.txt'];
gzName  = [station,'h',yrS,'.txt.gz'];

for attempt = 1 : nRetries
    try
        % view_text_file.php serves the DECOMPRESSED text - no gunzip needed
        websave(tmpFile,'https://www.ndbc.noaa.gov/view_text_file.php', ...
            'filename',gzName,'dir','data/historical/stdmet/',wopts);
        ok = true;
        return
    catch ME
        errMsg = ME.message;
        if contains(errMsg,'404') || contains(lower(errMsg),'not found')
            errMsg = 'not in the archive for this year';
            return   % a genuine gap - no point retrying
        end
        pause(1.5*attempt);   % transient: back off and try again
    end
end

% fallback: the gzip the site links from station_history
try
    gzTmp = [tempname,'.txt.gz'];
    websave(gzTmp,'https://www.ndbc.noaa.gov/download_data.php', ...
        'filename',gzName,'dir','data/historical/stdmet/', ...
        weboptions('Timeout',60));
    unz = gunzip(gzTmp,tempdir);
    movefile(unz{1},tmpFile,'f');
    delete(gzTmp);
    ok = true;
catch ME2
    errMsg = ['both endpoints failed: ',ME2.message];
end
end

% =======================================================================
function [nRows,nCols,why] = validateFile(f)
%VALIDATEFILE  Is this really an NDBC standard met file?
nRows = 0; nCols = 0; why = '';
fid = fopen(f,'r');
if fid < 0
    why = 'could not reopen the download';
    return
end
c = onCleanup(@() fclose(fid)); %#ok<NASGU>
first = fgetl(fid);
if ~ischar(first)
    why = 'empty file';
    return
end
if contains(lower(first),'<html') || contains(lower(first),'<!doctype')
    why = 'server returned an HTML page, not data';
    return
end
% header lines are either '#...' or start with YYYY/YY
if isempty(regexp(first,'^\s*(#|YYYY|#YY)','once'))
    why = ['unexpected first line: ',strtrim(first(1:min(40,end)))];
    return
end
[nRows,nCols] = peekFormatFid(fid);
if nRows == 0
    why = 'header but no data rows';
end
end

% =======================================================================
function [nRows,nCols] = peekFormat(f)
nRows = 0; nCols = 0;
fid = fopen(f,'r');
if fid < 0, return; end
c = onCleanup(@() fclose(fid)); %#ok<NASGU>
[nRows,nCols] = peekFormatFid(fid);
end

function [nRows,nCols] = peekFormatFid(fid)
%PEEKFORMATFID  Count data rows and the column count of the first data row.
nRows = 0; nCols = 0;
while true
    ln = fgetl(fid);
    if ~ischar(ln), break; end
    s = strtrim(ln);
    if isempty(s), continue; end
    if s(1) == '#', continue; end                      % 2007+ header
    if ~isempty(regexp(s,'^[A-Za-z]','once')), continue; end  % pre-2007 header
    nRows = nRows + 1;
    if nCols == 0
        nCols = numel(strsplit(s));
    end
end
end

% =======================================================================
function s = formatNote(yr,nc)
%FORMATNOTE  Plain-language note about this year's layout.
if nc == 0
    s = '';
elseif nc < 18
    s = 'UNSAFE 17-col pre-2005 layout';
elseif yr <= 2006
    s = 'no # header - first data row is skipped by the reader';
else
    s = '';
end
end

% =======================================================================
function report(yr,status,bytes,nr,nc,note)
fprintf('%-6d %-10s %10s %8d %8d  %s\n',yr,status,byteStr(bytes),nr,nc,note);
end

function s = byteStr(b)
if b <= 0
    s = '-';
elseif b < 1024^2
    s = sprintf('%.0f KB',b/1024);
else
    s = sprintf('%.1f MB',b/1024^2);
end
end

function v = getenvOr(name,dflt)
v = getenv(name);
if isempty(v)
    v = dflt;
end
end
