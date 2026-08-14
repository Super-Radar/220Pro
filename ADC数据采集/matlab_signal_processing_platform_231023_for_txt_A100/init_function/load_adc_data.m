function [adcData] = load_adc_data(file, Cfg)
%------------------------------------------------------------------------------
%   load_1rx_adc_data.m
%------------------------------------------------------------------------------
%   Author       : ZhuXinpeng
%   Created      : 2021-05-13
%   Description  : Load legacy and session-style RadarTools ADC data
%------------------------------------------------------------------------------

nfiles = numel(file);
target_dim = [Cfg.rng_nfft / 2, Cfg.nchirp];
adcTemp2 = zeros(target_dim(2), target_dim(1), nfiles);

for ifile = 1:nfiles
    [adcTempCol, metadata] = read_adc_capture_file(file{ifile}, Cfg);

    fprintf('通道 %d:\n', ifile);
    fprintf('  ADC 样本数: %d\n', numel(adcTempCol));
    if metadata.has_header
        fprintf('  文件头: Rx%d, %d samples, %d chirps\n', ...
            metadata.rx_channel, metadata.sample_count, metadata.chirp_count);
    end

    adcTemp2(:, :, ifile) = reshape(adcTempCol, target_dim).';
end

if Cfg.nvirtual_chirp == 1
    for iArray = 1 : Cfg.nvirtual_array
        adcData(:, :, iArray) = permute(adc_mem_2_real_fixed(adcTemp2(:, :, iArray)), [2, 1]);
    end
else
    for iArray = 1 : Cfg.nvirtual_array / Cfg.nvirtual_chirp
        adcTx1 = adcTemp2(1 : Cfg.vel_nfft, :, iArray);
        adcTx2 = adcTemp2(Cfg.vel_nfft + 1 : end, :, iArray);
        adcData(:, :, iArray * 2 - 1) = permute(adc_mem_2_real_fixed(adcTx1), [2, 1]);
        adcData(:, :, iArray * 2) = permute(adc_mem_2_real_fixed(adcTx2), [2, 1]);
    end
end

end
