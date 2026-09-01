% Compare Wind to LSTA 
% JAH 10/2019
% derived from LTSAdailySpectra.m
% 141103 smw
%
clear variables  
global PARAMS

% Load Harp data summary:
harpDataSummaryCSV = 'D:\TF\Code\HARPdataSummary.csv';
harpDataSummary = readtable(harpDataSummaryCSV);

WindFolder = 'D:\Wind\GofAK\';
LTSAFolder = 'G:\LTSA\GofAK\GofAK_PT\';
TFsFolder = 'D:\Harp_TF\';
% initial changable parameters:
% rm_fifo = 0;    % remove FIFO via interpolation on spectra. 0=no, 1=yes
% fsflag = 1;     % sample rate flag for FIFO removal 1=80kHz, 0=all other
NA = 5;     % number of time slices (spectral averages) to read per raw file
tres = 2;   % time bin resolution 0 = month, 1 = days, 2 = hours
% strum filter parameters - different for different sites, deployment,
% hydrophone sensitivities, etc.
% % OCNMS:
% if 1
%     fbin = 5;   % 4Hz
%     sthr = 20; % strum filter threashold [dB re count^2/Hz] no TF applied
% end
% if 0
% % CE01test
%     fbin = 8;
%     sthr = 0;
% end
% % sthr = 100; % set sthr high for no strum filter

% get LTSA file names and tf file name
[fn_files, fn_pathname] = uigetfile({'*.LTSA';'*.ltsa'},'Pick LTSA(s)',...
    'MultiSelect','on');

% sort if multiple files selected
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
    deplMatch = strfind(lower(fnFileForTF),lower(dBaseName));
    iFile = iFile+1;
end
if isempty(deplMatch)
    error('Error, no matching deployment in HARP database)')
else
    deplMatchIdx = iFile-1;
end
%Find the TF
tfNum = harpDataSummary.PreAmp{deplMatchIdx};
tfn = str2double(tfNum);
tfd = floor(tfn/100)*100;
TFsFolder = [TFsFolder,num2str(tfd),'_series'];
% Search TFs folder for the appropriate preamp
tfList = dir(TFsFolder);
tfMatch = [];
iTF = 1;

while isempty(tfMatch) && iTF<=size(tfList,1)
    tfMatch = strfind(tfList(iTF).name,tfNum);
    iTF = iTF+1;
end
if isempty(tfMatch)
    warning('No matching TF in TFs folder)')
    suggestedTFPath = [];
else
    tfMatchIdx = iTF-1;
    suggestedTFPath = fullfile(TFsFolder,tfList(tfMatchIdx).name);
end

[tf_file, tf_pathname ] = uigetfile(fullfile(suggestedTFPath,'*.tf'),'Pick Transfer Function');
outpath = uigetdir(pwd,'Choose Output Directory');
outname = inputdlg('Enter Output Filename','Enter Output Filename',1,...
    {[dBaseName '_DailyAves.mat']});
outfile = fullfile(outpath,char(outname));

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

% % for removing 80kHz FIFO
% if max(knave) == 38
%     fsflag = 1;
% else
%     fsflag = 0;
% end

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
    if tres == 0
        disp(['Month = ',num2str(dur(m))])
    elseif tres == 1
        disp(['Day = ',num2str(dur(m))])
    elseif tres == 2
        disp(['Hour = ',num2str(dur(m))]);
    end
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
        % number of time slices to use for calcs
        % need to set 'xxxx*int8' value
        prcsn = [num2str(NA*nf),'*int8'];
        
        % allocate memory
        pwrF = [];
        NB = NA * nrfRead;
        pwrF = zeros(nf,NB);
        
        % number of time slices to skip on each read
        SA = nave - NA;
        skip = nf*(SA);
        % initial time slice to start at
        if fs0 == 2000 || fs0 == 200000
            %         IA = (15+5)*nf;
            IA = (nave + NA)*nf;  % this should work better for 320kHz vs commented 200kHz hardwired above
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
        disp(['Number of 5s time bins in this Average Time Bin = ',num2str(NBO)]);
        fclose(fid);
        [Cltsa, ialtsa, ibltsa] =  intersect(I,eltsa);
        if Cltsa > 0 
            disp([num2str(m),' end of ltsa']);
            eltsam = [eltsam; m];
            Cltsa = 0;
        end
    end  % end for f
    
    %     % remove 5s time bins with strumming
    %     K = [];
    %     K = find(pwrM(fbin,:) < sthr);
    %     if ~isempty(K)
    %         pwrN = pwrM(:,K);
    %         NBF = size(pwrN,2);
    %         disp(['Number of 5s time bins after strumming filter = ',num2str(NBF)])
    %     else
    %         disp(['Error: no time bins with levels less than: ',num2str(sthr)])
    %         continue
    %     end
    
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
    
    % running average to remove FIFO spikes
    %     ws = 5; % window size: number of samples
    %     mfpwr(1:nf,m) = filter(ones(1,ws)/ws,1,mpwr(1:nf,m));
    %     mf(1:nf,m) = mfpwr(1:nf,m) + Ptf'; % add transfer function
    
    % standard deviation
    %     spwr(1:nf,m) = std(pwrM,1,2);
    %     sfpwr(1:nf,m) = filter(ones(1,ws)/ws,1,spwr(1:nf,m));
    %     sf1(1:nf,m) = mfpwr(1:nf,m) + sfpwr(1:nf,m) + Ptf';
    %     sf2(1:nf,m) = mfpwr(1:nf,m) - sfpwr(1:nf,m) + Ptf';
    
    %     % Remove FIFO via inperpolation on spectra
    %     if rm_fifo
    %         if fs0 == 2000
    %             if fsflag
    %                 fund = 20; % original fs=80kHz
    %             else
    %                 fund = 50;
    %             end
    %         elseif fs0 == 3200
    %             fund = 80;
    %         else
    %             fprintf('Unknown sample rate %d encountered during rmFIFO\nExiting!\n', ...
    %                 fs0);
    %         end
    %         nomult = 19;
    %         for mult = 1:nomult %going up to 1000 Hz
    %             ind2 = [];
    %             ind2 = find(abs(pwrN(mult*fund+1,:)-pwrN(mult*fund-1,:))>.8);
    %             if ~isempty(ind2)
    %                 %diference to add to each increment for interpolation
    %                 dff(ind2) = (pwrN(mult*fund+3,ind2)-pwrN(mult*fund-1,ind2))/4;
    %                 pwrN(mult*fund,ind2) = pwrN(mult*fund-1,ind2)+dff(ind2);
    %                 pwrN(mult*fund+1,ind2) = pwrN(mult*fund-1,ind2)+dff(ind2)*2;
    %                 pwrN(mult*fund+2,ind2) = pwrN(mult*fund-1,ind2)+dff(ind2)*3;
    %             end
    %         end
    %         % mean - these are smooth
    %         pwrN = bsxfun(@plus, pwrN, Ptf'); % add in transfer function!
    %         mpwrTF(1:nf,m) = mean(pwrN,2);
    %     end
end

% if fs0 == 3200  % only save up to 1000 Hz to be comparable to fs0 = 2000
%     nnf = 1001;
%     mpwr = mpwr(1:nnf,:);
%     mpwrTF = mpwrTF(1:nnf,:);
%     freq = freq(1:nnf);
% end

% save results
if 1
    save(outfile,'ptime','mpwr','mpwrtf','freq','nmave','tf_file','dBaseName','tf')
end
%Identify times with Bite Swapped Data
ibs = find(((mpwr(300,:) - mpwr(600,:))) > 5 );  %JAH to remove Bswap data  
ibscount = 0;
for i = 1:fnum
    ibscount = find(ibs > eltsam(i) & ibs < eltsam(i+1));
    if (length(ibscount) > 100)
        disp([fn_files{i},' WARNING BYTE SWAPPED DATA REMOVED']);
        ptime = setxor(ptime,ptime(eltsam(i):eltsam(i+1)));
        mpwr = setxor(mpwr,mpwr(eltsam(i):eltsam(i+1)));
        mpwrtf = setxor(mpwrtf,mpwrtf(eltsam(i):eltsam(i+1)));
    end
    ibscount = 0;
end
%Remove outlier / low noise data
isok = find( mpwr(10,:) > -15);  %JAH HACK to remove data
ptime = ptime(isok);
mpwr = mpwr(:,isok);
mpwrtf = mpwrtf(:,isok);
% Get Wind data
syr(1,:) = datevec(ptime(1));
syr(2,:) = datevec(ptime(end));
dName = strsplit(dBaseName,'_');
Proj = cell2mat(dName(1));
Site = cell2mat(dName(2));
Site = Site(1:2); % only 2 char site name
%
vec = []; speed = [];
for i = syr(1,1) : syr(2,1)
    load([WindFolder,num2str(i),'\',Proj,Site,'windvec.mat'],'dnvec','wspeed');
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
%
x = round(ptime .* 100)./100;
y = round(dnew' .* 100)./100;
[~,inoise,iwind] = intersect(x,y);
%sort into speed bins
force1 = find(wsnew(iwind) > 0.3 & wsnew(iwind) <= 1.6);
mpwr1 = mpwr(:,inoise(force1));
force2 = find(wsnew(iwind) > 1.6 & wsnew(iwind) <= 3.4);
mpwr2 = mpwr(:,inoise(force2));
force3 = find(wsnew(iwind) > 3.4 & wsnew(iwind) <= 5.5);
mpwr3 = mpwr(:,inoise(force3));
force4 = find(wsnew(iwind) > 5.5 & wsnew(iwind) <= 8.0);
mpwr4 = mpwr(:,inoise(force4));
force5 = find(wsnew(iwind) > 8.0 & wsnew(iwind) <= 10.8);
mpwr5 = mpwr(:,inoise(force5));
force6 = find(wsnew(iwind) > 10.8 & wsnew(iwind) <= 13.9);
mpwr6 = mpwr(:,inoise(force6));
force7 = find(wsnew(iwind) > 13.9 & wsnew(iwind) <= 17.2);
mpwr7 = mpwr(:,inoise(force7));
force8 = find(wsnew(iwind) > 17.2 & wsnew(iwind) <= 20.8);
mpwr8 = mpwr(:,inoise(force8));
force9 = find(wsnew(iwind) > 20.8 & wsnew(iwind) <= 24.5);
mpwr9 = mpwr(:,inoise(force9));
force10 = find(wsnew(iwind) > 24.5 & wsnew(iwind) <= 28.5);
mpwr10 = mpwr(:,inoise(force10));
force11 = find(wsnew(iwind) > 28.5 & wsnew(iwind) <= 32.7);
mpwr11 = mpwr(:,inoise(force11));
force12 = find(wsnew(iwind) > 32.7 );
mpwr12 = mpwr(:,inoise(force12));
%Knudsen Curves - modified for ddeep water ~1 km
% frequency in kHz
f = 1 : .1 : 100;
% attenuation
a = 0.036* f.^(3/2);
% tl = - 60 - 20*log10(r) - a*r;
% above equation assume distnace r in km
r = 1;
tl = - a*r;
%make plot
figure (1);
x = 1000:100000;
y = ones(size(x));
semilogx(x,y);
axis([1000,100000,10,80]);
hold on;
grid on;
ss = [0, .5, 1, 2, 3, 4, 5, 6];
% Approximation for Knudson curves
for i = 1:length(ss)
    for iif = 1:length(f)
        nl(i,iif) = 56 + (19 * log10(ss(i))) - (17 * log10(f(iif))) + tl(iif);
    end
end
% plot Knudsen curves
for i = 1: length(ss)
    semilogx(1000*f, nl(i,:),'k','LineWidth',2);
end
%
t = toc;
disp(' ')
disp(['Time Elapsed: Spectra from LTSA ', num2str(t),' secs'])






