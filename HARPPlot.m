% make map of HARPS for Wind Paper
%OCt 2020 JAH
% assume readtable('F:\Shared drives\MBARC_All\Code\WindCode\WindDeploy.xls')
latname = WindStudyDeploymentsv2.Latitude(2:289);
lonname = WindStudyDeploymentsv2.Longitude(2:289);
latna = strrep(latname,'-',' ');
lonna = strrep(lonname,'-',' ');
latn = split(latna,' ');
lonn = split(lonna,' ');
for i = 1:length(latn)
    lat(i) = str2num(latn(i,1)) + str2num(latn(i,2))/60;
    lon(i) = str2num(lonn(i,1)) + str2num(lonn(i,2))/60;
     if strcmp(latn(i,3),'S')
        lat(i) =  - lat(i);
    end
    if strcmp(lonn(i,3),'W')
        lon(i) = 360 - lon(i);
    end
end
gb = geobubble(lat,lon,'Basemap','bluegreen');
