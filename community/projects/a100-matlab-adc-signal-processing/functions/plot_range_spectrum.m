function plot_range_spectrum(rangePower, cfg, figureOpts, resultsDir)
%PLOT_RANGE_SPECTRUM Plot noncoherently integrated range spectrum.
fig = figure('Name','Range Spectrum','Visible',figureOpts.visible);
plot(cfg.range_axis_m, figure_db(rangePower, figureOpts.dynamic_range_db), ...
    'LineWidth', 1.2); grid on;
xlabel('Range (m)'); ylabel('Power (dB)'); title('Range spectrum');
xlim([cfg.range_axis_m(1), cfg.range_axis_m(end)]);
save_result_figure(fig, fullfile(resultsDir,'range_spectrum.png'), figureOpts);
end
