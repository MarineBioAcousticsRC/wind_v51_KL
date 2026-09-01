function dn=era5time(tihr)
% convert CCMP time into MATLAB datevec
dn1900 = datenum(1900,1,1);
dn = datenum(addtodate(dn1900,tihr,'hour'));
end

