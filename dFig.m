function [] = dFig(DepthFig,dip,idepth,Slope,ttex,fTS)
figure(DepthFig);
subplot(dip,1,1)
title(ttex);
hold
for i = 1 : dip % 500 Hz - 20000 Hz
    subplot(dip,1,i)
    histogram(Slope(idepth,i+1)/20,100)
    msl = mean(Slope(idepth,i+1)/20);
    ax = gca;
    ax.XLim = ([0 2]);
    mtext =[num2str(fTS(i+1)),' Hz'];
    text(0.02*ax.XLim(2),0.85*ax.YLim(2),mtext)
    mtext =['med= ',num2str(median(msl))];
    text(0.8*ax.XLim(2),0.85*ax.YLim(2),mtext)
end