% CompareWind_NDBC_vs_CCMP.m
% KL 260819 - Compare wind SPEED between an NDBC-derived windvec .mat and a
%             CCMP-derived windvec .mat (e.g. SOCALTwindvec.mat).
%
% Both files are expected to contain (CCMP output convention):
%   dnvec  - MATLAB datenum time vector (UTC)
%   wspeed - wind speed in m/s
%   slat25, slon25 - site coordinates
%
% This script:
%   1) loads both files
%   2) inspects & reports each time base (sampling interval, span)
%   3) resamples the finer series onto the coarser common time grid
%   4) plots overlay + difference, and prints summary stats
%
% Comparison is on wind SPEED only (convention-independent).

clear; clc;

%% ========================== USER INPUT ============================= %%
ndbcFile = 'C:\Users\Kieran Lenssen\Documents\GitHub\KLcode\wind\WindTimeSeries_Results\SDT\NDBC\2022\SDTNDBCwindvec.mat';
ccmpFile = 'Z:\Wind_deltaTF\Wind_Data\SOCAL\2022\SOCALTwindvec.mat';  % <-- adjust path

labelNDBC = 'NDBC 46086';
labelCCMP = 'CCMP SOCALT';

maxGapHours = 12;   % don't interpolate across gaps longer than this (hours)
%% ======================== END USER INPUT ============================ %%

% --- Load both ---
A = load(ndbcFile);   % NDBC
B = load(ccmpFile);   % CCMP

assert(isfield(A,'dnvec') && isfield(A,'wspeed'), 'NDBC file missing dnvec/wspeed');
assert(isfield(B,'dnvec') && isfield(B,'wspeed'), 'CCMP file missing dnvec/wspeed');

% Ensure column vectors, sorted by time
[tA, iA] = sort(A.dnvec(:));  sA = A.wspeed(:);  sA = sA(iA);
[tB, iB] = sort(B.dnvec(:));  sB = B.wspeed(:);  sB = sB(iB);

% --- Inspect and report each time base ---
descA = describeTimeBase(tA, labelNDBC);
descB = describeTimeBase(tB, labelCCMP);

fprintf('\n--- Time base summary ---\n');
fprintf('%s\n', descA.text);
fprintf('%s\n', descB.text);

% --- Choose common grid: the COARSER of the two ---
if descA.medDtMin >= descB.medDtMin
    tGrid = tA;   coarserLabel = labelNDBC;
    % Interp the finer (B) onto A's grid
    sGridRef = sA;                       % reference stays native
    sGridOther = resampleOnto(tB, sB, tGrid, maxGapHours);
    refLabel = labelNDBC;  otherLabel = labelCCMP;
else
    tGrid = tB;   coarserLabel = labelCCMP;
    sGridRef = sB;
    sGridOther = resampleOnto(tA, sA, tGrid, maxGapHours);
    refLabel = labelCCMP;  otherLabel = labelNDBC;
end
fprintf('\nCommon grid = %s time base (%.0f min nominal, %d points)\n', ...
    coarserLabel, min(descA.medDtMin,descB.medDtMin)*0 + ...
    max(descA.medDtMin,descB.medDtMin), numel(tGrid));

% --- Valid pairs (both finite) ---
pair = isfinite(sGridRef) & isfinite(sGridOther);
x = sGridRef(pair);      % reference speed
y = sGridOther(pair);    % resampled other speed
tP = tGrid(pair);
d = y - x;               % difference (other - reference)

% --- Summary stats ---
fprintf('\n--- Wind speed comparison (%s vs %s) ---\n', otherLabel, refLabel);
fprintf('  N matched points : %d\n', numel(d));
fprintf('  Mean %s          : %.2f m/s\n', refLabel, mean(x));
fprintf('  Mean %s          : %.2f m/s\n', otherLabel, mean(y));
fprintf('  Mean diff (o-r)  : %.2f m/s\n', mean(d));
fprintf('  Std  diff        : %.2f m/s\n', std(d));
fprintf('  RMS  diff        : %.2f m/s\n', sqrt(mean(d.^2)));
fprintf('  Max |diff|       : %.2f m/s\n', max(abs(d)));
R = corrcoef(x, y);
fprintf('  Correlation r    : %.3f\n', R(1,2));
p = polyfit(x, y, 1);
fprintf('  Best-fit slope   : %.3f\n', p(1));
fprintf('  Best-fit intercept: %.3f m/s\n', p(2));

% ============================ PLOTS ============================ %
figure('Name','Wind speed comparison','Units','inches','Position',[0.5 0.5 10 8]);

% (1) Overlay time series
subplot(3,1,1); hold on
plot(tGrid, sGridRef,   '-', 'LineWidth', 1.0, 'DisplayName', refLabel);
plot(tGrid, sGridOther, '-', 'LineWidth', 1.0, 'DisplayName', otherLabel);
datetick('x','mmm'); grid on
ylabel('Wind speed (m/s)');
title('Wind speed time series');
legend('Location','best');

% (2) Difference time series
subplot(3,1,2); hold on
plot(tP, d, 'k-', 'LineWidth', 0.8);
yline(0,'--','Color',[.5 .5 .5]);
datetick('x','mmm'); grid on
ylabel(sprintf('\\Deltaspeed (m/s)\n%s - %s', otherLabel, refLabel));
title(sprintf('Difference (mean %.2f, RMS %.2f m/s)', mean(d), sqrt(mean(d.^2))));

% (3) Scatter with 1:1 and best-fit
subplot(3,1,3); hold on
plot(x, y, '.', 'MarkerSize', 4, 'Color', [0.2 0.4 0.8]);
lims = [0, max([x;y])*1.05];
plot(lims, lims, 'k--', 'DisplayName','1:1');
plot(lims, polyval(p, lims), 'r-', 'DisplayName', ...
    sprintf('fit: y=%.2fx+%.2f', p(1), p(2)));
axis equal; xlim(lims); ylim(lims); grid on
xlabel(sprintf('%s speed (m/s)', refLabel));
ylabel(sprintf('%s speed (m/s)', otherLabel));
title(sprintf('Scatter (r = %.3f)', R(1,2)));
legend('Location','southeast');

sgtitle(sprintf('Wind Speed: %s vs %s (2022)', otherLabel, refLabel), ...
    'FontWeight','bold');

disp('Done.');

% ======================= LOCAL FUNCTIONS ======================= %
function desc = describeTimeBase(t, label)
% Report sampling interval and span of a datenum vector
    dt = diff(t);
    medDtMin = median(dt) * 24 * 60;   % median interval in minutes
    spanDays = (t(end) - t(1));
    desc.medDtMin = medDtMin;
    desc.text = sprintf(['%-14s: %d pts | %s to %s | median dt = %.1f min ', ...
        '(%.2f hr) | span %.1f days'], ...
        label, numel(t), datestr(t(1),'yyyy-mm-dd'), datestr(t(end),'yyyy-mm-dd'), ...
        medDtMin, medDtMin/60, spanDays);
end

function sOut = resampleOnto(tSrc, sSrc, tGrid, maxGapHours)
% Interpolate sSrc(tSrc) onto tGrid, but leave NaN where the nearest source
% sample is farther than maxGapHours (avoids interpolating across data gaps).
    sOut = interp1(tSrc, sSrc, tGrid, 'linear', NaN);
    % Blank out points that fall inside large gaps
    for k = 1:numel(tGrid)
        [gap, ~] = min(abs(tSrc - tGrid(k)));
        if gap*24 > maxGapHours
            sOut(k) = NaN;
        end
    end
end