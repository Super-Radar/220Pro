%------------------------------------------------------------------------------
%   Filename     : ct_signal_processing_main.m
%   Author       : ZhuXinpeng
%   Created      : 2021-04-10
%   Description  : Signal processing platform
%------------------------------------------------------------------------------

clc
clear
close all

% 添加脚本路径
addpath('.\init_function')
addpath('.\FFT')

%% 导入雷达配置参数
cell_cfg_file_path = {
    '.\cfg\CTLRR220pro配置\sensor_config_init1.hxx';
    };

nCfgFiles = length(cell_cfg_file_path);
for iCfgFile = 1 : nCfgFiles
    fid = fopen(cell_cfg_file_path{iCfgFile});
    SensorConfig = get_radar_paramete(fid);
end

%% 导入测试数据
% f0-3：代表profile
% _0-3：表示RXchannel
cell_data_file_path = '.\data';
cell_data_file_name_list = {
    [cell_data_file_path, '\', 'adc_test_20260527115033_Pf0_Rx0.txt'];
    [cell_data_file_path, '\', 'adc_test_20260527115041_Pf0_Rx1.txt'];
    [cell_data_file_path, '\', 'adc_test_20260527115050_Pf0_Rx2.txt'];
    [cell_data_file_path, '\', 'adc_test_20260527115059_Pf0_Rx3.txt'];
};

nAdcFiles = length(cell_data_file_name_list);
adcData = load_adc_data(cell_data_file_name_list, SensorConfig);
fclose('all');
MAX_OBJ_NUM = 256;

%% 信号处理
% 2D-FFT
[rngFftData, velFftData] = do_fft_2d(adcData, SensorConfig);

% 非相干积累
RVimage = zeros(SensorConfig.rng_nfft / 2, SensorConfig.vel_nfft);
for iArray = 1 : SensorConfig.nvirtual_array
    RVimage = RVimage + power(abs(velFftData(:, :, iArray)), 2);
end
RVimage = RVimage / SensorConfig.nvirtual_array;

% 搜索目标
targetRange = 2; %可设置搜索的目标距离，会在设定距离的±searchRangeBin内搜索目标
searchRangeBin = 10;
clamp = @(x, lo, hi) max(lo, min(x, hi));
idxStart = clamp(round(targetRange / SensorConfig.rng_res) - searchRangeBin, 1, SensorConfig.rng_bin_num);
idxEnd = clamp(round(targetRange / SensorConfig.rng_res) + searchRangeBin, 1, SensorConfig.rng_bin_num);
v = max(max(db(RVimage(idxStart:idxEnd, 1:SensorConfig.vel_nfft), 'power')));
[row, col] = find(v == db(RVimage, 'power'));

% 计算全局底噪
[globalNoiseValue] = calculate_global_noise(velFftData, SensorConfig);

% display
figure(1)
subplot(2,2,1); mesh(1:SensorConfig.vel_nfft, 1:SensorConfig.rng_nfft, adcData(:,:,1)); title('Channel 1')
subplot(2,2,2); mesh(1:SensorConfig.vel_nfft, 1:SensorConfig.rng_nfft, adcData(:,:,2)); title('Channel 2')
subplot(2,2,3); mesh(1:SensorConfig.vel_nfft, 1:SensorConfig.rng_nfft, adcData(:,:,3)); title('Channel 3')
subplot(2,2,4); mesh(1:SensorConfig.vel_nfft, 1:SensorConfig.rng_nfft, adcData(:,:,4)); title('Channel 4')
sgtitle('ADC结果')

figure(2)
subplot(2,2,1); mesh(1:SensorConfig.vel_nfft, 1:SensorConfig.rng_nfft, db(abs(rngFftData(:,:,1)))); title('Channel 1')
subplot(2,2,2); mesh(1:SensorConfig.vel_nfft, 1:SensorConfig.rng_nfft, db(abs(rngFftData(:,:,2)))); title('Channel 2')
subplot(2,2,3); mesh(1:SensorConfig.vel_nfft, 1:SensorConfig.rng_nfft, db(abs(rngFftData(:,:,3)))); title('Channel 3')
subplot(2,2,4); mesh(1:SensorConfig.vel_nfft, 1:SensorConfig.rng_nfft, db(abs(rngFftData(:,:,4)))); title('Channel 4')
sgtitle('1DFFT结果')

figure(3)
subplot(2,2,1); mesh(1:SensorConfig.vel_nfft, 1:SensorConfig.rng_bin_num, db(abs(velFftData(:,:,1)))); title('Channel 1')
subplot(2,2,2); mesh(1:SensorConfig.vel_nfft, 1:SensorConfig.rng_bin_num, db(abs(velFftData(:,:,2)))); title('Channel 2')
subplot(2,2,3); mesh(1:SensorConfig.vel_nfft, 1:SensorConfig.rng_bin_num, db(abs(velFftData(:,:,3)))); title('Channel 3')
subplot(2,2,4); mesh(1:SensorConfig.vel_nfft, 1:SensorConfig.rng_bin_num, db(abs(velFftData(:,:,4)))); title('Channel 4')
sgtitle('2DFFT结果')

figure(4)
mesh(1:SensorConfig.vel_nfft, 1:SensorConfig.rng_bin_num, db(abs(RVimage), "power"));
hold on
plot3(col, row, db(abs(RVimage(row, col)),"power"), 'ro')
title('非相干积累结果')

sprintf('目标距离为：%.2fm, 目标速度为：%.2fm/s', (row - 1) * SensorConfig.rng_res, (col - 1) * SensorConfig.V_res)
sprintf('目标幅值为：%.2fdB, 全局底噪为：%.2fdB, 目标SNR为：%.2fdB', v, globalNoiseValue, v - globalNoiseValue)
