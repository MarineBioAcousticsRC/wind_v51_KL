% Compare Wind to LSTA
% JAH 10/2019
% derived from LTSAdailySpectra.m
% 141103 smw
%
clear variables
global PARAMS
Proj = 'GofAK';
Site = 'PT';
Short = '01';
Depl = '01';
% Area Harp data summary:
harpDataSummaryCSV = 'H:\Wind_TF\Code\HARPdataSummary.csv';
harpDataSummary = readtable(harpDataSummaryCSV);
WindFolder = ['H:\Wind_Data\',Proj,'\'];
LTSAFolder = ['G:\LTSA\',Proj,'\',Site];
TFsFolder = 'H:\Harp_TF\';
TFsFolderOld = 'H:\Harp_TF\OLD\';
OutFolder = 'H:\Wind_TF\Output';
% initial changable parameters:
% rm_fifo = 0;    % remove FIFO via interpolation on spectra. 0=no, 1=yes
% fsflag = 1;     % sample rate flag for FIFO removal 1=80kHz, 0=all other
NA = 5;     % number of time slices (spectral averages) to read per raw file
tres = 2;   % time bin resolution 0 = month, 1 = days, 2 = hours

% get LTSA file names and tf file name
[fn_files, fn_pathname] = uigetfile( ...
    {'*.LTSA';'*.ltsa'},'Pick LTSA(s)',...
    'MultiSelect','on');

% sort if multiple files selecte
fn_files = sort(fn_files);

% from LTSA name, determine deployment and PreAmp number and Time Period
deplMatch = [];
iFile = 1;
if iscell(fn_files)
    fnFileForTF = fn_files{1};
else
    fnFileForTF = fn_files;
end
while isempty(deplMatch) && iFile<=size(harpDataSummary,1)
    dBaseName = strrep(harpDataSummary.Data_ID{iFile},'-','');
    dBaseName = strrep(dBaseName,'_','');
    if (strfind(lower(dBaseName),lower([Proj,Site,Depl])))
        deplMatch = 1;
    elseif (strfind(lower(dBaseName),lower([Proj,Depl,Site])))
        deplMatch = 1;
    elseif (strfind(lower(dBaseName),lower([Proj,Site,Short,Depl])))
        deplMatch = 1;
    end
    iFile = iFile+1;
end
if isempty(deplMatch)
    error('Error, no matching deployment in HARP database)')
else
    deplMatchIdx = iFile-1;
end
depth = str2double(harpDataSummary.Depth_m{deplMatchIdx});
if (isnan(depth))
    prompt = ' Please Enter Depth in m: ';
    depth = input(prompt);
end
%Find the TF
tfNum = harpDataSummary.PreAmp{deplMatchIdx};
tfn = str2double(tfNum);
if isnan(tfn)
     prompt = ' Please Enter PreAmp Number: ';
    tfNum = input(prompt,'s');
    tfn = str2double(tfNum);
end
tfd = floor(tfn/100)*100;
%Try new versions
TFsFold = [TFsFolder,num2str(tfd),'_series'];
% Search TFs folder for the appropriate preamp
tfList = dir(TFsFold);
tfMatch = [];
iTF = 1;
while isempty(tfMatch) && iTF<=size(tfList,1)
    tfMatch = strfind(tfList(iTF).name,tfNum);
    iTF = iTF+1;
end
if ~isempty(tfMatch)
    tfMatchIdx = iTF-1;
    suggestedTFPath = fullfile(TFsFold,tfList(tfMatchIdx).name);
else
    %try Old TF versions
    warning('No matching New TF in TFs folder)')
    TFsFold = [TFsFolderOld,num2str(tfd),'_series'];
    % Search TFs folder for the appropriate preamp
    tfList = dir(TFsFold);
    tfMatch = [];
    iTF = 1;
    while isempty(tfMatch) && iTF<=size(tfList,1)
        tfMatch = strfind(tfList(iTF).name,tfNum);
        iTF = iTF+1;
    end
    if ~isempty(tfMatch)
    tfMatchIdx = iTF-1;
    suggestedTFPath = fullfile(TFsFold,tfList(tfMatchIdx).name);
    end
end
[tf_file, tf_pathname ] = uigetfile(fullfile(suggestedTFPath,'*.tf'),'Pick Transfer Function');
% outpath = uigetdir(,'Choose Output Directory');
outname = inputdlg('Enter Output Filename','Enter Output Filename',1,...
    {[dBaseName '_WindNoise.mat']});
outfile = fullfile(OutFolder,char(outname));

tic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp([ 'Transfer function: ' tf_file  ]);
tf = fullfile(tf_pathname, tf_file);
loadTF(tf); % open and read Transfer function file:

disp('Calculating Averages for:')
if iscell(fn_files) % then it's a cell full of filenames
    fn = cell(length(fn_files),1);
    for k = 1:length(fn_files)
        fn{k} = fullfile(fn_pathname, fn_files{k});
        disp(fn{k});
    end
else % it's just one file, but put into cell
    fn = cell(1,1);
    fn{1} = fullfile(fn_pathname,fn_files);
    disp(fn);
end
nltsas = length(fn);    % number of LTSA files
mnum2secs = 24*60*60;

% read ltsa headers and sum the total number of raw files for
% pre-allocating vectors/matrices
nrftot = 0;
for k = 1:nltsas    % loop over files
    PARAMS.ltsa = [];   % clear
    PARAMS.ltsa.ftype = 1;
    [PARAMS.ltsa.inpath,infile,ext] = fileparts(fn{k});
    PARAMS.ltsa.infile = [infile,ext];
    read_ltsahead  % better would be to just read nrftot instead of whole header
    nrf = PARAMS.ltsa.nrftot;
    nrftot = nrftot + nrf;
    if k == 1 % read and set some useful parameters that should be the same across all ltsas
        nf = PARAMS.ltsa.nf;
        nave = PARAMS.ltsa.nave(1);
        freq = PARAMS.ltsa.freq;
        dfreq = PARAMS.ltsa.dfreq;
    end
end

% correct TF for more than one measurement at a specific frequency
[C,ia,ic] = unique(PARAMS.tf.freq);
if length(ia) ~= length(ic)
    disp(['Error: TF file ',tf,' is not monotonically increasing'])
end
tf_freq = PARAMS.tf.freq(ia);
tf_uppc = PARAMS.tf.uppc(ia);
% Transfer function correction vector
Ptf = interp1(tf_freq,tf_uppc,freq,'linear','extrap');
Ptf2 = Ptf'*ones(1,3);  % to add to

% fill up header matrix H
PARAMS.ltsa = [];   % clear
H = zeros(nrftot,3);    % 3 columns: filenumber, datenumber, byteloc in filenumber
cnt1 = 1;
cnt2 = 0;
doff = datenum([2000 0 0 0 0 0]);   % convert ltsa time to millenium time
eltsa = [];
for k = 1:nltsas    % loop over files
    PARAMS.ltsa.ftype = 1;
    [PARAMS.ltsa.inpath,infile,ext] = fileparts(fn{k});
    PARAMS.ltsa.infile = [infile,ext];
    read_ltsahead  % better would be to just read nrftot instead of whole header
    nrf = PARAMS.ltsa.nrftot;
    fs0 = PARAMS.ltsa.fs;
    knave = PARAMS.ltsa.nave;
    cnt2 = cnt2 + nrf;
    H(cnt1:cnt2,1) = k.*ones(nrf,1);
    H(cnt1:cnt2,2) = PARAMS.ltsa.dnumStart + doff;  % add doff JAH to make real datenum
    H(cnt1:cnt2,3) = PARAMS.ltsa.byteloc;
    cnt1 = cnt2 + 1;
    eltsa(k) = cnt2;
end

dvec = datevec(H(:,2));

if tres == 0
    mnum = dvec(:,1).*12 + dvec(:,2);   % month number where 1 = Jan 2000
elseif tres == 1
    mnum = floor(datenum(dvec));   % day number where 1 = Jan 2000
elseif tres == 2
    mnum = floor(datenum(dvec) * 24);   % hour
else
    disp(['Error: unknown time resolution = ',num2str(tres)])
end

mnumMin = min(mnum);
mnumMax = max(mnum);
%
dur = unique(mnum);   % unique averaging time bins
nm = length(dur); % number of ave time bins
cnt1 = 1;
cnt2 = 0;
ptime = zeros(nm,1);      % start time of bin average
nmave = zeros(nm,2);    % number of averages possible and used(ie not filtered out) for each bin
mpwr = ones(nf,nm);     % mean power over time period
mpwrtf = ones(nf,nm);   % mean power with TF applied
% mpwrTF = ones(nf,nm);   % mean power with FIFO interp & TF applied
eltsam = 1; Cltsa = 0;
for m = 1:nm    % loop over time average bins
    I = [];
    I = find(mnum == dur(m));
    nrfM = length(I);
    pwrM = [];
    pwrM = zeros(nf,NA*nrfM);
    fnum = [];
    fnum = unique(H(I,1));
    nfiles = length(fnum);
    
    NBO = 0;    % number of averages (taves) read for mean spectra
    for f = 1:nfiles    % loop over files with same month (probably only 2 max)
        % open ltsa file
        fid = fopen(fn{fnum(f)},'r');
        % samples to skip over in ltsa file
        J = [];
        J = find(H(I,1) == fnum(f));
        nrfRead = length(J);
        skip = H(I(J(1)),3);    % get first byteloc of file for that month
        fseek(fid,skip,-1);    % skip over header + other data
        
        ptime(m) = H(I(J(1)),2);     % save 1st time of this time unit
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % number of time slices to use for calcs need to set 'xxxx*int8' value
        prcsn = [num2str(NA*nf),'*int8'];
        
        % allocate memory
        pwrF = [];
        NB = NA * nrfRead;
        pwrF = zeros(nf,NB);
        
        % number of time slices to skip on each read
        SA = nave - NA;
        skip = nf*(SA);
        % initial time slice to start at
        if fs0 == 2000 || fs0 == 200000 || fs0 == 10000
            %  IA = (15+5)*nf;
            IA = (nave + NA)*nf;  % better than commented 200kHz hardwired above
        elseif fs0 == 3200 || fs0 == 320000
            IA = (nave + NA-1)*nf;
        else
            disp('Error: unknown sample rate')
            disp(['fs0 = ',num2str(fs0)])
        end
        fseek(fid,IA,-0);
        
        % read data into File power
        [pwrF,count] = fread(fid,[nf,NB],prcsn,skip);
        if count ~= nf*NB
            disp('error = did not read enough data')
            %             NBO = NB;
            NB = floor(count/nf);
            %             disp(['NBO = ',num2str(NBO)])
            disp(['NB = ',num2str(NB)])
        end
        
        % fill up power
        if nfiles == 1
            pwrM = pwrF;
            NBO = NB;
        else
            if f == 1
                pwrM(1:nf,1:NB) = pwrF;
                NBO = NB;
            else
                pwrM(1:nf,NBO+1:NBO+NB) = pwrF;
                NBO = NBO+NB;
            end
        end
        %disp(['Number of 5s time bins in this Average Time Bin = ',num2str(NBO)]);
        fclose(fid);
        [Cltsa, ialtsa, ibltsa] =  intersect(I,eltsa);
        if Cltsa > 0
            disp([num2str(m),' end of ltsa ',fn{fnum(f)}]);
            eltsam = [eltsam; m];
            Cltsa = 0;
        end
    end  % end for f
    
    nmave(m,1) = NBO;
    %     nmave(m,2) = NBF;
    
    %     cnt2 = cnt2 + size(pwrN,2);
    cnt2 = cnt2 + size(pwrM,2);
    %     pwrA(1:nf,cnt1:cnt2) = pwrM;
    cnt1 = cnt2 + 1;
    
    % mean - these are smooth (floating point pwr values)
    %     mpwr(1:nf,m) = mean(pwrN,2);
    mpwr(1:nf,m) = mean(pwrM,2);
    mpwrtf(1:nf,m) = mpwr(1:nf,m) + Ptf';   % add transfer function
    
end
%REMOVE TIMES outside of 2006 - 2019
d2006 = datenum([2006 0 0 0 0 0]); 
d2019 = datenum([2019 0 0 0 0 0]); 
gotime = find(ptime < d2019 & ptime > d2006);
ptime = ptime(gotime);
mpwr = mpwr(:,gotime);
mpwrtf = mpwrtf(:,gotime);
%
% if fs0 == 3200  % only save up to 1000 Hz to be comparable to fs0 = 2000
%     nnf = 1001;
%     mpwr = mpwr(1:nnf,:);
%     mpwrTF = mpwrTF(1:nnf,:);
%     freq = freq(1:nnf);
% end
% Get Wind data
syr(1,:) = datevec(ptime(1));
syr(2,:) = datevec(ptime(end));
%
vec = []; speed = [];
for i = syr(1,1) : syr(2,1)
    if exist([WindFolder,num2str(i),'\',Proj,Site,'windvec.mat']);
        load([WindFolder,num2str(i),'\',Proj,Site,'windvec.mat'],'dnvec','wspeed');
    elseif exist([WindFolder,num2str(i),'\',Site,'windvec.mat']);
        load([WindFolder,num2str(i),'\',Site,'windvec.mat'],'dnvec','wspeed');
    elseif exist([WindFolder,num2str(i),'\',Proj,Short,'windvec.mat']);
        load([WindFolder,num2str(i),'\',Proj,Short,'windvec.mat'],'dnvec','wspeed');
    elseif exist([WindFolder,num2str(i),'\',Site,Short,'windvec.mat']);
        load([WindFolder,num2str(i),'\',Site,Short,'windvec.mat'],'dnvec','wspeed');
    else
        disp(['No Wind File'])
        return
    end
    vec = [vec;dnvec];
    speed = [speed;wspeed];
end
% re-interpolate for hourly from every 6 hr
dnew = []; wsnew = [];
for i = 1 : length(vec)
    dnew((i-1)*6 +1) = vec(i);
    wsnew((i-1)*6 +1) = speed(i);
    if i < length(vec)
        for k = 1 : 5
            dnew((i-1)*6 +1 + k) = (k/6)  * vec(i+1) + ...
                ((6-k)/6) * vec(i);
            wsnew((i-1)*6 +1 + k) = (k/6)  * speed(i+1) + ...
                ((6-k)/6) * speed(i);
        end
    end
end
% save results for noise and wind
save(outfile) % save all workspace
%         save(outfile,'ptime','mpwr','mpwrtf','freq','nmave','tf_file',...
%         'dBaseName','tf','wsnew','dnew')
eltsam = unique(eltsam);
%Identify times with Bite Swapped Data
if tfn > 499  && fs0 > 100000 % skip for old TF or decimated data
    inbs = find(((mpwr(300,:) - mpwr(600,:))) < 5 );  %JAH to remove Bswap data
    ibs = setxor([1:length(mpwr)],inbs);
    ibscount = 0; anygood = 0;
    for i = 1:fnum
        ibscount = find(ibs > eltsam(i) & ibs < eltsam(i+1));
        if (length(ibscount) > .5 * ( eltsam(i+1) - eltsam(i)))
            disp([fn_files{i},' WARNING BYTE SWAPPED DATA REMOVED']);
        else
            anygood = 1;
        end
        ibscount = 0;
    end
    if anygood == 0
        disp([dBaseName,'   WARNING ALL DATA BYTE SWAPPED']);
        return
    end
    %Remove outlier / low noise data
    ptime = ptime(inbs);
    mpwr = mpwr(:,inbs);
    mpwrtf = mpwrtf(:,inbs);
end
% %JAH HACK to remove bad data
if fs0 == 200000
    isok = find( mpwrtf(101,:) > 30 & mpwrtf(101,:) < 65); %10kHz = 100 * 100
elseif fs0 == 10000
    isok = find( mpwrtf(11,:) > 40 & mpwrtf(11,:) < 90); %100 Hz = 10 * 10
else
    disp('Add New Sample Rate')
    return
end
ptime = ptime(isok);
mpwr = mpwr(:,isok);
mpwrtf = mpwrtf(:,isok);
% reduce sig figures to make times match
xp = round(ptime .* 100)./100;
xw = round(dnew' .* 100)./100;
[~,inoise,iwind] = intersect(xp,xw);
Wfig = figure; % Wind versus Noise plot
if fs0 == 200000
    plot(wsnew(iwind),mpwrtf(11,inoise),'o') %use 1 kHz noise
    hold on
    plot(wsnew(iwind),mpwrtf(101,inoise),'ro') %use 10 kH
    legend('1 kHz','10 kHz','Location','southeast');
elseif fs0 == 10000
    plot(wsnew(iwind),mpwrtf(11,inoise),'o') %use 100 Hz noise
    hold on
    plot(wsnew(iwind),mpwrtf(51,inoise),'ro') %use 500 Hz
    legend('100 Hz','500 Hz','Location','southeast');
end
xlabel('Wind Speed m/s');
ylabel('Pressure Spectrum Level [dB re uPa^2/Hz]');
title([dBaseName,'Noise vs Wind Speed']);
%save wind vs noise figure
wnfigname = fullfile(WindFolder,'WindvsNoise',[dBaseName,'WindNoise']);
savefig(Wfig,wnfigname)
% REgress
[SlopeLR,OffSetLR,SlopeTS,OffSetTS] = WNRegress(...
    Proj,Site,Depl,depth,wsnew,mpwrtf,ptime,dnew,fs0);
%sort into speed bins
force1 = find(wsnew(iwind) > 0.3 & wsnew(iwind) <= 1.6);
MPTF{1} = mpwrtf(:,inoise(force1));
force2 = find(wsnew(iwind) > 1.6 & wsnew(iwind) <= 3.4);
MPTF{2} = mpwrtf(:,inoise(force2));
force3 = find(wsnew(iwind) > 3.4 & wsnew(iwind) <= 5.5);
MPTF{3} = mpwrtf(:,inoise(force3));
force4 = find(wsnew(iwind) > 5.5 & wsnew(iwind) <= 8.0);
MPTF{4} = mpwrtf(:,inoise(force4));
force5 = find(wsnew(iwind) > 8.0 & wsnew(iwind) <= 10.8);
MPTF{5} = mpwrtf(:,inoise(force5));
force6 = find(wsnew(iwind) > 10.8 & wsnew(iwind) <= 13.9);
MPTF{6} = mpwrtf(:,inoise(force6));
force7 = find(wsnew(iwind) > 13.9 & wsnew(iwind) <= 17.2);
MPTF{7} = mpwrtf(:,inoise(force7));
force8 = find(wsnew(iwind) > 17.2 & wsnew(iwind) <= 20.8);
MPTF{8} = mpwrtf(:,inoise(force8));
force9 = find(wsnew(iwind) > 20.8 & wsnew(iwind) <= 24.5);
MPTF{9} = mpwrtf(:,inoise(force9));
force10 = find(wsnew(iwind) > 24.5 & wsnew(iwind) <= 28.5);
MPTF{10} = mpwrtf(:,inoise(force10));
force11 = find(wsnew(iwind) > 28.5 & wsnew(iwind) <= 32.7);
MPTF{11} = mpwrtf(:,inoise(force11));
force12 = find(wsnew(iwind) > 32.7 );
MPTF{12} = mpwrtf(:,inoise(force12));
%
% theoreticalOceanNoise.m
% 080423 smw  from Don Ross Notes:
% + 56 dB re uPa^2 / Hz
% + 19*log10(ss) for 0.5 < seastate (ss) < 6
% - 17*log10(f) for 0.5 kHz < freqeuncy (f) < 25 kHz (ie Knudsen)
ss = [0.5,1:1:6]; % same as force 1 - 7
lenss = length(ss);
f = .1 : .1 : 100;
lenf = length(f);
a = 56.*ones(lenss,lenf);
b = (19*log10(ss))'*ones(1,lenf);
c = ones(lenss,1) * (-17*log10(f));
% Pressure Spectrum Level (power)
p = a + b + c;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% depth dependance correction to Knudsen spectra
% numerically solve eqn (3)->(4) from Kurahshi and Gratta 2007
% or similarly eqn (10)->(12) Short 2005 IEEE
% depth of hydrophone:
h = depth;   % [meters
% start,end step angle [rad]
ti = 0;
to = pi/2;
dt = to/90;
% alpha -> sound absorbtion coefficient
alpha = 0.036 * f.^(3/2);    % [dB/km] f => [kHz]
% alpha * h
alphah = alpha * h/1000;
% e^-ah
eah = 10.^(-alphah/10);
% loop over angle (theta)
Joah = 0;
Joo= 0;
for t = ti:dt:to
    ct = cos(t);
    sct = sec(t);
    st = sin(t);
    po = ct * st;
    pc = po * eah.^sct;
    Joah = Joah + pc;
    Joo = Joo + po;
end
% depth dependance correction to Knudsen spectra
ddc = 10 .* log10(Joah ./ Joo);
kd = p + ones(lenss,1)*ddc; % theoretical noise level with ss
% ss = 1 is force = 2 etc
% Theory is f starts with 100
% Data is freq starts with 0
for  i = 3 : lenss    % start at i = 3 ss2 because noise level
    if ~isempty(MPTF{i})
        figure
        semilogx(freq(2:201),MPTF{i}(2:201,:)); % from 100 Hz to 100 kHz
        hold on
        smptf = size((MPTF{i}(2:201,:)'));
        if smptf(1) > 1
            AM = mean(MPTF{i}(2:201,:)');
        elseif smptf(1) == 1
            AM = MPTF{i}(2:201,:)';
        end
        semilogx(freq(2:201),AM,'r','LineWidth',3); % from 100 Hz to 100 kHz
        semilogx(f(1:200).*1000,kd(i,1:200),'k','LineWidth',3); % theory as a line
        hold off
        xlabel('Frequency [Hz]')
        ylabel('Pressure Spectrum Level [dB re uPa^2/Hz]')
        grid on
        title(['Sea State' ,num2str(ss(i))]);
        %     v = [1e3 2e4 20 80];
        v = [100 2e4 25 90];
        axis(v)
%         figure
        TFCorr(i,:) = kd(i,1:200) - AM; % first value is 100 Hz
%         semilogx(freq(2:201),TFCorr(i,:))
%         v = [100 2e4 -5 5];
%         axis(v)
%         hold on
    end
end
MTFCorr = mean(TFCorr); %starts with freq = 100 Hz
nMT = isnan(MTFCorr); % correct Nan
inMT = find(nMT > 0);
if (~isempty(inMT))
    for i = 1 : length(inMT)
        MTFCorr(inMT(i))=(MTFCorr(inMT(i)-1)+MTFCorr(inMT(i)+1))/2 ;
    end
end
figure
semilogx(freq(2:201),MTFCorr,'r','LineWidth',3); %
v = [100 2e4 -5 5];
axis(v)
grid on
hold on
% Make New TF
% MAKE TF CORRECTION > 1 kHz < 10 kHz
% note freq = (count -1)*100 Hz
iPtf = find(PARAMS.tf.freq > 0 & PARAMS.tf.freq < 100); % part below 100Hz
miP = max(iPtf);
TFnew = [PARAMS.tf.freq(iPtf)',PARAMS.tf.uppc(iPtf)'];% adds < 100 Hz data
TFnew(miP+1:miP+1000,:) = [freq(2:1001)',Ptf(2:1001)']; % begin at 100 Hz
TFold = TFnew;
TFnew(miP+1:miP+9,2) = TFnew(miP+1:miP+9,2) + MTFCorr(10); % for 100 Hz - 900 Hz
TFnew(miP+10:miP+100,2) = TFnew(miP+10:miP+100,2) + MTFCorr(10:100)'; % for 1 kHz - 10 kHz
TFnew(miP+101:end,2) = TFnew(miP+101:end,2) + MTFCorr(100); % for > 10 kHz
%Make TF Figure
TFFig = figure;
semilogx(TFnew(:,1),TFnew(:,2),'r','LineWidth',3); %
hold on
semilogx(TFold(:,1),TFold(:,2),'k','LineWidth',3); %
legend('NewTF','OldTF');
title([dBaseName,' Hydrophone ',tf_file(1:3)])
xlabel('Frequency [Hz]')
ylabel('Inverse Sensitivity [dB re uPa//counts]')
grid on
% save in inverse sensitivity tf format in original TF Folder
tfnewfile = fullfile(tf_pathname,...
    [tf_file(1:3),'_',Proj,Site,Depl,'_TFnew.tf']);
save(tfnewfile,'TFnew','-ascii','-tabs');
tfnewfig = fullfile(tf_pathname,...
     [tf_file(1:3),'_',Proj,Site,Depl,'_TFnewfig']);
savefig(TFFig,tfnewfig)
tfnewfigpdf = fullfile(tf_pathname,...
    [tf_file(1:3),'_',Proj,Site,Depl,'_TFnewfig.pdf']);
saveas(TFFig,tfnewfigpdf)
% Another copy in TF_Wind Folder
tfnewfile = fullfile(TFsFolder,'TF_Wind',...
    [tf_file(1:3),'_',Proj,Site,Depl,'_TFnew.tf']);
save(tfnewfile,'TFnew','-ascii','-tabs');
tfnewfig = fullfile(TFsFolder,'TF_Wind',...
    [tf_file(1:3),'_',Proj,Site,Depl,'_TFnewfig']);
savefig(TFFig,tfnewfig)
tfnewfigpdf = fullfile(TFsFolder,'TF_Wind',...
    [tf_file(1:3),'_',Proj,Site,Depl,'_TFnewfig.pdf']);
saveas(TFFig,tfnewfigpdf)
% end
t = toc;
disp(' ')
disp(['Time Elapsed: Spectra from LTSA ', num2str(t),' secs'])
 