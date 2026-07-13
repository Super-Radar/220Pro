function plot_results(out, cfarMask, detections, cfg)
%PLOT_RESULTS Save the requested educational visualizations as PNG files.

visibility = 'on';

f1 = figure('Visible', visibility, 'Color', 'w');
plot(out.rangeAxis, 20*log10(abs(out.rangeFft(:,1,1))+eps), 'LineWidth', 1);
xlabel('Range (m)'); ylabel('Magnitude (dB)'); grid on;
title(sprintf('CTSAI-A100 %s profile - Range spectrum', cfg.name));
saveas(f1, fullfile(cfg.resultsDir, '01_range_spectrum.png'));

f2 = figure('Visible', visibility, 'Color', 'w');
imagesc(out.velocityAxis, out.rangeAxis, out.rdPowerDb);
axis xy; colorbar; xlabel('Velocity (m/s)'); ylabel('Range (m)');
title('Range-Doppler map (4 RX noncoherent integration)');
saveas(f2, fullfile(cfg.resultsDir, '02_range_doppler_map.png'));

f3 = figure('Visible', visibility, 'Color', 'w');
imagesc(out.velocityAxis, out.rangeAxis, out.rdPowerDb); axis xy; colorbar; hold on;
[r,d] = find(cfarMask);
plot(out.velocityAxis(d), out.rangeAxis(r), 'ro', 'MarkerSize', 6);
xlabel('Velocity (m/s)'); ylabel('Range (m)'); title('2-D CA-CFAR detections');
saveas(f3, fullfile(cfg.resultsDir, '03_cfar_detections.png'));

f4 = figure('Visible', visibility, 'Color', 'w');
if isempty(detections)
    text(0.5,0.5,'No CFAR detections','HorizontalAlignment','center'); axis off;
else
    polarscatter(deg2rad(detections.angle_deg), detections.range_m, ...
        45, detections.power_db, 'filled'); colorbar;
end
title('Estimated target angle and range');
saveas(f4, fullfile(cfg.resultsDir, '04_angle_range.png'));
end
