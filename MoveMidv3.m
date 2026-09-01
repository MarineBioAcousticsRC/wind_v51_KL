% Code to move Mid files from SNOWMAN
%JAH 11-2020
% too much variablity in name . some hacking is needed!!
%if seeking 'mid' files get them from SNOWMAN and move to LTSA disk
% use PowerShell to create drive mapping berfore using this command:
% PS prompt> net use Z: \\SNOWMAN\Atlantic_Region_Decimated_1
% to remove:  net use z: /delete
warning off
clear variables
close all
% p holds var that come from getWindParams
% PARAMS read from the LTSAs
global p
for Dep = [7]
    drivelet = 'Z'; Proj = 'Arctic'; Site = 'C2'; ProjC = 'Arctic';
    if Dep <10
        Depl = ['0',num2str(Dep)];
    else
        Depl = num2str(Dep);
    end
    % aAdd extra on Depl
    %     Depl = [Depl,'_D_C4'];
%        Depl = [Depl,'-CORC02'];
    FoldIn = '\\frosty\Arctic_Region_Decimated_1\Arctic';
      forma = 'old'; %Proj,Depl,Site
%             forma = 'new'; % Proj_Site_Depl
    % forma = 'new'; %Proj_SiteDepl
    %     forma = 'junk';
    for ix = 1:2
        if isequal (ix,1)
            type ='low';
            pat2 = 'df100';
        else
            type ='mid';
            pat2 = 'df20';
        end
%         p = getWindParams(drivelet,Proj,Site,Depl); % paramter file
        FoldOut = '\\frosty\LTSA\Arctic\C2' ;
        %
%         if strcmp(type,'mid') && ~strcmp(Depl(end-1:end),'C4')
%             pat2 = 'df20';
%         elseif strcmp(type,'mid') && strcmp(Depl(end-1:end),'C4')
%             pat2 = 'df10';
%         elseif strcmp(type,'low') && ~strcmp(Depl(end-1:end),'C4')
%             pat2 = 'df100';
%         elseif strcmp(type,'low') && strcmp(Depl(end-1:end),'C4')
%             pat2 = 'df50';
%         end
        %
        if strcmp(forma,'new')
            pat1 = [Proj,'_',Site,'_',Depl];
        elseif strcmp(forma,'new1')
            pat1 = [Proj,'_',Site,Depl];
        elseif strcmp(forma,'old')
            pat1 = [ProjC,Depl,Site];
%                         pat1 = [Proj,Site,Depl];
        elseif strcmp(forma,'old1')
             pat1 = [Proj,Depl];

        end
        pat3 = 'ltsa';
%         p.infolder = fullfile(FoldIn,[Proj,' ',Site],pat1);
%         p.infolder = fullfile(FoldIn,[Proj,Depl,Site]);
          p.infolder = fullfile(FoldIn,pat1);
%          p.infolder = '\\snowman\GofMX_Decimated_4\GOM_HH_05';
%          p.infolder = fullfile(FoldIn,Proj,pat1);
        outfolder = fullfile(FoldOut,pat2);
%                 outfolder = fullfile(FoldOut,Site,pat2,...
%                     [Proj,'_',Site,'_',Depl,'_',pat2]);

        %
%         if strcmp(Depl(end-1:end),'C4')
%             pat2l = [pat2,'_CH1.ltsa'];
%         else
%             pat2l = [pat2,'.ltsa'];
%         end

        [filesfound1,inpath1,infile1,count1] = SelectTimeSitesX(pat1,pat2,pat3);
        filesfound1 = filesfound1(~any(cellfun('isempty', filesfound1), 2), :);
        inpath1 = inpath1(~any(cellfun('isempty', inpath1), 2), :);
        infile1 = infile1(~any(cellfun('isempty', infile1), 2), :);

        %
        
        if ~exist(outfolder)
            disp([' Create new Folder: ',outfolder])
            mkdir(outfolder);
        end
        numfiles = length(infile1);
        for nf = 1 : numfiles
            Myfile = fullfile(inpath1{nf,1},infile1{nf,1});
            disp(Myfile)
            copyfile(Myfile,outfolder)
        end
    end
end
