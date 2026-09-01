function [yell,zFD,bFlag] = brush_colorWIND(hFig,cc,zFD,ptime)

% brush_color.m

% Get brushed data from figure and based on specified color code modify data

% Inputs
%   hFig - Figure handle
%
%   cc - Keyboard shortcut label
%       A string with a keyboard shortcut to label data as:
%       'r' - False detection
%       'y' - Highlight selected data to show features (shown in black)
%       'g' - True detection
%       'u' - Update data according to current color brush selection. The
%       other keyboard shortcuts do not work if brush color is:
%           red - False detection
%           yellow - Highlight selected data to show features (shown in black)
%           green - True detection
%
%   zFD - An [N x 1] vector of detection times labeled as false detections,
%         where N is the number of detections.
%
%
%   colorTab - Color code for classification - ID signal types
%              [191, 191,   0] type 1 green
%              [191,   0, 191] type 2 purple
%              [  0, 127,   0] type 3 dark-green
%              [  0, 191, 191] type 4 light-blue
%              [ 20,  43, 140] type 5 dark-blue
%              [218, 179, 255] type 6 pale-purple
%              [255, 214,   0] type 7 yellow
%              [222, 125,   0] type 8 orange
%              [255, 153, 199] type 9 pink
%              [153,  51,   0] type 10  brown
%
%   t - An [N x 1] vector of detection times from current window session.
%
%
%
% Output:
%
%   yell - An [N x 1] vector of indices of highlighted detection times,
%          where N is the number of detections.
%
%   zFD - An [N x 1] vector of detection times labeled as false detections,
%         where N is the number of detections.
%
%   bFlag - Logical,track if brush is on record

yell = [];

% Find brushed axes
[brushDate, bFlag] = get_brushedWIND(hFig);

if ~isempty(brushDate)
    
    if strcmp(cc,'r')
        % Red paintbrush or 'r' = False Detections
        disp(['Number of False Detections = ',num2str(length(brushDate))])
        % Add false detections to FD matrix
        [newFD,~] = intersect(ptime, brushDate);
        zFD = [zFD; newFD];
        
    elseif strcmp(cc,'g')
        % Green paintbrush or 'g' = True Detections
        disp(['Number of Detections Selected = ',num2str(length(brushDate))])
        if exist('zFD','var')
            
            % Clear brushed set from FD set
            if ~isempty(zFD)
                [~,zFDkeep] = setdiff(zFD,brushDate);
                zFD = zFD(zFDkeep,:);
            end
            disp(['Remaining Number of False Detections = ',num2str(length(iC))])
        end
        
    elseif  strcmp(cc,'y')
        % Yellow paintbrush or 'y' = Highlight Detections
        disp(['Start time selected data: ',datestr(brushDate(1),'dd-mm-yyyy HH:MM:SS.FFF')]);
        [~,yell] = intersect(ptime, brushDate);
        
        
    end
end


