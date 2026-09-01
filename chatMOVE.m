% Ask the user to select the input directory
inputDir = uigetdir('', 'Select the Input Directory');
if isequal(inputDir,0)
    disp('User selected Cancel');
    return;
end

% Ask the user to select the output directory
outputDir = uigetdir('', 'Select the Output Directory');
if isequal(outputDir,0)
    disp('User selected Cancel');
    return;
end

% Define the patterns to search for
patterns = {'df20', 'ltsa'};

% Get a list of all files in the input directory and subdirectories
files = dir(fullfile(inputDir, '**', '*.*'));

% Loop through the files and check for the patterns
for k = 1:length(files)
    if ~files(k).isdir && contains(files(k).name, patterns{1}) && contains(files(k).name, patterns{2})
        % Construct the full source and destination file paths
        sourceFile = fullfile(files(k).folder, files(k).name);
        destFile = fullfile(outputDir, files(k).name);

        % Copy the file to the output directory
        copyfile(sourceFile, destFile);
        disp(['Copied ' sourceFile ' to ' destFile]);
    end
end

disp('File copy process completed.');
