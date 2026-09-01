function wicFile = DrawWIC(out)
%DRAWWIC  Draw a Wind Informed Correction by hand and save it as a .fvg file.
%
%   DrawWIC              runs CompareWindTFs first, then opens the drawing
%   DrawWIC(out)         uses an existing result: out = CompareWindTFs;
%   wicFile = DrawWIC(...)   returns the path written
%
%   Shows the same wind-minus-standard differences as figure 2002 in a
%   large window, and lets you build an approximate correction across them
%   by clicking. Points appear as you click and stay live: drag any of
%   them to move it, right-click one to delete it, Undo removes the last.
%   The red preview and the resampled grid points update as you drag, so
%   what you see is exactly what gets written.
%
%   Nothing is saved until you press Save WIC.
%
%   Uses only base MATLAB graphics - no Image Processing Toolbox needed,
%   so the behaviour is the same on every machine.
%
%   The line is interpolated in log10(frequency), matching what you see on
%   the log x-axis, so the saved curve follows the line you actually drew.
%   Beyond the ends of your line the value is held flat at the nearest end
%   rather than extrapolated.
%
%   SIGN CONVENTION - the file is the NEGATIVE of the plot.
%   The plot shows  wind TF - standard TF.  The .fvg is a correction to be
%   applied to the standard TF, so it is written as  standard - wind, i.e.
%   the drawn values with the sign flipped. Draw at -2.5 dB on the plot and
%   the file contains +2.5, and vice versa. Set flipSignForFile = false
%   below to write the drawn values unchanged.
%
%   KL 2026-08

%% ======================= SETTINGS - edit here =========================
initials = 'KL';        % goes in the .fvg header line

% Output frequency grid, kHz. This reproduces the grid in the existing
% MBARC WIC files exactly - note it jumps 0.01 -> 0.201, i.e. there is no
% 0.101 entry. Kept as-is so new files match the old ones; add 0.101 here
% if that gap was not intended.
wicGridkHz = [0.01, 0.201:0.1:3.001, 4.001:1:20.001];

figFrac = 0.85;         % fraction of the screen the drawing window fills

% The plot is wind minus standard. A WIC is a correction applied TO the
% standard TF, so it takes the opposite sign. Leave true unless you are
% deliberately changing the convention of the .fvg files.
flipSignForFile = true;
%% ======================================================================

if nargin < 1 || isempty(out)
    out = CompareWindTFs;      % writes its own figures and log first
end
if ~isstruct(out) || ~isfield(out,'wind') || isempty(out.wind)
    error('DrawWIC:badInput', ...
        'Need the struct from  out = CompareWindTFs;  with at least one wind TF.');
end

outDir = out.outDir;
W      = out.wind;
nW     = numel(W);

% carry on writing into the same run log
if isfield(out,'logFile') && ~isempty(out.logFile)
    diary(out.logFile);                       % appends
    closeDiary = onCleanup(@() diary('off')); %#ok<NASGU>
end
fprintf('\n----------------------- DrawWIC ---------------------------\n');
fprintf('Started : %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'));

%% ---------- a big drawing window --------------------------------------
scr = get(0,'ScreenSize');
wPx = round(scr(3)*figFrac);
hPx = round(scr(4)*figFrac);
fW  = figure(2003); clf
set(fW,'Name','Draw Wind Informed Correction','NumberTitle','off', ...
    'Position',[scr(1)+round((scr(3)-wPx)/2), ...
                scr(2)+round((scr(4)-hPx)/2), wPx, hPx], ...
    'Color','w');

ax = axes('Parent',fW,'Position',[0.07 0.17 0.90 0.74]);
col = lines(max(nW,3));
hD  = gobjects(nW,1);
% Same view as CompareWindTFs figure 2002: each wind TF is trimmed to its
% saved Hz cutoff where there is one, and marked with * in the legend where
% there is not. inBand/legName are set by CompareWindTFs; the fallbacks let
% this still run on a struct built before those fields existed.
nFlagged = 0;
legNames = cell(1,nW);
for k = 1 : nW
    if isfield(W,'inBand') && ~isempty(W(k).inBand)
        m = W(k).inBand;
    else
        m = true(size(W(k).freq));
    end
    if isfield(W,'legName') && ~isempty(W(k).legName)
        legNames{k} = W(k).legName;   %#ok<AGROW>
    else
        legNames{k} = W(k).name;      %#ok<AGROW>
    end
    if ~isempty(strfind(legNames{k},' *')) %#ok<STREMP>
        nFlagged = nFlagged + 1;
    end
    hD(k) = semilogx(ax,W(k).freq(m),W(k).diff(m),'-','LineWidth',1.5, ...
        'Color',col(k,:)); hold(ax,'on')
end
% clicks must reach the axes, not the difference curves
set(hD,'PickableParts','none','HitTest','off');
hZero = yline(0,'k--','LineWidth',1.2,'HandleVisibility','off');
try
    set(hZero,'PickableParts','none','HitTest','off');
catch
end
grid(ax,'on'); box(ax,'on')
set(ax,'FontSize',11);
xlabel(ax,'Frequency [Hz]','FontSize',12);
ylabel(ax,'Wind TF - standard TF [dB]','FontSize',12);
legend(hD,legNames,'Interpreter','none','Location','best');
xlim(ax,padRange([W.freq]));
if nFlagged > 0
    xl = xlim(ax); yl = ylim(ax);
    text(ax,xl(1),yl(1),'  * no saved Hz cutoff - full range shown', ...
        'VerticalAlignment','bottom','FontSize',9,'Color',[0.35 0.35 0.35], ...
        'PickableParts','none','HitTest','off');
end

%% ---------- click / drag / confirm -------------------------------------
[xv,yv,action] = pickLineInteractive(fW,ax,wicGridkHz);

wicFile = '';
if ~strcmp(action,'save')
    fprintf('Cancelled - nothing written.\n');
    fprintf('-----------------------------------------------------------\n');
    if nargout == 0
        clear wicFile
    end
    return
end

[v,fGridHz,nBelow,nAbove] = wicResample(xv,yv,wicGridkHz);

fprintf('\nDrawn line: %d vertices, %g to %g Hz\n',numel(xv),min(xv),max(xv));
fprintf('As drawn  : %d points, %g to %g kHz, %.2f to %.2f dB  (wind - standard)\n', ...
    numel(v),wicGridkHz(1),wicGridkHz(end),min(v),max(v));
if nBelow || nAbove
    fprintf(['Held flat outside the drawn range: %d point(s) below %g Hz ', ...
        'at %.2f dB, %d above %g Hz at %.2f dB\n'], ...
        nBelow,min(xv),yv(1),nAbove,max(xv),yv(end));
end

% A WIC corrects the standard TF, so it is the negative of the plotted
% difference. The plot and the drawing keep the wind-minus-standard sign;
% only the values written to the .fvg are flipped.
if flipSignForFile
    vFile = -v;
    fprintf('Written   : sign flipped to standard - wind, %.2f to %.2f dB\n', ...
        min(vFile),max(vFile));
else
    vFile = v;
    fprintf(2,'Written   : flipSignForFile = false, values written AS DRAWN\n');
end

wicFile = writeWIC(outDir,out,wicGridkHz(:),vFile,initials);

% keep a picture of the WIC that was drawn, alongside it
try
    [~,wn] = fileparts(wicFile);
    if flipSignForFile
        title(ax,{wn,['plot = wind - standard;  .fvg written with the ', ...
            'sign flipped (standard - wind)']}, ...
            'Interpreter','none','FontSize',12);
    else
        title(ax,{wn,'.fvg written as drawn, sign NOT flipped'}, ...
            'Interpreter','none','FontSize',12);
    end
    figBase = fullfile(outDir,wn);
    savefig(fW,figBase); saveas(fW,figBase,'png');
    fprintf('  figure           : %s.fig / .png\n',figBase);
catch ME
    fprintf(2,'  could not save the WIC figure: %s\n',ME.message);
end

fprintf('Finished %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('-----------------------------------------------------------\n');
if nargout == 0
    clear wicFile
end
end

% =======================================================================
function [xv,yv,action] = pickLineInteractive(fW,ax,wicGridkHz)
%PICKLINEINTERACTIVE  Click to add points, drag to move, right-click to delete.
% Base MATLAB only. Blocks until Save WIC or Cancel.

V       = zeros(0,2);     % vertices, [freqHz dB]
dragIdx = [];
action  = 'cancel';
xv = []; yv = [];

% preview graphics
hPrev = plot(ax,NaN,NaN,'o','MarkerSize',5,'MarkerEdgeColor','k', ...
    'MarkerFaceColor',[0.95 0.55 0.15],'PickableParts','none','HitTest','off');
hLine = plot(ax,NaN,NaN,'-o','Color',[0.85 0.1 0.1],'LineWidth',2.5, ...
    'MarkerSize',10,'MarkerFaceColor','w','MarkerEdgeColor',[0.85 0.1 0.1], ...
    'LineWidth',2.5);

set(ax,'ButtonDownFcn',@addPoint);
set(hLine,'ButtonDownFcn',@startDrag);
set(fW,'CloseRequestFcn',@onClose);

hInfo = uicontrol(fW,'Style','text','Units','normalized', ...
    'Position',[0.07 0.055 0.90 0.035],'HorizontalAlignment','left', ...
    'BackgroundColor','w','FontSize',11,'String','');

uicontrol(fW,'Style','text','Units','normalized', ...
    'Position',[0.07 0.945 0.90 0.04],'HorizontalAlignment','left', ...
    'BackgroundColor','w','FontSize',12,'FontWeight','bold', ...
    'String',['Click on the plot to add points  |  drag a point to move it  |  ', ...
              'right-click a point to delete it']);

uicontrol(fW,'Style','pushbutton','Units','normalized', ...
    'Position',[0.07 0.005 0.12 0.045],'String','Save WIC', ...
    'FontSize',11,'FontWeight','bold','Callback',@onSave);
uicontrol(fW,'Style','pushbutton','Units','normalized', ...
    'Position',[0.20 0.005 0.10 0.045],'String','Undo point', ...
    'FontSize',11,'Callback',@onUndo);
uicontrol(fW,'Style','pushbutton','Units','normalized', ...
    'Position',[0.31 0.005 0.10 0.045],'String','Clear all', ...
    'FontSize',11,'Callback',@onClear);
uicontrol(fW,'Style','pushbutton','Units','normalized', ...
    'Position',[0.42 0.005 0.10 0.045],'String','Cancel', ...
    'FontSize',11,'Callback',@onCancel);

refresh();
uiwait(fW);

% figure may have been closed
if isvalid(fW)
    set(fW,'CloseRequestFcn','closereq', ...
        'WindowButtonMotionFcn','','WindowButtonUpFcn','');
    if isvalid(ax)
        set(ax,'ButtonDownFcn','');
    end
end

    % ---------------- callbacks ----------------------------------------
    function addPoint(~,~)
        if strcmp(get(fW,'SelectionType'),'alt')
            return                     % right-click on empty space: ignore
        end
        cp = get(ax,'CurrentPoint');
        V(end+1,:) = [cp(1,1) cp(1,2)];  %#ok<AGROW>
        refresh();
    end

    function startDrag(~,~)
        cp = get(ax,'CurrentPoint');
        [d,i] = nearestVertex(cp(1,1),cp(1,2));
        if isempty(i) || d > 0.04
            addPoint();                % clicked the line, not a vertex
            return
        end
        if strcmp(get(fW,'SelectionType'),'alt')
            V(i,:) = [];               % right-click a vertex: delete it
            refresh();
            return
        end
        dragIdx = i;
        set(fW,'WindowButtonMotionFcn',@doDrag,'WindowButtonUpFcn',@endDrag);
    end

    function doDrag(~,~)
        if isempty(dragIdx)
            return
        end
        cp = get(ax,'CurrentPoint');
        xl = get(ax,'XLim'); yl = get(ax,'YLim');
        V(dragIdx,1) = min(max(cp(1,1),xl(1)),xl(2));
        V(dragIdx,2) = min(max(cp(1,2),yl(1)),yl(2));
        refresh();
    end

    function endDrag(~,~)
        dragIdx = [];
        set(fW,'WindowButtonMotionFcn','','WindowButtonUpFcn','');
    end

    function onUndo(~,~)
        if ~isempty(V)
            V(end,:) = [];
        end
        refresh();
    end

    function onClear(~,~)
        V = zeros(0,2);
        refresh();
    end

    function onSave(~,~)
        [xs,ys] = sortedVerts();
        if numel(xs) < 2
            set(hInfo,'String', ...
                'Need at least two points at different frequencies before saving.');
            return
        end
        xv = xs; yv = ys; action = 'save';
        uiresume(fW);
    end

    function onCancel(~,~)
        action = 'cancel';
        uiresume(fW);
    end

    function onClose(~,~)
        action = 'cancel';
        uiresume(fW);
    end

    % ---------------- helpers ------------------------------------------
    function [xs,ys] = sortedVerts()
        xs = []; ys = [];
        if isempty(V)
            return
        end
        [xs,is] = sort(V(:,1));
        ys = V(is,2);
        [xs,iu] = unique(xs);          % one value per frequency
        ys = ys(iu);
    end

    function [d,i] = nearestVertex(x,y)
        d = Inf; i = [];
        if isempty(V)
            return
        end
        xl = get(ax,'XLim'); yl = get(ax,'YLim');
        nx = (log10(V(:,1)) - log10(xl(1))) / (log10(xl(2)) - log10(xl(1)));
        ny = (V(:,2) - yl(1)) / (yl(2) - yl(1));
        px = (log10(x) - log10(xl(1))) / (log10(xl(2)) - log10(xl(1)));
        py = (y - yl(1)) / (yl(2) - yl(1));
        dd = hypot(nx - px, ny - py);
        [d,i] = min(dd);
    end

    function refresh()
        [xs,ys] = sortedVerts();
        set(hLine,'XData',xs,'YData',ys);
        if numel(xs) >= 2
            [v,fg] = wicResample(xs,ys,wicGridkHz);
            set(hPrev,'XData',fg,'YData',v);
            set(hInfo,'String',sprintf( ...
                ['%d point(s)   |   drawn %g to %g Hz   |   WIC %.2f to %.2f dB', ...
                 '   |   orange = the %d values that will be written'], ...
                numel(xs),min(xs),max(xs),min(v),max(v),numel(v)));
        else
            set(hPrev,'XData',NaN,'YData',NaN);
            set(hInfo,'String',sprintf( ...
                '%d point(s) - add at least two at different frequencies', ...
                numel(xs)));
        end
        drawnow limitrate
    end
end

% =======================================================================
function [v,fGridHz,nBelow,nAbove] = wicResample(xv,yv,wicGridkHz)
%WICRESAMPLE  Sample the drawn line onto the WIC grid, in log frequency.
% Outside the drawn range the value is held flat at the nearest end rather
% than extrapolated - a hand-drawn slope should not be projected out to
% 20 kHz on its own.
fGridHz = wicGridkHz(:) * 1000;
v = interp1(log10(xv),yv,log10(fGridHz),'linear',NaN);
nBelow = sum(fGridHz < min(xv));
nAbove = sum(fGridHz > max(xv));
v(fGridHz < min(xv)) = yv(1);
v(fGridHz > max(xv)) = yv(end);
v = round(v,2);
end

% =======================================================================
function wicFile = writeWIC(outDir,out,fkHz,v,initials)
%WRITEWIC  Write the .fvg file, matching the existing MBARC WIC layout.
%
% Name follows the standard TF: 988_220823_A_HARP.tf -> 988_220823_WIC.fvg
% (same shape as the existing 8_170720_WIC.fvg). If that name is taken by
% an older file, _v2, _v3 ... is appended rather than overwriting work.

tok = strsplit(out.safeBase,'_');
if numel(tok) >= 2
    stem = [tok{1},'_',tok{2}];
else
    stem = out.safeBase;
end

wicFile = fullfile(outDir,[stem,'_WIC.fvg']);
n = 1;
while exist(wicFile,'file') == 2
    n = n + 1;
    wicFile = fullfile(outDir,sprintf('%s_WIC_v%d.fvg',stem,n));
end
[~,wicName,wicExt] = fileparts(wicFile);

fid = fopen(wicFile,'w');
if fid < 0
    error('DrawWIC:cannotWrite','Could not write:\n  %s',wicFile);
end
fprintf(fid,'%% %s%s\r\n',wicName,wicExt);
fprintf(fid,'%% Wind informed correction\r\n');
fprintf(fid,'%% %s %s\r\n',initials,datestr(now,'mm/dd/yyyy'));
fprintf(fid,'%% \r\n');
fprintf(fid,'%% see %s\r\n',outDir);
fprintf(fid,'\r\n');
for i = 1 : numel(fkHz)
    fprintf(fid,'%g\t%g\r\n',fkHz(i),v(i));
end
fprintf(fid,'\r\n');
fclose(fid);

fprintf('\nWrote WIC: %s\n',wicFile);
fprintf('  from standard TF : %s\n',out.std.file);
for k = 1 : numel(out.wind)
    fprintf('  over wind TF     : %s\n',out.wind(k).file);
end
if n > 1
    fprintf(2,['  Note: %s_WIC.fvg already existed, so this was saved as ', ...
        'version %d.\n'],stem,n);
end
end

% =======================================================================
function vlim = padRange(f)
f = f(:);
f = f(isfinite(f) & f > 0);
if isempty(f)
    vlim = [1 100000];
    return
end
vlim = [min(f)*0.9, max(f)*1.1];
if vlim(1) >= vlim(2)
    vlim = [vlim(1)*0.5, vlim(1)*2];
end
end
