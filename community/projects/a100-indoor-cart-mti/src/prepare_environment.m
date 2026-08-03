function env = prepare_environment(project_root)
%PREPARE_ENVIRONMENT Load free dependencies and create output directories.

if nargin < 1 || isempty(project_root)
    project_root = fileparts(fileparts(mfilename('fullpath')));
end

if exist('OCTAVE_VERSION', 'builtin')
    runtime = ['GNU Octave ' OCTAVE_VERSION];
    try
        pkg('load', 'signal');
    catch err
        error('a100:MissingSignalPackage', ...
            ['The free Octave signal package is required. Install it with ' ...
             '"pkg install -forge signal". Original error: %s'], err.message);
    end
else
    runtime = version;
end

figures_dir = fullfile(project_root, 'figures');
results_dir = fullfile(project_root, 'results');
if ~exist(figures_dir, 'dir')
    mkdir(figures_dir);
end
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

set(0, 'defaultfigurevisible', 'off');
rand('state', 20260802); %#ok<RAND>
randn('state', 20260802); %#ok<RAND>

env = struct('runtime', runtime, ...
             'project_root', project_root, ...
             'figures_dir', figures_dir, ...
             'results_dir', results_dir);
end
