function plot_clutter_suppression(rawPower, processedPower, cfg, ...
    clutterDiagnostics, figureOpts, resultsDir)
%PLOT_CLUTTER_SUPPRESSION Compare Range-Doppler maps before and after.
fig = figure('Name','Clutter Suppression','Visible',figureOpts.visible);
subplot(1,2,1);
imagesc(cfg.velocity_axis_mps, cfg.range_axis_m, ...
    figure_db(rawPower, figureOpts.dynamic_range_db));
axis xy; xlabel('Velocity (m/s)'); ylabel('Range (m)');
title('Before clutter suppression'); colorbar;

subplot(1,2,2);
imagesc(cfg.velocity_axis_mps, cfg.range_axis_m, ...
    figure_db(processedPower, figureOpts.dynamic_range_db));
axis xy; xlabel('Velocity (m/s)'); ylabel('Range (m)');
title(sprintf('After %s, rank=%d', clutterDiagnostics.method, ...
    clutterDiagnostics.removed_rank)); colorbar;

save_result_figure(fig, fullfile(resultsDir, ...
    'clutter_suppression_comparison.png'), figureOpts);
end
