clear
filen = 'H:\Wind_Model\ERA5\2020\file4.nc';
time = ncread(filen,'time');
for i = 1:length(time)
    dn(i) = era5time(time(i));
end
datevec(dn(1))
datevec(dn(end))