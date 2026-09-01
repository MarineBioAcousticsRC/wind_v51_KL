% Average Wind Regression data
%JAH 12-2019
% get Regress file names
clear all
[fn_files, fn_pathname] = uigetfile( ...
    {'*.mat'},'Pick Regress files',...
    'MultiSelect','on');
% sort if multiple files selecte
fn_files = sort(fn_files);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(fn_files) % then it's a cell full of filenames
    fn = cell(length(fn_files),1);
    for k = 1:length(fn_files)
        fn{k} = fullfile(fn_pathname, fn_files{k});
        %         disp(fn{k});
    end
else % it's just one file, but put into cell
    fn = cell(1,1);
    fn{1} = fullfile(fn_pathname,fn_files);
    %     disp(fn);
end
nfiles = length(fn);
Slope = zeros(nfiles,10);
d = zeros(1,nfiles);
disp(['Calculating Averages for: ',num2str(nfiles),' files']);
for k = 1:nfiles    % loop over files
    load(fn{k});
    d(k) = depth;
    Slope(k,:) = SlopeTS;
end
% make plot with depth
[i200] = find(d < 200);
[i400] = find(d >= 200 & d < 400 );
[i600] = find(d >= 400 & d < 600 );
[i800] = find(d >= 600 & d < 800 );
[i1000] = find(d >= 800 & d < 1000 );
[i1200] = find(d >= 1000 & d < 1200 );
[i1400] = find(d >= 1200  );
m(1,:) = mean(Slope(i200,:));
m(2,:) = mean(Slope(i400,:));
m(3,:) = mean(Slope(i600,:));
m(4,:) = mean(Slope(i800,:));
m(5,:) = mean(Slope(i1000,:));
m(6,:) = mean(Slope(i1200,:));
m(7,:) = mean(Slope(i1400,:));
DFig = figure;
for i = 1:7
    semilogx(fr,m(i,:))
    hold on
    grid on
end
legend('show','Location','northwest')
legend('200','400','600','800','1000','1200','1400')
% ax = gca;
% ax.XLim = ([50 40000]);
% ax.YLim = ([-10 10]);
