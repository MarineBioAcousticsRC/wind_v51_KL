function out = CompareWindTFs(stdFolder,windFolder)
%COMPAREWINDTFS  Compare a standard transfer function against wind-derived ones.
%
%   CompareWindTFs
%   CompareWindTFs(stdFolder,windFolder)
%   out = CompareWindTFs(...)
%
%   Prompts for:
%     1. the original "standard" hydrophone .tf file  (via getTFx)
%     2. one or more wind-derived .tf files           (multi-select)
%
%   Then draws:
%     Figure 1 - every transfer function on one axis, standard in black
%     Figure 2 - wind minus standard for each wind file, legend = filename
%
%   Differences are evaluated on each wind file's own frequency grid, with
%   the standard TF interpolated onto it. Nothing is extrapolated: outside
%   the standard TF's frequency range the difference is left as NaN and the
%   overlap actually used is reported.
%
%   INPUT (both optional)
%     stdFolder  - folder the first dialog opens in. Default MBARC_TF.
%     windFolder - folder the second dialog opens in. Default TF_Wind.
%   You always pick the files by hand; these only set where the dialog
%   starts. Pass '' to accept a default, or a path to override it.
%
%   OUTPUT (optional)
%     out.std        .file .name .freq .uppc
%     out.wind(k)    .file .name .freq .uppc .diff .fOverlap .stats
%
%   Figures and a run log are written to TFCompareFolder below, all named
%   after the standard TF file so a set of outputs stays together.
%
%   KL 2026-08

%% ======================= FOLDERS - edit here ==========================
stdFolderDefault  = 'G:\Shared drives\MBARC_TF';
windFolderDefault = ['G:\Shared drives\MBARC_Engineering\Hydrophone_Lab\', ...
                     'wind\HARPs\TF_Wind'];
TFCompareFolder   = ['G:\Shared drives\MBARC_Engineering\Hydrophone_Lab\', ...
                     'wind\HARPs\TFComparison'];
%% ======================================================================

saveFigs        = true;   % write .fig and .png next to the run log
applyCutoff     = true;   % trim each wind TF to its saved Hz cutoff when there is one
reuseWindowMin  = 5;      % re-run inside this many minutes replaces the last set

%% ---------- where the dialogs should open ------------------------------
% The defaults above win. A path passed in as an argument overrides them.
% If a default folder is not reachable (drive not mapped) the dialog just
% opens in the current folder - you still choose the file either way.
if nargin < 1 || isempty(stdFolder)
    stdFolder = stdFolderDefault;
end
if ~isfolder(stdFolder)
    fprintf(2,'Standard-TF folder not reachable, opening in %s instead:\n  %s\n', ...
        pwd,stdFolder);
    stdFolder = pwd;
end
if nargin < 2 || isempty(windFolder)
    windFolder = windFolderDefault;
end
if ~isfolder(windFolder)
    fprintf(2,'Wind-TF folder not reachable, opening in %s instead:\n  %s\n', ...
        pwd,windFolder);
    windFolder = pwd;
end

%% ---------- 1. the standard TF ----------------------------------------
fprintf('\n=== Compare wind-derived TFs against a standard TF ===\n');
[fStd,uStd,stdFull] = getTFx(stdFolder,'STANDARD / original TF');
[~,stdBase,stdExt] = fileparts(stdFull);
stdName = [stdBase,stdExt];

%% ---------- output folder, and start logging ---------------------------
% Every output from this run - both figures and this log - is named after
% the standard TF plus a timestamp, so one comparison's files sort together
% and repeat runs never overwrite each other.
outDir = TFCompareFolder;
if ~isfolder(outDir)
    [ok,msg] = mkdir(outDir);
    if ok
        fprintf('Created output folder: %s\n',outDir);
    else
        fprintf(2,['Could not create the output folder:\n  %s\n  %s\n', ...
            'Saving alongside the wind TFs instead.\n'],outDir,msg);
        outDir = windFolder;
    end
end

% Re-running within reuseWindowMin of the last run for this same standard
% TF overwrites that run's outputs instead of adding another set. A repeat
% that fast is almost always a correction, not a second result worth
% keeping. Older runs are never touched.
safeBase = regexprep(stdBase,'[^\w-]','_');
[stamp,reused] = runStamp(outDir,safeBase,reuseWindowMin);
runBase  = [safeBase,'_TFcompare_',stamp];
logFile  = fullfile(outDir,[runBase,'_log.txt']);

if reused
    fprintf(2,['Re-run within %g min of %s - replacing that run''s files ', ...
        'rather than making new ones.\n'],reuseWindowMin,stamp);
    delete2(logFile);
    delete2(fullfile(outDir,[runBase,'.fig']));
    delete2(fullfile(outDir,[runBase,'.png']));
    delete2(fullfile(outDir,[safeBase,'_TFdiff_',stamp,'.fig']));
    delete2(fullfile(outDir,[safeBase,'_TFdiff_',stamp,'.png']));
end

% onCleanup guarantees the diary closes even if this function errors, so a
% failed run cannot leave the diary capturing unrelated command window text
diary off
diary(logFile)
closeDiary = onCleanup(@() diary('off'));   %#ok<NASGU>

fprintf('===========================================================\n');
fprintf(' CompareWindTFs run log\n');
fprintf('===========================================================\n');
fprintf('Started     : %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('User        : %s\n',getenvOr('USERNAME','UNKNOWN'));
fprintf('Machine     : %s\n',getenvOr('COMPUTERNAME','UNKNOWN'));
fprintf('MATLAB      : %s\n',version);
fprintf('Output dir  : %s\n',outDir);
fprintf('Log file    : %s\n',logFile);
fprintf('Standard TF : %s\n',stdFull);
fprintf('              %d points, %g to %g Hz\n', ...
    numel(fStd),fStd(1),fStd(end));
fprintf('-----------------------------------------------------------\n');

%% ---------- 2. one or more wind TFs -----------------------------------
[wFiles,wPath] = uigetfile('*.tf', ...
    'Pick WIND-derived TF file(s)  -  select one or many', ...
    windFolder,'MultiSelect','on');
if isequal(wFiles,0)
    error('CompareWindTFs:noWindTF','No wind TF selected - stopping.');
end
if ~iscell(wFiles)
    wFiles = {wFiles};      % single selection comes back as a char row
end
nW = numel(wFiles);
fprintf('\nStandard TF : %s\n',stdFull);
fprintf('Wind TFs    : %d file(s) from %s\n',nW,wPath);

%% ---------- read them and difference each ------------------------------
% NOTE ON CUTOFFS
% WindLTSA writes a wind TF across the whole band, but tfmake51/tfmakel51
% hold the correction FLAT outside the correlated range - MTFCorr(col)
% below it and MTFCorr(coh) above. Those shoulders are a carried-out edge
% value, not measured correlation, so they drag the statistics around and
% are misleading to plot as if they were results.
%
% Where the matching TFCorr .mat records the range in Hz, this trims to it.
% Only the per-band Hz fields written from Aug 2026 are trusted; the older
% col/coh are bin indices AND are overwritten between bands within one run,
% so they are deliberately ignored. A wind TF with no usable cutoff is left
% at full range and marked with * in the legend and the table.
W = struct('file',{},'name',{},'legName',{},'freq',{},'uppc',{},'diff',{}, ...
    'fOverlap',{},'cut',{},'cutSrc',{},'inBand',{},'stats',{});
nFlagged = 0;
for k = 1 : nW
    f = fullfile(wPath,wFiles{k});
    [fw,uw] = readTFfile(f);
    [~,nm,ex] = fileparts(f);

    % standard TF onto this wind TF's grid, no extrapolation
    uStdOn = interp1(fStd,uStd,fw,'linear',NaN);
    d      = uw - uStdOn;
    ok     = ~isnan(d);

    % the correlated range, if it was saved
    [cut,cutSrc] = findCutoff(f);
    if ~applyCutoff
        cut = [];
        cutSrc = 'cutoffs disabled (applyCutoff = false)';
    end
    inBand = true(size(fw));
    if ~isempty(cut)
        inBand = fw >= cut(1) & fw <= cut(2);
        if ~any(inBand & ok)
            fprintf(2,['Cutoff %g-%g Hz leaves nothing for %s%s - ', ...
                'ignoring it and using the full range.\n'],cut(1),cut(2),nm,ex);
            cut = [];
            cutSrc = 'saved cutoff excluded all points';
            inBand = true(size(fw));
        end
    end
    use = ok & inBand;

    W(k).file     = f;
    W(k).name     = [nm,ex];
    W(k).legName  = [nm,ex];
    if isempty(cut)
        W(k).legName = [nm,ex,' *'];
        nFlagged = nFlagged + 1;
    end
    % freq/uppc/diff stay FULL LENGTH - downstream tools such as DrawWIC
    % keep seeing exactly what they saw before. inBand is the mask this
    % function plots and summarises with.
    W(k).freq     = fw;
    W(k).uppc     = uw;
    W(k).diff     = d;
    W(k).cut      = cut;
    W(k).cutSrc   = cutSrc;
    W(k).inBand   = inBand;
    W(k).fOverlap = [NaN NaN];
    if any(use)
        W(k).fOverlap = [min(fw(use)) max(fw(use))];
    end
    W(k).stats = struct( ...
        'nPoints',   sum(use), ...
        'meanDiff',  mean(d(use)), ...
        'medianDiff',median(d(use)), ...
        'maxAbsDiff',max(abs(d(use))), ...
        'rmsDiff',   sqrt(mean(d(use).^2)));
end

fprintf('\n%-42s %s\n','WIND TF','CORRELATED RANGE APPLIED');
fprintf('%s\n',repmat('-',1,110));
for k = 1 : nW
    if isempty(W(k).cut)
        fprintf('%-42s  none *  (%s)\n',shorten(W(k).name,42),W(k).cutSrc);
    else
        fprintf('%-42s  %g to %g Hz  (%s)\n',shorten(W(k).name,42), ...
            W(k).cut(1),W(k).cut(2),W(k).cutSrc);
    end
end
if nFlagged > 0
    fprintf(['* no saved Hz cutoff found - shown at full range, so the ', ...
        'flat shoulders\n  outside the correlated band are included.\n']);
end

%% ---------- console summary -------------------------------------------
fprintf('\n%-42s %9s %9s %9s %9s  %s\n', ...
    'WIND TF','MEAN dB','MEDIAN','MAX|d|','RMS','OVERLAP USED (Hz)');
fprintf('%s\n',repmat('-',1,110));
for k = 1 : nW
    s = W(k).stats;
    if s.nPoints == 0
        fprintf('%-42s   no frequency overlap with the standard TF\n', ...
            shorten(W(k).name,42));
        continue
    end
    fprintf('%-42s %9.2f %9.2f %9.2f %9.2f  %g to %g  (%d pts)\n', ...
        shorten(W(k).name,42),s.meanDiff,s.medianDiff,s.maxAbsDiff, ...
        s.rmsDiff,W(k).fOverlap(1),W(k).fOverlap(2),s.nPoints);
end

% difference at a few reference frequencies, where they exist
refF = [50 100 200 500 1000 2000 5000 10000 20000];
fprintf('\n%-42s','DIFFERENCE AT (Hz):');
fprintf('%8g',refF); fprintf('\n');
fprintf('%s\n',repmat('-',1,110));
for k = 1 : nW
    fprintf('%-42s',shorten(W(k).name,42));
    for r = refF
        v = NaN;
        if isempty(W(k).cut) || (r >= W(k).cut(1) && r <= W(k).cut(2))
            v = interp1(W(k).freq,W(k).diff,r,'linear',NaN);
        end
        if isnan(v)
            fprintf('%8s','-');
        else
            fprintf('%8.2f',v);
        end
    end
    fprintf('\n');
end
fprintf('\n');

%% ---------- colours ----------------------------------------------------
col = lines(max(nW,3));

%% ---------- Figure 1 : all transfer functions --------------------------
f1 = figure(2001); clf
set(f1,'Name','Transfer functions','NumberTitle','off');
hAll = gobjects(nW+1,1);
hAll(1) = semilogx(fStd,uStd,'k-','LineWidth',3); hold on
for k = 1 : nW
    m = W(k).inBand;
    hAll(k+1) = semilogx(W(k).freq(m),W(k).uppc(m),'-','LineWidth',1.5, ...
        'Color',col(k,:));
end
grid on; box on
xlabel('Frequency [Hz]');
ylabel('TF [dB re uPa/counts]');
title('Standard vs wind-derived transfer functions');
legend(hAll,[{stdName},{W.legName}],'Interpreter','none','Location','best');
xlim(padRange([fStd, W.freq]));

%% ---------- Figure 2 : wind minus standard -----------------------------
f2 = figure(2002); clf
set(f2,'Name','Wind TF minus standard TF','NumberTitle','off');
hD = gobjects(nW,1);
for k = 1 : nW
    m = W(k).inBand;
    hD(k) = semilogx(W(k).freq(m),W(k).diff(m),'-','LineWidth',1.8, ...
        'Color',col(k,:)); hold on
end
yline(0,'k--','LineWidth',1.5,'HandleVisibility','off');
grid on; box on
xlabel('Frequency [Hz]');
ylabel('Wind TF - standard TF [dB]');
title(['Difference from ',stdName],'Interpreter','none');
legend(hD,{W.legName},'Interpreter','none','Location','best');
xlim(padRange([W.freq]));
if nFlagged > 0
    xl = xlim; yl = ylim;
    text(xl(1),yl(1),'  * no saved Hz cutoff - full range shown', ...
        'VerticalAlignment','bottom','FontSize',9,'Color',[0.35 0.35 0.35]);
end

%% ---------- save figures -----------------------------------------------
if saveFigs
    b1 = fullfile(outDir,runBase);
    b2 = fullfile(outDir,[safeBase,'_TFdiff_',stamp]);
    try
        savefig(f1,b1);  saveas(f1,b1,'png');
        savefig(f2,b2);  saveas(f2,b2,'png');
        fprintf('Saved figures:\n  %s.fig / .png\n  %s.fig / .png\n',b1,b2);
    catch ME
        fprintf(2,'Could not save figures to %s\n  %s\n',outDir,ME.message);
    end
end

fprintf('\nFinished %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('Run log: %s\n',logFile);

%% ---------- output -----------------------------------------------------
if nargout > 0
    out.std.file = stdFull;
    out.std.name = stdName;
    out.std.freq = fStd;
    out.std.uppc = uStd;
    out.wind     = W;
    out.outDir   = outDir;
    out.stamp    = stamp;
    out.safeBase = safeBase;
    out.logFile  = logFile;
end
end

% -----------------------------------------------------------------------
function v = padRange(f)
%PADRANGE  x limits covering all positive frequencies present.
f = f(:);
f = f(isfinite(f) & f > 0);
if isempty(f)
    v = [1 100000];
    return
end
v = [min(f)*0.9, max(f)*1.1];
if v(1) >= v(2)
    v = [v(1)*0.5, v(1)*2];
end
end

% -----------------------------------------------------------------------
function s = shorten(str,n)
%SHORTEN  Trim from the left so the distinctive tail stays visible.
if numel(str) <= n
    s = str;
else
    s = ['...',str(end-n+4:end)];
end
end

% -----------------------------------------------------------------------
function v = getenvOr(name,dflt)
v = getenv(name);
if isempty(v)
    v = dflt;
end
end

% -----------------------------------------------------------------------
function [stamp,reused] = runStamp(outDir,safeBase,windowMin)
%RUNSTAMP  Reuse the previous run's timestamp if it is very recent.
% Looks for this standard TF's most recent log in outDir and reads the
% timestamp out of its name. Within windowMin minutes that stamp is reused,
% so the run overwrites itself instead of leaving a near-duplicate set.
stamp  = datestr(now,'yyyymmdd_HHMMSS');
reused = false;
if windowMin <= 0
    return
end
d = dir(fullfile(outDir,[safeBase,'_TFcompare_*_log.txt']));
if isempty(d)
    return
end
best = ''; bestAge = Inf;
for k = 1 : numel(d)
    tok = regexp(d(k).name,'_TFcompare_(\d{8}_\d{6})_log\.txt$','tokens','once');
    if isempty(tok)
        continue
    end
    try
        t = datenum(tok{1},'yyyymmdd_HHMMSS');
    catch
        continue
    end
    ageMin = (now - t)*24*60;
    if ageMin >= 0 && ageMin < bestAge
        bestAge = ageMin;
        best    = tok{1};
    end
end
if ~isempty(best) && bestAge < windowMin
    stamp  = best;
    reused = true;
end
end

% -----------------------------------------------------------------------
function delete2(f)
%DELETE2  Delete a file if it is there, without warning if it is not.
if exist(f,'file') == 2
    delete(f);
end
end

% -----------------------------------------------------------------------
function [cut,src] = findCutoff(windTFfile)
%FINDCUTOFF  The correlated Hz range for a wind TF, from its TFCorr .mat.
%
% WindLTSA writes, in <OutFolder>:
%     TF_Wind\<tfn>_<Proj><Site>_<Depl>_TFnew[m|l].tf
%     TFCorr \<Proj><Site>_<Depl>_TFCorr[m|l].mat
% so the .mat can be found from the .tf name. Only the per-band Hz fields
% added Aug 2026 are read. The older col/coh are NOT used: they are bin
% indices whose scale differs per band, and one col/coh pair is shared by
% all three bands in a run, so in a multi-band run they can carry another
% band's values. A wrong cutoff is worse than none.

cut = [];
[wp,wn] = fileparts(windTFfile);

if endsWith(wn,'TFnewm')
    band = 'm'; lo = 'cutlowHzm'; hi = 'cuthighHzm';
elseif endsWith(wn,'TFnewl')
    band = 'l'; lo = 'cutlowHzl'; hi = 'cuthighHzl';
elseif endsWith(wn,'TFnew')
    band = '';  lo = 'cutlowHz';  hi = 'cuthighHz';
else
    src = 'filename is not a WindLTSA TFnew file';
    return
end

tok = strsplit(wn,'_');
if numel(tok) < 3
    src = 'filename does not carry a deployment name';
    return
end
dBase    = strjoin(tok(2:end-1),'_');          % e.g. SOCALB_47
corrName = [dBase,'_TFCorr',band,'.mat'];

cands = { fullfile(fileparts(wp),'TFCorr',corrName)
          fullfile(wp,'..','TFCorr',corrName)
          fullfile(wp,corrName) };
corrFile = '';
for i = 1 : numel(cands)
    if exist(cands{i},'file') == 2
        corrFile = cands{i};
        break
    end
end
if isempty(corrFile)
    src = ['no ',corrName,' found'];
    return
end

try
    S = load(corrFile,lo,hi);
catch
    src = ['could not read ',corrName];
    return
end
if ~isfield(S,lo) || ~isfield(S,hi)
    src = [corrName,' predates the Hz cutoffs'];
    return
end
a = S.(lo); b = S.(hi);
if ~isscalar(a) || ~isscalar(b) || ~isfinite(a) || ~isfinite(b) || a >= b
    src = [corrName,' has an unusable cutoff pair'];
    return
end
cut = [a b];
src = corrName;
end
