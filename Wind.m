%JAH Buoy data
sc762014 = size(c762014);
z = zeros(sc762014(1),1);
dc76 = datenum([c762014.YY,c762014.MM,c762014.DD,c762014.hh,c762014.mm,z]);
xq76 = dc76(1) : 1/(24*6) : dc76(end);
vq76 = interp1(dc76,c762014.RWSP,xq76);
%
sc852014 = size(c852014);
z = zeros(sc852014(1),1);
dc85 = datenum([c852014.YY,c852014.MM,c852014.DD,c852014.hh,c852014.mm,z]);
xq85 = dc85(1) : 1/(24*6) : dc85(end);
vq85 = interp1(dc85,c852014.RWSP,xq85);
%
[C,ia,ib] = intersect(xq76,xq85);
figure(99)
plot(vq76(ia),vq85(ib),'.')
figure(98)
co = xcov(vq76(ia),vq85(ib));
plot(co)
% 2.5 x 2.5 Global model
uwnd = ncread('/Users/jah 1 2/Dropbox/TF/WindData/uwnd.sig995.2013.nc','uwnd');
vwnd = ncread('/Users/jah 1 2/Dropbox/TF/WindData/uwnd.sig995.2013.nc','vwnd');
twnd = ncread('/Users/jah 1 2/Dropbox/TF/WindData/uwnd.sig995.2013.nc','time');
% 0.25 x 0.25 Global model
in = ncinfo('/Users/jah 1 2/Dropbox/TF/WindData/CCMP_Wind_Analysis_20050101_V02.0_L3.0_RSS.nc');
lat = ncread('/Users/jah 1 2/Dropbox/TF/WindData/CCMP_Wind_Analysis_20050101_V02.0_L3.0_RSS.nc','latitude');
lon = ncread('/Users/jah 1 2/Dropbox/TF/WindData/CCMP_Wind_Analysis_20050101_V02.0_L3.0_RSS.nc','longitude');
ti = ncread('/Users/jah 1 2/Dropbox/TF/WindData/CCMP_Wind_Analysis_20050101_V02.0_L3.0_RSS.nc','time');
uwnd = ncread('/Users/jah 1 2/Dropbox/TF/WindData/CCMP_Wind_Analysis_20050101_V02.0_L3.0_RSS.nc','uwnd');

plot(squeeze(uwind(1,1,:)))