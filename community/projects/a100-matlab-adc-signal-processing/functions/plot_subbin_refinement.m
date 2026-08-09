function plot_subbin_refinement(rdPower, detections, cfg, figureOpts, resultsDir)
%PLOT_SUBBIN_REFINEMENT Overlay coarse and refined peak coordinates.
if isempty(detections)
    return;
end
fig = figure('Name','Sub-bin Refinement','Visible',figureOpts.visible);
imagesc(cfg.velocity_axis_mps, cfg.range_axis_m, ...
    figure_db(rdPower, figureOpts.dynamic_range_db));
axis xy; hold on;
scatter(detections.Velocity_mps, detections.Range_m, 55, 'x', ...
    'MarkerEdgeColor','w','LineWidth',1.3);
scatter(detections.VelocityRefined_mps, detections.RangeRefined_m, 48, ...
    'o','MarkerEdgeColor','r','LineWidth',1.2);
for i = 1:height(detections)
    plot([detections.Velocity_mps(i), detections.VelocityRefined_mps(i)], ...
        [detections.Range_m(i), detections.RangeRefined_m(i)], 'w-', ...
        'HandleVisibility','off');
end
xlabel('Velocity (m/s)'); ylabel('Range (m)');
title('Coarse FFT peaks and sub-bin refined estimates');
legend('Coarse FFT bin','Refined estimate','Location','best'); colorbar;
save_result_figure(fig, fullfile(resultsDir,'subbin_refinement.png'), figureOpts);
end
