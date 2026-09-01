n = 1;
dnew = [];
for i = 1 : length(dnvec)
    dnew((i-1)*6 +1) = dnvec(i);
    if i < length(dnvec)
        for k = 1 : 5
            dnew((i-1)*6 +1 + k) = (k/6)  * dnvec(i+1) + ...
                ((6-k)/6) * dnvec(i);
        end
    end
end
