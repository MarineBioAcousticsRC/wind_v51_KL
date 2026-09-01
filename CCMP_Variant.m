function [f,mid,post,lat,lon] = CCMP_Variant(...
    pre,pre0,year,m,d,mid0,mid1,mid2,post0,post1,post2)
% check for CCMP variant file name, get lat lon
mid0 = [pre0,m,mid0];
las0 = [mid0,year,m,d,post0];
las1 = [mid1,year,m,d,post1];
las2 = [mid2,year,m,d,post2];
f0 = fullfile(pre,year,las0);
f1 = fullfile(pre,year,las1);
f2 = fullfile(pre,year,las2);
isfile0 = exist(f0,'file');
isfile1 = exist(f1,'file');
isfile2 = exist(f2,'file');
% find which variant
if isfile1 == 2
    f = f1;
    mid = mid1;
    post = post1;
    lat = ncread(f,'latitude');
    lon = ncread(f,'longitude');
elseif isfile2 == 2
    f = f2;
    mid = mid2;
    post = post2;
    lat = ncread(f,'latitude');
    lon = ncread(f,'longitude');
elseif isfile0 == 2
    f = f0;
    mid = mid2;
    post = post2;
    lat = ncread(f,'lat');
    lon = ncread(f,'lon');
else
    f = 'n';
    mid = []; post = []; 
    lat = 0; lon = 0;
end
