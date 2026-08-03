function [adcData] = load_adc_data(file, Cfg)
%------------------------------------------------------------------------------
%   load_1rx_adc_data.m
%------------------------------------------------------------------------------
%   Author       : ZhuXinpeng
%   Created      : 2021-05-13
%   Description  : Load all adc data (Fixed Length Mismatch)
%------------------------------------------------------------------------------

nfiles = numel(file);

for ifile = 1:nfiles
    % 1. 读取数据并展平为列向量
    adcTempCol = csvread(file{ifile});
    adcTempCol = adcTempCol(:);
    actual_len = length(adcTempCol);
    
    % 2. 关键修复：统一预期长度和reshape目标
    target_dim = [Cfg.rng_nfft/2, Cfg.nchirp];
    expected_len = prod(target_dim);  % 直接用reshape需要的长度g'fgf
    
    % 打印调试信息
    fprintf('通道 %d:\n', ifile);
    fprintf('  实际数据长度: %d\n', actual_len);
    fprintf('  reshape目标维度: %d × %d (需要元素数: %d)\n', ...
        target_dim(1), target_dim(2), expected_len);
    
    % 3. 强制对齐到reshape需要的长度
    if actual_len > expected_len
        warning('通道 %d 数据过长，自动截断到 %d 个样本', ifile, expected_len);
        adcTempCol = adcTempCol(1:expected_len);
    elseif actual_len < expected_len
        warning('通道 %d 数据过短，自动补零到 %d 个样本', ifile, expected_len);
        adcTempCol = [adcTempCol; zeros(expected_len - actual_len, 1)];
    end
    
    % 4. 现在元素数100%匹配，直接reshape
    adcTemp(:, ifile) = adcTempCol;
    adcTemp1(:, :, ifile) = reshape(adcTempCol, target_dim);
    adcTemp2(:, :, ifile) = adcTemp1(:, :, ifile)';
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