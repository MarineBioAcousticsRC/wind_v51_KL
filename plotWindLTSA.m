% plotDailyAvesSingleLSG_170715.m
%
% Single site long spectrogram use the same T and F vector.
% the power matrix for each site is pre-allocated, then filled for days
% when data exists
%
% 170707 smw
%
clear variables
OutFolder = 'H:\Wind_TF\Output';
ns = 1; % number of sites
spflag = 0; % save plot flag yes=1, no=0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% choose *WindNoise.mat files
% getfile names
[fn_files, fn_pathname] = uigetfile({'*.mat'},'Pick WindNoise(s)'),...
    'MultiSelect','on');
% sort if multiple files selected
fn_files = sort(fn_files);
nS = length(fn_files);    % number of *_DailyAves.mat files
% from  name, determine deployment and depth
for indexf = 1 : nS
    dBaseName = strrep(fn_files{indexf},'_WindNoise.mat','');
    load(fn_files{indexf})
    nch = 1;
    % set parameters based on sample rate
    if fs0 == 2000 || fs0 == 3200
        npF = 1001; % number of frequency bins
        Fp = 0:1:1000;
        la = 10;        % plot min freq
        lb = 1000;       % plot max freq
        % color min and max in spectral power
        cmn = 39;
        cmx = 110;
        cmin = 1; cmax = 110;   %[dB]
        fstr = 'Hz';
        ptype = 1;  % high freq linear =0, low freq log =1
    elseif fs0 == 200000
        npF = 1001; % number of frequency bins
        Fp = 0:0.1:100;
        la = 0;        % plot min freq
        lb = 100;       % plot max freq
        % color min and max in spectral power
        cmn = 30;
        cmx = 60;
        cmin = 1; cmax = 70;   %[dB]
        fstr = 'kHz';
        ptype = 0;  % high freq linear =0, low freq log =1
    elseif fs0 == 320000
        npF = 1601; % number of frequency bins
        Fp = 0:0.1:160;
        la = 0;        % plot min freq
        lb = 160;       % plot max freq
        % color min and max in spectral power
        cmn = 30;
        cmx = 60;
        cmin = 1; cmax = 70;   %[dB]
        fstr = 'kHz';
        ptype = 0;  % high freq linear =0, low freq log =1
    else
        disp(['Error, Unknown Sample Rate : ',num2str(fs0)])
        return
    end
    % begin and end date for this file
    ta = floor(ptime(1));
    tb = ceil(ptime(end));
    Tp = ta:1:tb;
    dD = ta ;
    nD = tb - ta + 1;
    FM = zeros(npF,nD);  % pre-allocate power matrix
    % put values in one matrix
    k = 1;
    T = ptime;
    P = mpwrtf;
    sname = dBaseName;
    deplStart{k} = T(1);
    Ti = T - dD;
    FM = P(1:npF,:);
JAHJAHJKAHJKAH Stopped here
% make xTick for months
d=datevec(Tp);
%takes every month just once
[a,idxm]=unique(d(:,1:2),'rows');
%takes every year just once
[a,idxy]=unique(d(:,1),'rows');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make figure
%%
h=figure; clf
set(h,'Units','normalized','Position',[.15,.2,.75,.7])
pp = [0.25 0.25 10.5 8.0];
set(h,'PaperPosition',pp)
FS = 24;
FS2 = FS;
%%%%%%%%%%%%%%%%%%%%
% plot spectrogram
h = surf(T,Fp,FM,'Linestyle','none');
sgAx = get(h,'Parent');
view(sgAx,0,90)
if ptype
    set(sgAx,'yscale','log')
else
    set(sgAx,'yscale','linear')
end
set(sgAx,'TickDir','out')
axis([ta tb la lb])
set(gca,'FontSize',FS)
set(gca,'XtickLabel',Tp(idxm))
% set(gca,'xtick',Tp(idxy))
set(gca,'xtick',Tp(idxm(2:end))) % select monthly ticks
datetick('keepticks')
% datetick

% do not put 1st year label unless first month is Jan
if d(1,2) ~= 1
    XtL = cellstr(get(gca,'XtickLabel'));
    if Tp(end)-Tp(1)<365
        XtL{1} = num2str(year(Tp(1)));
    else
        XtL{1} = blanks(1);
    end
    set(gca,'XtickLabel',XtL);
end
ax = get(gca);
% minor ticks
ax.XAxis.MinorTick = 'on';
ax.XAxis.MinorTickValues = Tp(idxm);
ap = get(gca,'Position');
set(gca,'Position',[ap(1) ap(2)+0.1 ap(3) ap(4)*.80])
ylabel(['Frequency [',fstr,']'],'FontSize',FS)

% plot frame/box
txtz = 200;
% dtl = datenum([0 0 1 0 0 0]);
dtl = datenum([0 0 0 1 0 0]);
dfa = -1e-10; dfb = 1e-10;
lx = [ta+dtl ta+dtl tb-2*dtl tb-2*dtl ta+dtl];
ly = [la+dfa lb-dfb lb-dfb la+dfa la+dfa];
lz = txtz.*ones(1,5);
hold on
plot3(lx,ly,lz,'-k','LineWidth',2)
hold off
caxis([cmn cmx]) % set color limits
colormap(jet)
% colorbar
cb = colorbar('Location','SouthOutside','FontSize',FS);%'Position',[0.12 0.125 0.8 0.0125]);
text(0.5,-.5 ,'Spectrum Level [dB re 1\muPa^2/Hz]',...
    'HorizontalAlignment','center','Units','normalized','FontSize',FS)
set(cb,'XLim',[cmn+1 cmx])

% add plus sign to last label on colorbar
if 1
    xtl = get(cb,'XTickLabel');
    xtl = [char(xtl) blanks(length(xtl))'];
    xtl(end,end) = '+';
    set(cb,'XTickLabel',xtl)
end

% use path as title - could be better...
warning('off')
hT = title(fn_files,'FontSize',FS2);
set(hT,'Position',get(hT,'Position')+[0,lb*.06,0])
%%
% Save plot to file
if spflag
    opath = fn_pathname;
    ofile = 'SingleLSG.jpg';
    print('-f700','-djpeg','-r600',fullfile(opath,ofile))
    ofile2 = 'SingleLSG.tif';
    print('-f700','-dtiff','-r600',fullfile(opath,ofile2))
end

