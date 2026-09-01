function [TFold, TFnew] = tfmake(col, coh, freq, Ptf, MTFCorr,tfn)
% create new TF 
%JAH Sept 2020
global PARAMS
iPtf = find(PARAMS.tf.freq > 0 & PARAMS.tf.freq < 100); % part below 100Hz
miP = max(iPtf);
TFnew = [PARAMS.tf.freq(iPtf)',PARAMS.tf.uppc(iPtf)'];% adds < 100 Hz data
TFnew(miP+1:miP+1000,:) = [freq(2:1001)',Ptf(2:1001)']; %  100 Hz - 100 kHz
TFold = TFnew;
TFnew(1:miP,2) = TFnew(1:miP,2) + MTFCorr(col); % for < 500 Hz
TFnew(miP+1:miP+col-1,2) = TFnew(miP+1:miP+col-1,2) + MTFCorr(col); % for 100 Hz - 400 Hz
TFnew(miP+col:miP+coh,2) = TFnew(miP+col:miP+coh,2) + MTFCorr(col:coh)'; % for 500 Hz - 20 kHz
if (tfn >= 697 && tfn < 780 ) % 20 kHz xover
    for i = 1:80
    TFnew(miP+coh+i,2) = TFnew(miP+coh+i,2) + (1 - i/100) * MTFCorr(coh); % taper over 8 kHz
    end
else
    TFnew(miP+coh+1:end,2) = TFnew(miP+coh+1:end,2) + MTFCorr(coh); % for > 20 kHz
end
%