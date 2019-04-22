function openCanvasProject
% OPENPROJECT Initialize MATLAB path to work on project

% Check that version of MATLAB is 9.1 (R2016b)
if verLessThan('matlab', '9.1')
    error('MATLAB 9.1 (R2016b) or higher is required.');
elseif verLessThan('matlab', '9.6')
    warning('It is recommended to work with MATLAB 9.6 (R2019a).')
end

% Determine the complete path of project folder
root_dir = fileparts(fileparts(mfilename('fullpath')));

% Add to path all needed directories to work
addInPath(fullfile(root_dir,'data')) % Parameters
addInPath(fullfile(root_dir,'data', 'images')) % Images
addInPath(fullfile(root_dir,'data', 'animatlab_files')) % Images
addInPath(fullfile(root_dir,'lib')) % Library of drivers for Robot
addInPath(fullfile(root_dir,'matlab'))
addInPath(fullfile(root_dir,'matlab','utilities'))

% Create work directory if it doesn't already exist
if ~isfolder(fullfile(root_dir,'work'))
    mkdir(fullfile(root_dir,'work'));
end

% Add work directory in path and set it as destination for all generated
% files from Simulink (for simulation and code generation)
addpath(fullfile(root_dir,'work'))
     
disp('Project initialization is completed.')
disp(' ')

disp('To setup Canvas (define subnetwork geometry):')
disp('Use function <a href="matlab:setupCanvas">setupCanvas</a> (matlab/utilities/setupCanvas.m)')
disp('Or use the project shortcut (Project shortcuts tab) "setupCanvas"')
disp(' ')

    function addInPath(folder)
        if isfolder(folder)
            addpath(folder)
        end
    end
end