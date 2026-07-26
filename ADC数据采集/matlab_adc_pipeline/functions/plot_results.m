function plot_results(out, cfarMask, detections, cfg)
%PLOT_RESULTS Save range and raw-Doppler diagnostic visualizations.

visibility = 'on';

f1 = figure('Visible', visibility, 'Color', 'w');
plot(out.rangeAxis, 20*log10(abs(out.rangeFft(:,1,1))+eps), 'LineWidth', 1);
xlabel('Range (m)'); ylabel('Magnitude (dB)'); grid on;
title(sprintf('CTSAI-A100 %s profile - Range spectrum', cfg.name));
saveas(f1, fullfile(cfg.resultsDir, '01_range_spectrum.png'));

f2 = figure('Visible', visibility, 'Color', 'w');
imagesc(out.dopplerBinAxis, out.rangeAxis, out.rdPowerDb);
axis xy; colorbar; xlabel('Raw Doppler bin'); ylabel('Range (m)');
title('Raw Range-Doppler map (DDMA not decoded)');
saveas(f2, fullfile(cfg.resultsDir, '02_raw_range_doppler_map.png'));

f3 = figure('Visible', visibility, 'Color', 'w');
imagesc(out.dopplerBinAxis, out.rangeAxis, out.rdPowerDb);
axis xy; colorbar; hold on;
[r,d] = find(cfarMask);
plot(out.dopplerBinAxis(d), out.rangeAxis(r), 'ro', 'MarkerSize', 6);
xlabel('Raw Doppler bin'); ylabel('Range (m)');
title('2-D CA-CFAR on undecoded DDMA spectrum');
saveas(f3, fullfile(cfg.resultsDir, '03_raw_cfar_detections.png'));

f4 = figure('Visible', visibility, 'Color', 'w');
axis off;
text(0.02, 0.85, 'Physical velocity and angle intentionally withheld.', ...
    'FontWeight', 'bold');
text(0.02, 0.65, 'Reason: public DDMA phase/offset/channel metadata is incomplete.');
text(0.02, 0.45, sprintf('Raw CFAR detections exported: %d', height(detections)));
text(0.02, 0.25, 'See configuration_report.txt and documentation for required metadata.');
title('Processing status');
saveas(f4, fullfile(cfg.resultsDir, '04_processing_status.png'));
end
