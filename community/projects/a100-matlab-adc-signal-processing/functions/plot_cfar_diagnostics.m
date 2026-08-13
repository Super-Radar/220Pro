function plot_cfar_diagnostics(cfarResult, cfg, figureOpts, resultsDir)
%PLOT_CFAR_DIAGNOSTICS Visualize adaptive-CFAR internal statistics.
fig = figure('Name','CFAR Diagnostics','Visible',figureOpts.visible);
subplot(1,3,1);
imagesc(cfg.velocity_axis_mps, cfg.range_axis_m, cfarResult.snr_db);
axis xy; xlabel('Velocity (m/s)'); ylabel('Range (m)');
title('CUT / noise estimate (dB)'); colorbar;

subplot(1,3,2);
variabilityDisplay = min(cfarResult.variability_index, 10);
imagesc(cfg.velocity_axis_mps, cfg.range_axis_m, variabilityDisplay);
axis xy; xlabel('Velocity (m/s)'); ylabel('Range (m)');
title('Variability index CV^2 (clipped at 10)'); colorbar;

subplot(1,3,3);
imagesc(cfg.velocity_axis_mps, cfg.range_axis_m, ...
    double(cfarResult.method_map));
axis xy; xlabel('Velocity (m/s)'); ylabel('Range (m)');
title(sprintf('%s decision map', cfarResult.algorithm)); colorbar;

save_result_figure(fig, fullfile(resultsDir,'cfar_diagnostics.png'), figureOpts);
end
