function plot_target_point_cloud(detections, figureOpts, resultsDir)
%PLOT_TARGET_POINT_CLOUD Plot lateral/forward position and radial velocity.
if isempty(detections)
    return;
end
angle = detections.SelectedAngle_deg;
x = detections.Range_m .* sind(angle);
y = detections.Range_m .* cosd(angle);
fig = figure('Name','Target Point Cloud','Visible',figureOpts.visible);
scatter3(x, y, detections.Velocity_mps, 55, detections.SNR_dB, 'filled');
grid on; xlabel('Lateral x (m)'); ylabel('Forward y (m)');
zlabel('Radial velocity (m/s)'); title('Detected target point cloud');
colorbar;
save_result_figure(fig, fullfile(resultsDir,'target_point_cloud.png'), figureOpts);
end
