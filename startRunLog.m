function logfile = startRunLog(p)
%STARTRUNLOG  Begin a diary of the command window for this run.
%
%   logfile = startRunLog(p)
%
%   Captures everything printed to the command window - prompts, the wind
%   and TF files chosen, warnings, the matched-point counts, and any error
%   - into a timestamped text file under p.harp.OutLog, so a run can be
%   reconstructed afterwards without relying on scrollback.
%
%   Writes a header first recording who ran it, on what machine, when,
%   which MATLAB, and the parameters that were in force.
%
%   Close it with  diary off  at the end of the run.
%
%   KL 2026-08

if ~isfield(p,'harp') || ~isfield(p.harp,'OutLog') || isempty(p.harp.OutLog)
    warning('startRunLog:noFolder', ...
        'p.harp.OutLog is not set - no run log will be written.');
    logfile = '';
    return
end

logdir = p.harp.OutLog;
if ~isfolder(logdir)
    [ok,msg] = mkdir(logdir);
    if ~ok
        warning('startRunLog:mkdirFailed', ...
            'Could not create log folder:\n  %s\n  %s',logdir,msg);
        logfile = '';
        return
    end
    fprintf('Created log folder: %s\n',logdir);
end

stamp = datestr(now,'yyyymmdd_HHMMSS');
base  = regexprep(p.harp.dBaseName,'[^\w-]','_');   % safe for a filename
logfile = fullfile(logdir,[base,'_',stamp,'_runlog.txt']);

diary off            % close anything left open by a previous run that errored
diary(logfile)

fprintf('===========================================================\n');
fprintf(' WindLTSA run log\n');
fprintf('===========================================================\n');
fprintf('Started    : %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('User       : %s\n',getenvOr('USERNAME','UNKNOWN'));
fprintf('Machine    : %s\n',getenvOr('COMPUTERNAME','UNKNOWN'));
fprintf('MATLAB     : %s\n',version);
fprintf('Working dir: %s\n',pwd);
fprintf('Log file   : %s\n',logfile);
fprintf('-----------------------------------------------------------\n');
fprintf('Deployment : %s %s  depl %s   (%s)\n', ...
    p.harp.Proj,p.harp.Site,p.harp.Depl,p.harp.dBaseName);
fprintf('Bands      : low=%s  mid=%s  high=%s\n',p.usel,p.usem,p.use);
fprintf('Recalc avg : low=%s  mid=%s  high=%s\n',p.calavgl,p.calavgm,p.calavg);
fprintf('Time bin   : tres=%d (0=month 1=day 2=hour), NA=%d\n', ...
    p.harp.tres,p.harp.NA);
fprintf('Date window: %s to %s\n', ...
    datestr(p.dEarly,'yyyy-mm-dd'),datestr(p.dLate,'yyyy-mm-dd'));
if isfield(p,'minFitPts')
    fprintf('minFitPts  : %d\n',p.minFitPts);
end
fprintf('-----------------------------------------------------------\n');
fprintf('Wind folder: %s\n',p.harp.WindFolder);
if isfield(p,'windfile') && any(~cellfun(@isempty,p.windfile))
    fprintf('p.windfile pins:\n');
    for k = 1 : numel(p.windfile)
        if ~isempty(p.windfile{k})
            fprintf('   {%d} %s\n',k,p.windfile{k});
        end
    end
else
    fprintf('p.windfile : not set (automatic CCMP search)\n');
end
fprintf('LTSA folder: %s\n',p.ltsa.LTSAFolder);
fprintf('TF folder  : %s\n',p.tf.TFsFolder);
fprintf('Out folder : %s\n',p.harp.OutFolder);
fprintf('===========================================================\n\n');

end

% -----------------------------------------------------------------------
function v = getenvOr(name,dflt)
v = getenv(name);
if isempty(v)
    v = dflt;
end
end
