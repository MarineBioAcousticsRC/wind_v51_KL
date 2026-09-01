% Code to plot regression versus depth
%JAH 11-2019
%load('H:\Wind_TF\Regress\RegOutALL.mat')
c = cmid;
lc = length(c);
xdepth = [];
in = 1;
xfreq = (c{1,in}{1,9});
for i = 1: lc
    xdepth(in) = cell2mat(c{1,i}(1,4));
    xslope(in,:) = cell2mat(c{1,i}(1,7));
    xincept(in,:) = cell2mat(c{1,i}(1,8)); 
    in = in +1;
end
% figure(88)
% plot(xdepth,xslope(:,1),'o')
[xfitr, xgof] = createFit2(xdepth,xslope(:,1)','on');
        SLR1 = xfitr.p1;
        OLR1 = xfitr.p2;       
% hold on
% plot(xdepth,xslope(:,10),'ro')
[xfitr, xgof] = createFit2(xdepth,xslope(:,10)','on');
        SLR10 = xfitr.p1;
        OLR10 = xfitr.p2;       
        
        % plot(xdepth,xincept(:,1),'ro')
[xfitr, xgof] = createFit2(xdepth,xincept(:,1)','on');
        INLR1 = xfitr.p1;
        INLR1 = xfitr.p2;       

        % plot(xdepth,xincept(:,10),'ro')
[xfitr, xgof] = createFit2(xdepth,xincept(:,10)','on');
        INLR10 = xfitr.p1;
        INLR10 = xfitr.p2;       


