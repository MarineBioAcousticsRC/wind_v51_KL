% WindTimeSeries_Comparison_211005.m
% KLL 211005 - to compare CCMP and NCEP models
% KLL 211015 - adjusted to compare any models available for a site and year
% of interest. Only need to change the input params in the first couple of
% lines to run! 
close all
clear 

% input params: 

loc = ''; % location of interest
site = 'WT'; % site of interest
year = '2007'; % year of interest
pflag = 1; % save plots yes or no
ipath = 'C:\Users\13035\Desktop\Wind\Wind_Results\Comparison_Plots'; % where to save plots
pn = 'C:\Users\13035\Desktop\Wind\Wind_Results'; % where to find mat files
oneAtaT = 0; % look at data day by day

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
all_mat = dir(fullfile(pn,'**','*.mat'));
fnd = char(all_mat.name);
fld_fnd = char(all_mat.folder);
fld_fnd = strtrim(fld_fnd);
sz = size(fnd); szz = sz(1);
for k = 1:szz
    ff = strtrim(fld_fnd(k,:));
    full{k} = [ff,'\',fnd(k,:)];
end
all_o = transpose(full);
all_one = all_o(contains(all_o,year));
if isempty(all_one)
    clc
    disp(['No wind data at ',site,' available from the year ',year,'. Try a different year or run WindTimeSeries.m for ',site,' ', year])
    return
end
all_two = all_one(contains(all_one,loc));
if isempty(all_two)
    clc
    disp(['No wind data containing ',loc,' available from the year ',year,'. Try a different year, run WindTimeSeries.m for ',site,' ', year,', or set loc to blank in input params'])
    return
end
paths = all_two(contains(all_two,site));
paths = strtrim(paths);
if isempty(paths)
    clc
    disp(['No wind data available from the site ',site,'. Try a different site or run WindTimeSeries.m for ',site,' ', year])
    return
end
% get size so that mats can be sized and interpolated correctly:
for k = 1:length(paths)
    mat = load(paths{k});
    l(:,k) = length(mat.wspeed);
    dn(:,k) = length(mat.dnvec);
end

[M,I] = max(l);
[Md,Id] = max(dn);
%need to load max
max_mat = load(paths{Id});
max_date = max_mat.dnvec;

for k = 1:length(paths)
    mat = load(paths{k});
    if length(mat.wspeed) ~= max(l) %if a length is greater 1460, match to that length
        a = mat.dnvec; % dnvec can't have repeating zeros for the interpolation
        b = mat.wspeed;
        mat.wspeed = interp1(mat.dnvec,mat.wspeed,max_date);
        mat.dnvec = interp1(mat.dnvec,mat.dnvec,max_date);
    end
    wspeed(:,k) = mat.wspeed; %#ok<*SAGROW> 
    date(:,k) = mat.dnvec;
    level = wildcardPattern + "\";
    pat = asManyOfPattern(level);
%     name(k,:) = paths{k}(end-16:end-4);
    name(k,:) = extractAfter(paths{k}(1:end-4),pat);
end

m_wspeed = mean(wspeed,2,'omitnan');

for k = 1:length(paths)
    d(:,k) = wspeed(:,k)-m_wspeed;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plots
figure(100) 
clf
plot(date,wspeed)
hold on
grid on
hold off
datetick('x','mmm')
title([loc,' ',site,' Wind Speed Comparison ',year]);
ylabel('Wind Speed (m/s)');
xlabel(' Month ');
legend(name)
% xlim([date(1,1) date(3000,2)])
if pflag
    opfile = fullfile(ipath,[site,year,'_wspeed.png']);
    print('-f100','-dpng','-r300', opfile)
end

% difference plot
figure(101) 
clf
plot(date, d)
hold on
grid on
datetick('x','mmm')
title([loc,' ',site,' Wind Speed Comparison Difference from the Mean ',year]);
ylabel('Wind Speed Difference (m/s)');
xlabel(' Month ');
ylim([-5 5])
legend(name)
% xlim([date(1,1) date(3000,2)])

if pflag
    opfile = fullfile(ipath,[site,year,'_difference.png']);
    print('-f101','-dpng','-r300', opfile)
end

% histogram of difference
figure(102)
for k = 1:length(paths)
    subplot(length(paths),1,k)
    H = histogram(d(:,k),25);
    xlim([-5 5])
    ylim([0 1500])
    legend(name(k,:))
end
han=axes(figure(102),'visible','off'); 
han.Title.Visible='on'; han.XLabel.Visible='on'; han.YLabel.Visible='on';
ylabel(han,'Number of Hours');
xlabel(han,'Difference (m/s)');
title(han,['Histogram of Difference from Mean for ',loc,' ',site,' ',year]);

if pflag
    opfile = fullfile(ipath,[site,year,'_histogram_diff.png']);
    print('-f102','-dpng','-r300', opfile)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% oneAtaTime plot
if oneAtaT == 1
    LW = 3;
    FS = 14;
    fac = 1;
    pause on
    disp('For Figure 505:')
    disp('Press ''b'' key to go backwards')
    disp('Press any other key to go forwards')
    k = 1;
    % loop over the days
    while (k <= date(2,end))
        figure(505);
        subplot(2,1,1);
        plot(date,wspeed)
        grid on
        datetick('x','mmm')
        title([site,' Wind Speed Comparison ',year]);
        ylabel('Wind Speed (m/s)');
        xlabel(' Month ');
        set(gca,'FontSize',FS)
        xlim([date(k,2) date(k+60,2)])
        
        subplot(2,1,2);
        plot(date, d)
        hold on
        xline(0,'k')
        hold off
        grid on
        grid minor
        datetick('x','mmm')
        title([site,' Difference from the Mean ',year]);
        ylabel('Speed Difference (m/s)');
        xlabel(' Month ');
        ylim([-5 5])
        xlim([date(k,2) date(k+60,2)])
        legend(name)
        set(gca,'FontSize',FS)
    
    
        % get key stroke and set k forward or backwards 1
        pause
        cc = get(505,'CurrentCharacter');
        if strcmp(cc,'b')
            if k ~= 1
                k = fac*(k-15);
            end
        else
            k = fac*(k+30);
        end
        
    end
    pause off
end