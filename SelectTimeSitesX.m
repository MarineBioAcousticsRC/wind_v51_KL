function [filesfound,inpath,infile,count] = SelectTimeSitesX(pat1,pat2,pat3)
%select which site
global p
list = dir(fullfile(p.infolder));
dirlist = [list.isdir];
sFolders = list(dirlist);
sFolderD = {sFolders.folder};
sFolderN = {sFolders.name};
lfold = length(sFolderN);
count = 0; 
filesfound = cell(500,1);
inpath = cell(500,1);
infile = cell(500,1);
for ix = 1 : lfold
    listfile = dir(fullfile(sFolderD{ix},sFolderN{ix}));

    % Loop through the list to find folders that include 'df100' in their name
    numfol = 0;
    for k = 1:length(listfile)
        if listfile(k).isdir && contains(listfile(k).name, 'df100')
            % This is a folder that includes 'df100' in its name
            numfol = 1 + numfol;
            selectedFolder{numfol} = fullfile(listfile(k).name);
            disp(['Found folder: ' selectedFolder(numfol)]);
%             % List all files in the selected folder
%             folderContents{numfol} = dir(selectedFolder{numfol});
%             disp(['Files in ' selectedFolder{numfol} ':']);
%           
        end
    end
 
    for iy = 1: length(selectedFolder)
        disp(selectedFolder{iy})
        e1 = extract(lfile{1,iy},pat1);
        e2 = extract(lfile{1,iy},pat2);
        e3 = extract(lfile{1,iy},pat3);
        disp([e1,' ',e2,' ',e3])
        if ~isempty(e1) && ~isempty(e2)  && ~isempty(e3)
            fnParms = fullfile(sFolderD{ix},sFolderN{ix},lfile{1,iy});
%             disp(['File ',num2str(ix),' ',fnParms]);
            count = count + 1;
            filesfound{count,1} = string(fnParms);
            inpath{count} = fullfile(sFolderD{ix},sFolderN{ix});
            infile{count} = lfile{1,iy};
        end

    end
end

