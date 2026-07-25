function plot_adc_overview(adcCube, figureOpts, resultsDir)
%PLOT_ADC_OVERVIEW Plot first virtual channel ADC values.
fig = figure('Name','ADC Overview','Visible',figureOpts.visible);
imagesc(0:size(adcCube,2)-1, 0:size(adcCube,1)-1, adcCube(:,:,1));
axis xy; xlabel('Chirp index'); ylabel('Sample index');
title('ADC data, channel 1'); colorbar;
save_result_figure(fig, fullfile(resultsDir,'adc_overview.png'), figureOpts);
end
