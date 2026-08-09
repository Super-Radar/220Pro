function save_result_figure(fig, filePath, figureOpts)
%SAVE_RESULT_FIGURE Save a PNG using exportgraphics when available.
if figureOpts.save_png
    if exist('exportgraphics', 'file') == 2
        exportgraphics(fig, filePath, 'Resolution', 160);
    else
        saveas(fig, filePath);
    end
end
if figureOpts.close_after_save
    close(fig);
end
end
