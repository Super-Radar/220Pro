function  SensorConfig = get_radar_paramete(fid)
%------------------------------------------------------------------------------
%   get_radar_paramete.m
%------------------------------------------------------------------------------
%   Author       : ZhuXinpeng
%   Created      : 2021-04-10
%   Description  : Getting radar configuration from .hxx file
%------------------------------------------------------------------------------
%   Reviser      : ZhuXinpeng
%   Edited       : 2021-04-12
%   Description  : add cfar para init
%------------------------------------------------------------------------------
%   Reviser      : ZhuXinpeng
%   Edited       : 2021-10-09
%   Description  : add doa para init
%------------------------------------------------------------------------------

%% Get all radar configuration information
configTemp1 = textscan(fid, '%s', 1);
while(~strcmp(configTemp1{1, 1}{1, 1}, '.fmcw_startfreq'))
    configTemp1 = textscan(fid, '%s', 1);
end
configTemp2 = textscan(fid, '%s', 'Delimiter', '=');
configTemp2{1, 1}{1, 1} = '.fmcw_startfreq ';
configLen = length(configTemp2{1, 1});
nConfigName = 1 : 2 : configLen;
nConfigValue = 2 : 2 : configLen;
nValues = length(nConfigValue);
configTemp3 = cell(nValues, 2);
for i = 1 : nValues
    configTemp3{i, 1} = configTemp2{1, 1}{nConfigName(i), 1}(2 : end);
    configTemp3{i, 2} = configTemp2{1, 1}{nConfigValue(i), 1}(1 : end - 1);
end

%% The useful radar configuration information is extracted and put into the structure
for i = 1 : size(configTemp3, 1)
%     if i < 101
%         continue;
%     end
    for j = 1 : length(configTemp3{i, 1})
        if(configTemp3{i, 1}(j) == ' ')
            break;
        end
    end
    str = string(configTemp3{i, 1}(1 : j - 1));

    if(~contains(str, '/'))
        switch str
            % 十六进制类
            case {'tx_groups', 'cfar_recwin_msk', 'cfar_sogo_mask', 'doa_fft_mux', 'combined_doa_fft_mux', ...
                    'agc_code', 'ant_info_flash_addr', 'phase_scramble_init_state', 'phase_scramble_tap', ...
                    'freq_hopping_init_state', 'freq_hopping_tap', 'chirp_shifting_init_state', ...
                    'chirp_shifting_init_tap', 'cfar_pk_en', 'cfar_noise_type', 'cfar_region_algo_type'}
                dataConfigTemp1 = configTemp3{i, 2};
                
                for k = 1 : length(dataConfigTemp1)
                    if(dataConfigTemp1(k) == '{')
                        dataConfigTemp1(k) = '[';
                    end
                    if(dataConfigTemp1(k) == '}')
                        dataConfigTemp1(k) = ']';
                    end
                end
                
                idxStart = [];
                idxEnd = [];
                for k = 1 : length(dataConfigTemp1) - 1
                    if(strcmp(dataConfigTemp1(k : k + 1), '0x'))
                        idxStart = [idxStart k];
                    end
                end
                for k = 1 : length(dataConfigTemp1)
                    if((dataConfigTemp1(k) == ',' || dataConfigTemp1(k) == ']'))
                        idxEnd = [idxEnd k];
                    end
                end
                
                if(isempty(idxEnd) && length(idxStart) == 1)
                    tmp1 = hex2dec(dataConfigTemp1(idxStart + 2 : end));
                else
                    tmp1 = zeros(length(idxStart), 1);
                    for k = 1 : length(idxStart)
                        tmp1(k) = hex2dec(dataConfigTemp1(idxStart(k) + 2 : idxEnd(k) - 1));
                    end
                end
                
                temp2 = [];
                for k = 1 : length(tmp1)
                    temp2 = [temp2 num2str(tmp1(k)) ','];
                end
                dataConfigTemp1 = ['[' temp2 ']'];
                eval(join(['SensorConfig.' str '=' dataConfigTemp1 ';']));
                
            % 字符串类
            case {'rng_win', 'vel_win', 'cfar_mimo_win', 'doa_win'}
                dataConfigTemp2 = configTemp3{i, 2};
                switch dataConfigTemp2(2 : end - 1)
                    case {'cheb'}
                        eval(join(['SensorConfig.' str '= 1' ';']));
                    case {'hanning'}
                        eval(join(['SensorConfig.' str '= 2' ';']));
                    case {'hamming'}
                        eval(join(['SensorConfig.' str '= 3' ';']));
                    otherwise
                        eval(join(['SensorConfig.' str '= 0' ';']));
                end
                
            % 逻辑判断类
            case {'fft_nve_bypass', 'bfm_iter_search', 'ant_info_from_flash', 'bpm_mode', 'phase_scramble_on', 'freq_hopping_on', ...
                    'chirp_shifting_on', 'fsm_on', 'agc_align_en', 'adc_comp_en', 'de_vel_amb', 'spk_en', 'spk_set_zero', ...
                    'spk_thres_dbl', 'spk_min_max_sel', 'zero_doppler_cancel', 'anti_velamb_en', 'dml_extra_1d_en', 'dml_p1p2_en', 'sv_read_from_flash'}
                dataConfigTemp3 = configTemp3{i, 2};
                idxFalse = strfind(dataConfigTemp3, 'false');
                idxTrue = strfind(dataConfigTemp3, 'true');
                idxLogic = [idxFalse idxTrue];
                idxLogic = sort(idxLogic, 'ascend');
                tmpLogic = zeros(1, length(idxLogic));
                for k = 1 : length(idxLogic)
                    if(~isempty(find(idxLogic(k) == idxTrue, 1)))
                        tmpLogic(k) = 1;
                    end
                end
                eval(join(['SensorConfig.' str '=' '[' num2str(tmpLogic) ']'';']));
                
            % 单引号类
            case {'doa_samp_space'}
                eval(join(['SensorConfig.' str '= 1' ';']));
                
            % 其他
            otherwise
                dataConfigTemp4 = configTemp3{i, 2};
                for k = 1 : length(dataConfigTemp4)
                    if(dataConfigTemp4(k) == '{')
                        dataConfigTemp4(k) = '[';
                    end
                    if(dataConfigTemp4(k) == '}')
                        dataConfigTemp4(k) = ']';
                    end
                end
                eval(join(['SensorConfig.' str '=' dataConfigTemp4 ';']));
        end
    end
end

%% Calculation of radar parameters
tmpTx = max(SensorConfig.tx_groups);
% TX发射次序
for iTx = 4 : -1 : 1 
    idxTx = bitget(tmpTx, 1 + ((iTx - 1) * 4));
    if(idxTx)
        break;
    end
end

SensorConfig.nvirtual_chirp = iTx;
SensorConfig.nvirtual_array = SensorConfig.nvirtual_chirp * 4;
if(SensorConfig.dec_factor > 1)
    SensorConfig.adc_sample_num = round((SensorConfig.adc_sample_end - SensorConfig.adc_sample_start) * SensorConfig.adc_freq / SensorConfig.dec_factor) + 1;
else
    SensorConfig.adc_sample_num = round((SensorConfig.adc_sample_end - SensorConfig.adc_sample_start) * SensorConfig.adc_freq / SensorConfig.dec_factor);
end
if(SensorConfig.adc_sample_num > SensorConfig.rng_nfft)
    SensorConfig.adc_sample_num = SensorConfig.rng_nfft;
end

if(SensorConfig.anti_velamb_en)
    SensorConfig.anti_velamb_nchirp = 1;
    
else
    SensorConfig.anti_velamb_nchirp = 0;
end
SensorConfig.nanti_velamb_array = SensorConfig.anti_velamb_nchirp * 4;

SensorConfig.rng_bin_num = SensorConfig.rng_nfft / 2;
SensorConfig.max_dis = 3e8 / 2 * (SensorConfig.adc_freq * 1e6 / 2) / (SensorConfig.fmcw_bandwidth * 1e6 / SensorConfig.fmcw_chirp_rampup * 1e6) / SensorConfig.dec_factor;
SensorConfig.rng_res = 3e8 / 2 / (SensorConfig.fmcw_bandwidth / SensorConfig.fmcw_chirp_rampup * (SensorConfig.adc_sample_end - SensorConfig.adc_sample_start)) / 1e6;
SensorConfig.rng_res_1dfft = SensorConfig.max_dis / SensorConfig.rng_nfft * 2;

SensorConfig.fram_time = SensorConfig.fmcw_chirp_period * SensorConfig.nchirp * 1e-3 + SensorConfig.anti_velamb_nchirp * (SensorConfig.fmcw_chirp_period + SensorConfig.anti_velamb_delay) * SensorConfig.nchirp / SensorConfig.nvirtual_chirp * 1e-3;
SensorConfig.maxV = 0.5 * 3e8 / SensorConfig.fmcw_startfreq / 1e9 * (1 / (SensorConfig.fram_time) / 1e-3) * SensorConfig.nchirp / SensorConfig.nvirtual_chirp;
SensorConfig.V_res = 0.5 * 3e8 / SensorConfig.fmcw_startfreq / 1e9 * (1 / SensorConfig.fram_time / 1e-3);
SensorConfig.V_acu = SensorConfig.maxV / SensorConfig.vel_nfft;

%% Anti_velamb
if(SensorConfig.anti_velamb_en)
    Tr1 = SensorConfig.fmcw_chirp_period + SensorConfig.anti_velamb_delay;
    Tr = SensorConfig.fmcw_chirp_period * (SensorConfig.nvirtual_chirp + 1) + SensorConfig.anti_velamb_delay;
    anti_velamb_gcd = gcd(SensorConfig.fmcw_chirp_period + SensorConfig.anti_velamb_delay, SensorConfig.fmcw_chirp_period * (SensorConfig.nvirtual_chirp + 1) + SensorConfig.anti_velamb_delay);
    SensorConfig.anti_velamb_num = (SensorConfig.fmcw_chirp_period * (SensorConfig.nvirtual_chirp + 1) + SensorConfig.anti_velamb_delay) / anti_velamb_gcd;
    anti_Vel_Amb_phase = zeros(SensorConfig.anti_velamb_num, 1);
    for i = SensorConfig.anti_velamb_qmin : 1 : SensorConfig.anti_velamb_qmin + SensorConfig.anti_velamb_num - 1
        anti_Vel_Amb_phase(i - SensorConfig.anti_velamb_qmin + 1) = i * Tr1 / Tr - round(i * Tr1 / Tr);
    end
    SensorConfig.anti_Vel_Amb_phase = anti_Vel_Amb_phase;
    
else
    SensorConfig.anti_velamb_num = 1;
    SensorConfig.anti_Vel_Amb_phase = 0;
end

%% Cfar para init
% [cfarPra] = cfar_init(SensorConfig);
% SensorConfig.cfarPra = cfarPra;
% 
% %% 根据配置生成导向矢量
% antena_position_all = reshape(SensorConfig.ant_pos, 2, []);
% ant_comps = SensorConfig.ant_comps;
% antena_position = zeros(2, SensorConfig.nvirtual_array);
% antena_phase = zeros(1, SensorConfig.nvirtual_array);
% 
% for k3 = 1:SensorConfig.nvirtual_chirp %发射次序
%     TX_idx = bitget(SensorConfig.tx_groups, 1 + ((k3 - 1) * 4));
%     enable_num = length(find(TX_idx == 1));
%     for k4 = 1:length(TX_idx)
%         if(TX_idx(k4) == 1)
%             antena_position(:, (k3 - 1) * 4 + 1:k3 * 4) = antena_position(:, (k3 - 1) * 4 + 1:k3 * 4)+...
%                 antena_position_all(:, (k4 - 1) * 4 + 1:k4 * 4);
%             antena_phase(:, (k3 - 1) * 4 + 1:k3 * 4) = antena_phase(:, (k3 - 1) * 4 + 1:k3 * 4) +...
%                 ant_comps(:, (k4 - 1) * 4 + 1:k4 * 4);
%         end
%     end
%     antena_position(:, (k3 - 1) * 4 + 1:k3 * 4) = antena_position(:, (k3 - 1) * 4 + 1:k3 * 4) / enable_num;
%     antena_phase(:, (k3 - 1) * 4 + 1:k3 * 4) = antena_phase(:, (k3 - 1) * 4 + 1:k3 * 4) / enable_num;
% 
% end
% 
% SensorConfig.antena_position = antena_position;
% SensorConfig.antena_phase = antena_phase;
% 
% %% Doa para init
% [DOA_par] = doa_init(SensorConfig);
% SensorConfig.DOA_par = DOA_par;

end

