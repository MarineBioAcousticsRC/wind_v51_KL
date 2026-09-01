%combine ADEON wav files
%JAH
% in powershell:  net use V: \\Jahs2019\l
% Get a list of all txt files in the current folder, or subfolders of it.
%cd ADEON
savedir = 'u:\ADEONnew\'; % directory to save files
firstpart = 'AMAR501.1.';
ye = '2017';
mon = '11';
day = '29';
fds = fileDatastore('*.txt', 'ReadFcn', @importdata)
fullFileNames = fds.Files
numFiles = length(fullFileNames)

% Loop over all files reading them in and plotting them.

for k = 1 : numFiles

    fprintf('Now reading file %s\n', fullFileNames{k});

    % Now have code to read in the data using whatever function you want.

    % Now put code to plot the data or process it however you want...

end


% savedir = 'E:\OOI\RS01SLBS'; % directory to save files
% savedir = 'E:\OOI\RS03AXBS'; % directory to save files

API_USERNAME = 'OOIAPI-HTTBQTNKU801RA';
API_TOKEN = 'TEMP-TOKEN-RVZ0NFZZOQYRMY';

site = 'RS03AXBS';
node = 'LJ03A';
instrument = '09-HYDBBA302';
method = 'telemetered';
stream = 'data.mseed';

api_base_url = 'https://rawdata.oceanobservatories.org/files';
yr = '2018';
mn = '05';
startnum = 0;
% find the days with data
data_request_url = sprintf('%s/%s/%s/%s/%s/%s/%s',...
    api_base_url,site,node,instrument,yr,mn);
options = weboptions('Username',API_USERNAME,'Password',API_TOKEN);
options.Timeout = 120;
respmn = [];
respmn = webread(data_request_url);
if ~isempty(respmn)
    reslmn = splitlines(respmn);
    nreslmn = extractAfter(reslmn,...
        '<img src="/folder.png" alt="[DIR]"> <a href="');
    nreslmn1 = extractBefore(nreslmn,'/">');
    kmn = ~ismissing(nreslmn1);
    imn = find(kmn == 1);
    for id = 1:length(imn)  % days in month with data
        day = nreslmn1(imn(id));
        dy = char(day);
                       if (str2num(dy) > startnum)
        data_request_url = sprintf('%s/%s/%s/%s/%s/%s/%s',...
            api_base_url,site,node,instrument,yr,mn,dy);
        response = [];
        response = webread(data_request_url);
        if ~isempty(response)
            reslines = splitlines(response);
            newrl = extractAfter(reslines,'./');
            newrl1 = extractBefore(newrl,'">');
            k = ~ismissing(newrl1); indx = 0;
            for i = 1:length(reslines)
                if (k(i) == 1)
                    indx = indx + 1;
                    drurl = [data_request_url,'/',newrl1{i}];
                    mseedfile = webread(drurl);
                    newrl2 = erase(newrl1{i},':');
                    newrl3 = erase(newrl2,'.');
                    newrl4 = strrep(newrl3,'mseed','.mseed');
                    fileout = fullfile(savedir,yr,mn,newrl4);
                    fileID = fopen(fileout,'w');
                    fwrite(fileID,mseedfile);
                    disp(['file; ',num2str(indx),' ',fileout]);
                    fclose(fileID);
                end
            end
              end  
       end
    end
end
