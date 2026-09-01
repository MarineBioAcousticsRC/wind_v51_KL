function [dnew,wsnew,windInfo] = loadWindData(ptime)
%LOADWINDDATA  Load the wind time series that pairs with an LTSA average.
%
%   [dnew,wsnew,windInfo] = loadWindData(ptime)
%
%   Replaces the block of wind-loading code that used to be copy-pasted into
%   calLTSA51.m, calLTSAm51.m and calLTSAl51.m.  Behaviour for CCMP data is
%   unchanged; the differences are:
%
%     1. p.windfile is honoured FIRST.  If you set an explicit wind file in
%        getWindParams.m it is used instead of the automatic folder search.
%        Previously p.windfile was the LAST thing checked, so a stale CCMP
%        file sitting in the Wind_Data tree would silently win.
%     2. The same file is never loaded twice (an "all years in one file"
%        wind product used to be re-loaded once per year and, for the
%        SOCALB special case, each load overwrote the previous one).
%     3. Sample cadence is measured from the data rather than assumed to be
%        6-hourly, so 10-minute buoy (NDBC) data is no longer stretched by a
%        6x interpolation that was only ever correct for CCMP.
%     4. It prints what it loaded, from where, and over what date range, and
%        it returns that in windInfo so callers can save it as provenance.
%
%   INPUT
%     ptime    - vector of LTSA average bin times (MATLAB datenum)
%
%   OUTPUT
%     dnew     - wind sample times (datenum), row vector
%     wsnew    - wind speed (m/s), row vector, same length as dnew
%     windInfo - struct describing what was loaded:
%                  .files      cellstr of full paths actually loaded
%                  .source     cellstr, how each file was found
%                              ('p.windfile override' | 'auto search' | 'user picked')
%                  .label      p.windSource label, e.g. 'CCMP' or 'NDBC 46053'
%                  .years      deployment years searched
%                  .nRaw       number of samples before interpolation
%                  .dtMedian   median sample interval in hours
%                  .interpFac  interpolation factor applied (1 = none)
%                  .dnRange    [first last] wind datenum
%                  .ltsaRange  [first last] ptime datenum
%
%   KL 2026-08 - factored out of calLTSA*51.m

global p

Proj       = p.harp.Proj;
Site       = p.harp.Site;
Short      = p.harp.Short;
WindFolder = p.harp.WindFolder;

if ~isfield(p,'windSource') || isempty(p.windSource)
    p.windSource = 'unlabelled';
end

% ---- deployment years spanned by the LTSA averages ---------------------
% Taken from the bins themselves, not yr1:yr2, so a deployment with a gap
% does not demand a wind file for a year it has no data in. binCount is
% kept so a year holding only a handful of bins - a deployment that ends
% just after midnight on 1 Jan, say - does not turn a missing wind file
% into a hard stop.
yrsOfBins = year(datetime(ptime(:),'ConvertFrom','datenum'));
wyrs      = unique(yrsOfBins)';
binCount  = arrayfun(@(y) sum(yrsOfBins == y), wyrs);
trivialYr = max(24, 0.01*numel(ptime));   % fewer bins than this = trivial

fprintf('\n--- Wind data ---------------------------------------------\n');
fprintf('LTSA averages span %s to %s (%d bins)\n', ...
    datestr(ptime(1),'yyyy-mm-dd HH:MM'), ...
    datestr(ptime(end),'yyyy-mm-dd HH:MM'), numel(ptime));
fprintf('Wind source label : %s\n', p.windSource);
fprintf('Looking for years : %s\n', num2str(wyrs));

% ---- locate and load one wind file per year ----------------------------
vec = []; speed = [];
filesUsed = {}; howFound = {}; kinds = {};

for iyr = 1 : length(wyrs)
    thisYr   = wyrs(iyr);
    yrStr    = num2str(thisYr);
    yrStart  = datenum(thisYr,1,1);
    yrEnd    = datenum(thisYr+1,1,1);
    wfile    = '';
    how      = '';
    rejected = {};   % candidates that exist but hold no data for this year

    % (1) explicit files from getWindParams - checked FIRST.
    % Every non-empty p.windfile entry is tested against THIS year, rather
    % than trusting entry iyr to line up with wyrs(iyr). That alignment is
    % easy to get wrong when a deployment starts mid-year or spans a year
    % boundary, and getting it wrong silently loads the wrong year.
    if isfield(p,'windfile')
        for k = 1 : numel(p.windfile)
            f = p.windfile{k};
            if isempty(f)
                continue
            end
            if exist(f,'file') ~= 2
                fprintf(2,'p.windfile{%d} does not exist:\n  %s\n',k,f);
                continue
            end
            [okYr,cov] = coversYear(f,yrStart,yrEnd);
            if okYr
                wfile = f;
                how   = sprintf('p.windfile{%d}',k);
                break
            else
                rejected{end+1,1} = sprintf('%s\n        holds %s, no %s data', ...
                    f,cov,yrStr);  %#ok<AGROW>
            end
        end
    end

    % (2) automatic search - CANONICAL CCMP LOCATIONS ONLY.
    % Year folders first, then the flat all-years product. A candidate is
    % accepted only if it holds data for THIS year AND is not sitting in a
    % quarantine subfolder. Nothing else is ever substituted: if none of
    % these match, the code stops and asks rather than guessing. That is
    % deliberate - grabbing a plausible-looking wrong file is far worse
    % than making you click.
    if isempty(wfile)
        cand = { fullfile(WindFolder,yrStr,[Proj,Site,'windvec.mat'])
                 fullfile(WindFolder,yrStr,[Site,'windvec.mat'])
                 fullfile(WindFolder,yrStr,[Proj,Short,'windvec.mat'])
                 fullfile(WindFolder,yrStr,[Site,Short,'windvec.mat'])
                 fullfile(WindFolder,[Proj,Site,'windvec.mat']) };
        for ic = 1 : length(cand)
            if exist(cand{ic},'file') ~= 2
                continue
            end
            [isQ,qword] = isQuarantined(cand{ic},WindFolder);
            if isQ
                rejected{end+1,1} = sprintf('%s\n        in a "%s" folder - not auto-used', ...
                    cand{ic},qword);  %#ok<AGROW>
                continue
            end
            [okYr,cov] = coversYear(cand{ic},yrStart,yrEnd);
            if okYr
                wfile = cand{ic};
                how   = 'auto (CCMP)';
                break
            else
                rejected{end+1,1} = sprintf('%s\n        holds %s, no %s data', ...
                    cand{ic},cov,yrStr);  %#ok<AGROW>
            end
        end
    end

    % (3) ask the user
    if isempty(wfile)
        fprintf(2,'No usable CCMP wind found for %s %s %s, year %s\n', ...
            Proj,Site,Short,yrStr);
        if ~isempty(rejected)
            fprintf('  Found but NOT used:\n');
            for ir = 1 : numel(rejected)
                fprintf('    %s\n',rejected{ir});
            end
        end
        fprintf(['  Searched: %s\n', ...
                 '            <year>\\ and the flat all-years file only.\n', ...
                 '  Pick the file by hand below, or set p.windfile in\n', ...
                 '  getWindParams.m to pin it. windFileReport(p.harp.WindFolder)\n', ...
                 '  lists every wind file you have and the years it covers.\n'], ...
            WindFolder);

        % A year holding only a sliver of the deployment is not worth
        % stopping for - this is the deployment that ends at 00:30 on
        % 1 Jan and so nominally "spans" a year it barely touches.
        if binCount(iyr) < trivialYr && ~isempty(filesUsed)
            fprintf(2,['  Only %d of %d LTSA bins (%.2f%%) fall in %s.\n', ...
                '  Continuing without a wind file for that year.\n'], ...
                binCount(iyr),numel(ptime), ...
                100*binCount(iyr)/numel(ptime),yrStr);
            continue
        end

        suggestedWind = fullfile(WindFolder,yrStr);
        if ~isfolder(suggestedWind)
            suggestedWind = WindFolder;
        end
        if ~isfolder(suggestedWind)
            suggestedWind = pwd;
        end
        dlgTitle = sprintf('Pick WIND file:  %s %s  depl %s  -  YEAR %s', ...
            Proj,Site,Short,yrStr);
        [w_file, w_pathname] = uigetfile(fullfile(suggestedWind,'*.mat'), ...
            dlgTitle);
        if isequal(w_file,0)
            error('loadWindData:noWindFile', ...
                'No wind file selected for %s %s year %s - cannot continue.', ...
                Proj,Site,yrStr);
        end
        wfile = fullfile(w_pathname,w_file);
        how   = 'user picked';
        p.windfile{iyr,1} = wfile;   % remember for the rest of the run
    end

    % skip a file already loaded (all-years products, repeated per year)
    if any(strcmpi(filesUsed,wfile))
        fprintf('  %s : already loaded, skipping duplicate\n',yrStr);
        continue
    end

    W = load(wfile);   % whole file, so provenance fields come with it
    if ~isfield(W,'dnvec') || ~isfield(W,'wspeed')
        error('loadWindData:badWindFile', ...
            'Wind file is missing dnvec and/or wspeed:\n  %s',wfile);
    end
    dnvec  = W.dnvec(:);
    wspeed = W.wspeed(:);
    if numel(dnvec) ~= numel(wspeed)
        error('loadWindData:lengthMismatch', ...
            'dnvec (%d) and wspeed (%d) differ in length in:\n  %s', ...
            numel(dnvec),numel(wspeed),wfile);
    end

    % What kind of wind product is this? Do not rely on p.windSource being
    % typed correctly - read it out of the file. WindTimeSeries_NDBC.m saves
    % stationID/buoyLat/buoyLon; the CCMP writers do not.
    if isfield(W,'stationID')
        kind = sprintf('NDBC buoy %s',num2str(W.stationID));
        if isfield(W,'buoyLat') && isfield(W,'buoyLon')
            kind = sprintf('%s at %.3fN %.3fW',kind,W.buoyLat,W.buoyLon);
        end
    elseif isfield(W,'slat25') && isfield(W,'slon25')
        kind = sprintf('gridded model at %.3fN %.3fW',W.slat25,W.slon25);
    else
        kind = 'unknown product';
    end
    kinds{end+1,1} = kind;   %#ok<AGROW>

    nInYr = sum(dnvec >= yrStart & dnvec < yrEnd);
    fprintf('  %s : %s\n',yrStr,wfile);
    fprintf('        (%s)  %d samples, %s to %s, %d in %s\n', ...
        how, numel(dnvec), datestr(dnvec(1),'yyyy-mm-dd'), ...
        datestr(dnvec(end),'yyyy-mm-dd'), nInYr, yrStr);
    fprintf('        contents: %s\n',kind);

    filesUsed{end+1,1} = wfile;   %#ok<AGROW>
    howFound{end+1,1}  = how;     %#ok<AGROW>
    vec   = [vec;   dnvec];       %#ok<AGROW>
    speed = [speed; wspeed];      %#ok<AGROW>
end

if isempty(vec)
    error('loadWindData:empty','No wind samples were loaded.');
end

% ---- tidy: sort in time, drop exact duplicate timestamps ---------------
[vec,isort] = sort(vec);
speed = speed(isort);
[vec,iuniq] = unique(vec);
speed = speed(iuniq);

% ---- cadence: measure it, do not assume 6-hourly -----------------------
dtDays = median(diff(vec));
dtHrs  = dtDays * 24;
interpFac = max(1, round(dtHrs));   % how many hourly steps per wind sample

fprintf('Loaded %d unique wind samples, median interval %.2f h\n', ...
    numel(vec), dtHrs);

if interpFac > 1
    % legacy behaviour: linearly fill interpFac-1 sub-samples between points
    % (for 6-hourly CCMP this reproduces the original 6x interpolation exactly)
    fprintf('Interpolating %d x to approx hourly\n',interpFac);
    n = length(vec);
    dnew  = zeros(1,(n-1)*interpFac + 1);
    wsnew = zeros(1,(n-1)*interpFac + 1);
    for i = 1 : n
        dnew((i-1)*interpFac + 1)  = vec(i);
        wsnew((i-1)*interpFac + 1) = speed(i);
        if i < n
            for k = 1 : interpFac-1
                f = k/interpFac;
                dnew((i-1)*interpFac + 1 + k)  = f*vec(i+1)   + (1-f)*vec(i);
                wsnew((i-1)*interpFac + 1 + k) = f*speed(i+1) + (1-f)*speed(i);
            end
        end
    end
else
    fprintf('Sampling is already hourly or finer - no interpolation\n');
    dnew  = vec(:)';
    wsnew = speed(:)';
end

% ---- overlap with the LTSA period, reported up front -------------------
ovlp = sum(dnew >= ptime(1) & dnew <= ptime(end));
fprintf('Wind covers %s to %s\n', ...
    datestr(dnew(1),'yyyy-mm-dd HH:MM'), datestr(dnew(end),'yyyy-mm-dd HH:MM'));
fprintf('Wind samples inside the LTSA period: %d\n',ovlp);
if ovlp == 0
    fprintf(2,'*** WARNING: the wind file does not overlap the LTSA period ***\n');
    fprintf(2,'*** Check p.windfile / p.harp.WindFolder in getWindParams.m ***\n');
    fprintf(2,'*** Run  windFileReport(p.harp.WindFolder)  to see what exists ***\n');
end
fprintf('-----------------------------------------------------------\n\n');

% ---- provenance --------------------------------------------------------
windInfo.files     = filesUsed;
windInfo.source    = howFound;
windInfo.kind      = kinds;   % what the file actually contains, read from it
windInfo.label     = p.windSource;
windInfo.years     = wyrs;
windInfo.nRaw      = numel(vec);
windInfo.dtMedian  = dtHrs;
windInfo.interpFac = interpFac;
windInfo.dnRange   = [dnew(1) dnew(end)];
windInfo.ltsaRange = [ptime(1) ptime(end)];
windInfo.nOverlap  = ovlp;
windInfo.loadedBy  = getenv('USERNAME');
windInfo.loadedOn  = datestr(now,'yyyy-mm-dd HH:MM:SS');

end

% =======================================================================
function [tf,word] = isQuarantined(f,root)
%ISQUARANTINED  True if a folder BELOW root looks like a "do not use" bin.
% Wind products that turned out to be wrong get moved into a subfolder
% rather than deleted, e.g.
%     Wind_Data\SOCAL\2022\potentially_incorrect\SOCALBwindvec.mat
% Those must never be picked up automatically.
%
% Only the part of the path below root is inspected, so a quarantine word
% appearing somewhere in the drive or project path above the wind tree
% cannot reject everything. Folder names are matched whole, not as
% substrings, so a site legitimately called e.g. "Goldstone" is safe.
words = {'potentially_incorrect','potentiallyincorrect','incorrect', ...
         'do_not_use','donotuse','dont_use','bad','suspect','suspect_data', ...
         'quarantine','deprecated','old','archive','junk','ignore'};
tf = false; word = '';

% strip the root prefix so only the wind tree's own folders are checked
rel = f;
if nargin > 1 && ~isempty(root)
    r = root;
    if ~isempty(r) && (r(end) == filesep || r(end) == '/')
        r = r(1:end-1);
    end
    if strncmpi(f,r,length(r))
        rel = f(length(r)+1 : end);
    end
end

% split on either separator - do not use strsplit(.,filesep), a lone
% backslash is processed as an escape sequence there
parts = regexp(rel,'[\\/]','split');
parts = parts(~cellfun(@isempty,parts));
if numel(parts) > 1
    parts = parts(1:end-1);   % folders only, ignore the filename
else
    parts = {};               % file sits directly in root
end

for k = 1 : numel(parts)
    if any(strcmpi(parts{k},words))
        tf = true; word = parts{k};
        return
    end
end
end

% =======================================================================
function [tf,coverage] = coversYear(matfile,yrStart,yrEnd)
%COVERSYEAR  True if matfile holds any wind sample inside [yrStart,yrEnd).
% Loads only dnvec, so it is cheap enough to test several candidates.
tf = false;
coverage = 'unreadable';
try
    D = load(matfile,'dnvec');
catch
    return
end
if ~isfield(D,'dnvec') || isempty(D.dnvec)
    coverage = 'no dnvec';
    return
end
d = D.dnvec(:);
coverage = sprintf('%s to %s',datestr(min(d),'yyyy-mm-dd'), ...
    datestr(max(d),'yyyy-mm-dd'));
tf = any(d >= yrStart & d < yrEnd);
end
