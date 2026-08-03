function save_png(fig, file_path)
%SAVE_PNG Save a deterministic 150-DPI PNG and verify it is non-empty.

[parent_dir, ~, ~] = fileparts(file_path);
if ~exist(parent_dir, 'dir')
    mkdir(parent_dir);
end
if exist('OCTAVE_VERSION', 'builtin')
    toolkits = available_graphics_toolkits();
    if any(strcmp(toolkits, 'gnuplot'))
        graphics_toolkit(fig, 'gnuplot');
    end
end
set(fig, 'paperpositionmode', 'auto');
% Ghostscript bundled with Octave cannot write directly to some Windows
% paths containing non-ASCII characters. Render in the ASCII temp folder,
% then move the completed PNG through Octave's Unicode-aware file API.
temporary_file = [tempname '.png'];
cleanup = onCleanup(@() delete_if_exists(temporary_file));
print(fig, temporary_file, '-dpng', '-r150');
[moved, message] = movefile(temporary_file, file_path, 'f');
if ~moved
    error('a100:FigureMoveFailed', 'Could not move figure to %s: %s', file_path, message);
end
clear cleanup;
info = dir(file_path);
if isempty(info) || info.bytes == 0
    error('a100:EmptyFigure', 'Figure was not written: %s', file_path);
end
close(fig);
end

function delete_if_exists(file_path)
if exist(file_path, 'file')
    delete(file_path);
end
end
