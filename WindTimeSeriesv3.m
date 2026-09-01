%Jah Extract Wind time series from CCMP data
% Oct 2021 added ERA5 option
% added 2004 in Aug 2022
% Oct 8, 2019
%
clear;
wmod = 'CCMP';
drivelet = 'G';
pre = [drivelet,':\Shared drives\Wind_deltaTF\Wind_Model\CCMP\'];
pre0 = '\v11l30_2004';
mid0 = '\analysis_';
post0 = '_v11l30flk.nc';
mid1 = '\CCMP_Wind_Analysis_';
post1 = '_V02.0_L3.0_RSS.nc';
mid2 = '\CCMP_RT_Wind_Analysis_';
post2 = '_V02.1_L3.0_RSS.nc';
outpath = [drivelet,':\Shared drives\Wind_deltaTF\Wind_Data'];
%
% wmod = 'ERA5';
% pre = 'H:\Wind_Model\ERA5\';
% mid = '\';
% post = '.nc';
for yr = 2022 : 2023
    year = num2str(yr);
    % deployment site
    % site
    Proj = 'SOCAL';
    site = 'B';
    outdir = fullfile(outpath,Proj,num2str(yr));  % Output file directory
    if ~isfolder(outdir)
        disp(['Make new folder: ',outdir])
        mkdir(outdir);
    end
    disp([Proj,' ',site,' ',year]);
    
    % deployment locations for each site
     [slat,slon] = WhichProjSite(Proj,site);
    
    % convert to East Lon
    slon = 360 - slon;
    %pre = '/Volumes/CzikoAudio1/WIND/CCMP/';
    %pre = '/Users/jah 1 2/Ddirectory/Whale/WIND/CCMP/';

    % get latitude and longitude loction from first file
    [f,mid,post,lat,lon] = CCMP_Variant(...
        pre,pre0,year,'01','01',mid0,mid1,mid2,post0,post1,post2);

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
            [f,mid,post,lat,lon] = CCMP_Variant(...
        pre,pre0,year,m,d,mid0,mid1,mid2,post0,post1,post2);
            if ~strcmp(f,'n')
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
                disp(['Not Valid Date:  ',year,m,d]);
            end
        end
    end
    % plot wind speed
    figure
    subplot(2,1,1)
    wspeed = sqrt(uwvec.^2 + vwvec.^2);
    % take out bad data
    isok = find(wspeed > 0);
    wspeed = wspeed(isok);
    dnvec = dnvec(isok);
    uwvec = uwvec(isok);
    vwvec = vwvec(isok);
    %
    plot(dnvec,wspeed);
    datetick('x','mmm')
    title([Proj,site,' Wind Speed ',num2str(year),'  lat= ',num2str(slat25),...
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
    title([Proj,site,' Wind Direction ',num2str(year),'  lat= ',num2str(slat25),...
        '  lon= ',num2str(slon25)]);
    ylabel('Meterological Wind Direction re: North');
    xlabel(' Month ');
    %save results
    fs = fullfile(outdir,[Proj,site,'windvec']);
    save(fs,'Proj','site','year','slat25','slon25','dnvec','uwvec','vwvec',...
        'wspeed','wmetdir');
    saveas(gcf,fs,'pdf');
    %
end