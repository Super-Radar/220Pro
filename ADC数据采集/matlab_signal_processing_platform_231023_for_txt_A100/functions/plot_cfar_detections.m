function plot_cfar_detections(rdPower, detections, cfg, figureOpts, resultsDir)
%PLOT_CFAR_DETECTIONS Overlay detections on the Range-Doppler map.
fig = figure('Name','CFAR Detections','Visible',figureOpts.visible);
imagesc(cfg.velocity_axis_mps, cfg.range_axis_m, ...
    figure_db(rdPower, figureOpts.dynamic_range_db));
axis xy; hold on;
if ~isempty(detections)
    scatter(detections.Velocity_mps, detections.Range_m, 48, ...
        'o', 'MarkerEdgeColor', 'r', 'LineWidth', 1.2);
end
xlabel('Velocity (m/s)'); ylabel('Range (m)');
title('CFAR detections'); colorbar;
save_result_figure(fig, fullfile(resultsDir,'cfar_detections.png'), figureOpts);
end
