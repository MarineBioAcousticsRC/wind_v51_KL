% Covert csv wind data to mat3
%  load([w_pathname,w_file],'dnvec','wspeed');
clear
outdir = 'H:\Wind_Data\HAWAII';
site = 'K';
year = '2019';
fn = ['L:\Shared drives\Wind_deltaTF\Wind_Data\91197521510\91197521510_',year,'.csv'];
headerlinesIn = 1;
[A] = readtable(fn);
da = A.DATE;
wi= A.WND;
% get date into datenum format
fin = 'uuuu-MM-dd''T''HH:mm:ss' ;
dat = datetime(da,'InputFormat',fin);
dnve = datenum(dat);
% get wind in wind speed
for i = 1: length(wi)
    win(i) = str2num(wi{i,1}(9:12))/10;
end
ix = find(win < 900 & win > 0);
wspeed = win(ix); wspeed = wspeed';
dnvec = dnve(ix);
%
figure
plot(dnvec,wspeed);
datetick('x','mmm')
ylabel('Wind Speed in m/s');
xlabel(' Month ');
title(['Hawaii ',site,' ',year]);
%
fs = fullfile(outdir,year,['Hawaii',site,'windvec']);
save(fs,'site','year','dnvec','wspeed');
saveas(gcf,fs,'pdf');
