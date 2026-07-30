function plot_adc_overview(adcRxCube, figureOpts, resultsDir)
%PLOT_ADC_OVERVIEW Plot raw ADC values for RX0 before MIMO processing.
fig = figure('Name','ADC Overview','Visible',figureOpts.visible);
imagesc(0:size(adcRxCube,2)-1, 0:size(adcRxCube,1)-1, adcRxCube(:,:,1));
axis xy; xlabel('Raw chirp index'); ylabel('Sample index');
title('Raw ADC data, RX0'); colorbar;
save_result_figure(fig, fullfile(resultsDir,'adc_overview.png'), figureOpts);
end
