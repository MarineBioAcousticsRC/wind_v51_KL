%
figure(1);
yell = []; cc = 'p';
while cc == 'p'
    disp(' Clean bad data: Enter "p" in window, else any key to proceed')
    pause  % wait for user input.
    cc = get(gcf,'CurrentCharacter'); % get key stroke
    % if brush selected get action key
    if strcmp(cc,'p')
        disp(' r = bad; g = good; s = skip')
        h = brush;
        set(h,'Color',[1,1,0],'Enable','on'); % light yellow [.9290 .6940 .1250]
        waitfor(gcf,'CurrentCharacter')
        set(h,'Enable','off')
        cc = get(gcf,'CurrentCharacter');
    end
    if  strcmp(cc,'g') || strcmp(cc,'r')
        % data were flagged by user
        disp(' Update Display') % Stay on same bout
        % get brushed data and figure out what to do based on color:
        disp(' Will do somthing to data')
        zFD = [];
        [yell,zFD,bFlag] = brush_colorWIND(gca,cc,zFD);
        cc = 'p';
    elseif  strcmp(cc,'s')
        disp(' No change')
        cc = 'p';
    end
end
%% save wind