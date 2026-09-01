%Jah Extract Wind time series from CCMP data
% Oct 8, 2019
% exmple file name
% '/Volumes/CzikoAudio1/WIND/CCMP/2005/CCMP_Wind_Analysis_20050101_V02.0_L3.0_RSS.nc'
%
for yr = 2005 : 2005
    year = num2str(yr);
    % deployment site
    % site
    site = 'GofAKCB';
    slat = 58.66302424; slon =	148.0451015;
    %
    %pre = '/Volumes/CzikoAudio1/WIND/CCMP/';
    pre = 'H:\WIND\CCMP\';
    %mid = '/CCMP_Wind_Analysis_';
    mid = '\CCMP_Wind_Analysis_';
    post = '_V02.0_L3.0_RSS.nc';
    % get latitude and longitude loction from first file
    las = [mid,year,'01','01',post];
    f = fullfile(pre,year,las);
    lat = ncread(f,'latitude');
    lon = ncread(f,'longitude');
    % find point near deployment site
    slat25 = (round((slat+.125) * 4))/4 - .125;
    slon25 = (round((slon+.125) * 4))/4 - .125;
    % Difference with wind site?
    disp([' Del-Lat = ',num2str(slat - slat25),' deg']);
    disp([' Del-Lon = ',num2str(slon - slon25),' deg']);
    ilat = find(lat == slat25);
    ilon = find(lon == slon25);
    dnvec = zeros(4*365,1);  ivec = 0;
    uwvec = dnvec;  vwvec = dnvec;
    for month = 1:12
        if month < 10
            ml = num2str(month);
            m = ['0',ml];
        else
            m = num2str(month);
        end
        for day = 1:31
            if day < 10
                dl = num2str(day);
                d = ['0',dl];
            else
                d = num2str(day);
            end
            las = [mid,year,m,d,post];
            f = fullfile(pre,year,las);
            isfile = exist(f,'file');
            if isfile == 2
                %n = ncinfo(f); % read data for one day
                tihr = ncread(f,'time');
                uwnd = ncread(f,'uwnd');
                vwnd = ncread(f,'vwnd');
                for i = 1:4
                    ivec = ivec + 1;
                    dnvec(ivec) = datenum([1987,0,1,tihr(i),0,0]);
                    %test date
                    if i == 1
                        dntest = datenum([yr,month,day,0,0,0]);
                        if dntest ~= dnvec(ivec)
                            disp(['Date Prob ',dntest, dnvec(ivec)]);
                        end
                    end
                    uwvec(ivec) = uwnd(ilon,ilat,i);
                    vwvec(ivec) = vwnd(ilon,ilat,i);
                end
            else
                disp(['Not Valid:  ',year,m,d]);
            end
        end
    end
    % plot wind speed
    figure
    subplot(2,1,1)
    wspeed = sqrt(uwvec.^2 + vwvec.^2);
    plot(dnvec,wspeed);
    datetick('x','mmm')
    title([site,' Wind Speed ',num2str(year),'  lat= ',num2str(slat25),...
        '  lon= ',num2str(slon25)]);
    ylabel('Wind Speed in m/s');
    xlabel(' Month ');
    %plot wind direction
    subplot(2,1,2)
    wdir = 180*atan2(vwvec,uwvec)/pi; % v is north u is east
    wmetdir = wdir;
    idir = find (wdir < 0); % meterological convention 0-360 deg
    wmetdir(idir) = 360 + wdir(idir);
    plot(dnvec,wmetdir);
    datetick('x','mmm')
    title([site,' Wind Direction ',num2str(year),'  lat= ',num2str(slat25),...
        '  lon= ',num2str(slon25)]);
    ylabel('Meterological Wind Direction re: North');
    xlabel(' Month ');
    %save results
    fs = fullfile(pre,year,'windvec');
    save(fs,'site','year','slat25','slon25','dnvec','uwvec','vwvec',...
        'wspeed','wmetdir');
    saveas(gcf,fs,'pdf');
    %
end