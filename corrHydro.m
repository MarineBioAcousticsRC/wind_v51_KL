function [TFCnan] = corrHydro(TFCnan,xseries,cseries,colk,cohk)
% Correct Hydrophones
for n = 1 : length(xseries)
    TFCnan(xseries(n),colk(xseries(n)):cohk(xseries(n))) = ...
        TFCnan(xseries(n),colk(xseries(n)):cohk(xseries(n))) - ...
        cseries(colk(xseries(n)):cohk(xseries(n)));
end
