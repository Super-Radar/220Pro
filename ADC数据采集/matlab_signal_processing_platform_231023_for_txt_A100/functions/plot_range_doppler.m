function plot_range_doppler(rdPower, cfg, figureOpts, resultsDir)
%PLOT_RANGE_DOPPLER Plot the Range-Doppler map.
fig = figure('Name','Range-Doppler Map','Visible',figureOpts.visible);
mesh(cfg.velocity_axis_mps, cfg.range_axis_m, ...
    figure_db(rdPower, figureOpts.dynamic_range_db));
axis xy; xlabel('Velocity (m/s)'); ylabel('Range (m)');
title('Range-Doppler map'); colorbar;
save_result_figure(fig, fullfile(resultsDir,'range_doppler_map.png'), figureOpts);
end
