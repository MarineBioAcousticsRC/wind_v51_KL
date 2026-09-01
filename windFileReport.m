function T = windFileReport(folder,pattern)
%WINDFILEREPORT  List every wind .mat under a folder with its date coverage.
%
%   windFileReport(folder)            scans folder and all subfolders
%   windFileReport(folder,pattern)    e.g. '*windvec.mat' (default)
%   T = windFileReport(...)           also returns the result as a table
%
%   Answers "what wind data do I actually have, and for which years?"
%   without opening files one at a time. Use it when loadWindData reports
%   no overlap with your LTSA period.
%
%   Example:
%       windFileReport('Z:\Wind_deltaTF\Wind_Data\SOCAL')
%       windFileReport(p.harp.WindFolder)
%
%   KL 2026-08

if nargin < 2 || isempty(pattern)
    pattern = '*windvec.mat';
end
if nargin < 1 || isempty(folder)
    error('windFileReport:noFolder','Give me a folder to scan.');
end
if ~isfolder(folder)
    error('windFileReport:badFolder','Not a folder:\n  %s',folder);
end

d = dir(fullfile(folder,'**',pattern));
if isempty(d)
    fprintf('No files matching %s under:\n  %s\n',pattern,folder);
    T = table();
    return
end

fprintf('\n%d file(s) matching %s under %s\n\n',numel(d),pattern,folder);
fprintf('%-52s %10s  %-10s %-10s %8s  %s\n', ...
    'FILE','SAMPLES','FIRST','LAST','MEDIAN','YEARS COVERED');
fprintf('%s\n',repmat('-',1,132));

name = cell(numel(d),1); relpath = cell(numel(d),1);
nsamp = zeros(numel(d),1); first = NaT(numel(d),1); last = NaT(numel(d),1);
dtHrs = nan(numel(d),1);   yearsCov = cell(numel(d),1);

for k = 1 : numel(d)
    f = fullfile(d(k).folder,d(k).name);
    rel = strrep(f,[folder,filesep],'');
    name{k} = d(k).name;
    relpath{k} = rel;
    try
        D = load(f,'dnvec');
    catch ME
        fprintf('%-52s  !! could not load: %s\n',shorten(rel,52),ME.message);
        yearsCov{k} = 'unreadable';
        continue
    end
    if ~isfield(D,'dnvec') || isempty(D.dnvec)
        fprintf('%-52s  !! no dnvec variable\n',shorten(rel,52));
        yearsCov{k} = 'no dnvec';
        continue
    end
    dn = sort(D.dnvec(:));
    nsamp(k) = numel(dn);
    first(k) = datetime(dn(1),'ConvertFrom','datenum');
    last(k)  = datetime(dn(end),'ConvertFrom','datenum');
    if numel(dn) > 1
        dtHrs(k) = median(diff(dn)) * 24;
    end
    yrs = unique(year(datetime(dn,'ConvertFrom','datenum')));
    yearsCov{k} = compressYears(yrs);

    fprintf('%-52s %10d  %-10s %-10s %6.2f h  %s\n', ...
        shorten(rel,52), nsamp(k), ...
        datestr(dn(1),'yyyy-mm-dd'), datestr(dn(end),'yyyy-mm-dd'), ...
        dtHrs(k), yearsCov{k});
end
fprintf('\n');

T = table(name,relpath,nsamp,first,last,dtHrs,yearsCov, ...
    'VariableNames',{'File','RelPath','Samples','First','Last','MedianHrs','Years'});
if nargout == 0
    clear T
end
end

% -----------------------------------------------------------------------
function s = compressYears(yrs)
%COMPRESSYEARS  [2016 2017 2018 2022] -> '2016-2018, 2022'
yrs = sort(yrs(:))';
if isempty(yrs)
    s = '';
    return
end
runs = {}; a = yrs(1); b = yrs(1);
for i = 2 : numel(yrs)
    if yrs(i) == b + 1
        b = yrs(i);
    else
        runs{end+1} = fmtRun(a,b); %#ok<AGROW>
        a = yrs(i); b = yrs(i);
    end
end
runs{end+1} = fmtRun(a,b);
s = strjoin(runs,', ');
end

function s = fmtRun(a,b)
if a == b
    s = num2str(a);
else
    s = sprintf('%d-%d',a,b);
end
end

function s = shorten(str,n)
%SHORTEN  Trim from the left so the filename stays visible.
if numel(str) <= n
    s = str;
else
    s = ['...',str(end-n+4:end)];
end
end
