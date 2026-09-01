function [TFnew] = tfmakeK(TFwind,coh,dfreq,kaitF,kaitT)
% create new TF
%JAH Sept 2020
TFnew = TFwind;
icoh = find(TFwind(:,1) >= dfreq*coh,1);
lw = length(TFwind);
lk = length(kaitT);
icohk = icoh+lk-lw;
for ikait = lk:-1:icohk % above valid wind data use kait
    TFnew(lw-lk+ikait,2) = kaitT(ikait);
end 
for ikait = icohk : -1 : 1 %choose higher of kait and wind
 if (kaitT(ikait)>TFwind(lw-lk+ikait,2))
   TFnew(lw-lk+ikait,2) = kaitT(ikait);
%    %check
%    if (kaitF(ikait)~=TFwind(lw-lk+ikait,1))
%        disp('Bad Freq ',num2str(ikait))
%    end
 end
end
%  