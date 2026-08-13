# CTSAI-A100 ADC 信号处理链路说明

## 1. 目标与适用范围

本工程演示从 CTSAI-A100 ADC 原始导出数据到基础目标距离、径向速度和方位角结果的完整处理流程。工程用于格式理解、算法学习和二次开发，不应将示例输出解释为传感器产品性能承诺。

## 2. ADC TXT 数据格式

随附四个文件分别对应 `Rx0` 到 `Rx3`。每个文件是逗号分隔的一维数值流：

```text
rx_index, samples_per_chirp, chirp_count, packed_word_0, packed_word_1, ...
```

随附 Pf0 数据头为：

```text
Rx0: 0,1024,256,...
Rx1: 1,1024,256,...
Rx2: 2,1024,256,...
Rx3: 3,1024,256,...
```

每个 `packed_word` 是 32 位无符号整数：

- 高 16 位：较早的 ADC 有符号采样；
- 低 16 位：较晚的 ADC 有符号采样；
- 两个 16 位数均按二进制补码解释。

因此每个 RX 的有效打包字数应为：

```text
(samples_per_chirp / 2) × chirp_count
```

随附文件在有效载荷后多出 1 个尾部值。新读取函数会依据头部计算有效长度、忽略尾部并记录数量，不会把头部误当作 ADC 数据。

## 3. 工程结构与运行

`main.m` 是唯一运行入口。它自动添加 `functions/` 路径、加载配置、发现数据文件并依次执行全部算法。

```text
main.m
  ├─ load_ctsaia100_config
  ├─ derive_radar_parameters
  ├─ load_adc_dataset / unpack_uint32_adc
  ├─ range_fft
  ├─ organize_virtual_array（TDM分组 / 显式DDMA解调）
  ├─ suppress_clutter
  ├─ doppler_fft
  ├─ cfar_2d / vi_cfar_map / extract_detections
  ├─ refine_detections_subbin
  ├─ estimate_angles_for_detections
  └─ plot_* / writetable / save
```

运行：

```matlab
cd('<工程目录>')
main
```

算法开关集中在 `config/default_processing_options.m`，无需手工分段执行多个脚本。

## 4. 远波、近波配置使用方式

四份 HXX 配置均由 `load_ctsaia100_config.m` 解析。切换方法：

```matlab
opts.profile_id = 0; % 0、1、2 或 3
```

必须保证 ADC 文件的 profile、采样点数和 chirp 数与 HXX 匹配。

| 配置 | 带宽 | Nrange | Nchirp | 距离栅格 | 最大距离 | 说明 |
|---|---:|---:|---:|---:|---:|---|
| init0 | 300 MHz | 1024 | 256 | 约 0.525 m | 约 268 m | 随附 Pf0 示例；远距、速度范围较大 |
| init1 | 750 MHz | 2048 | 128 | 约 0.255 m | 约 261 m | 长 ramp、较细距离栅格，速度范围较低 |
| init2 | 500 MHz | 1024 | 256 | 约 0.315 m | 约 161 m | 中远距折中 |
| init3 | 2900 MHz | 1024 | 128 | 约 0.055 m | 约 28 m | 近距高分辨率 |

“远波/近波”不是仅由带宽决定，还取决于采样率、斜率、FFT 点数、chirp 周期、发射方式和实际射频配置。上表是依据随附参数得到的工程用途解释。

## 5. 数据维度

读取后：

```text
adcRxCube(sample, raw_chirp, rx)
```

单 TX 配置下，处理立方体保持：

```text
adcCube(sample, slow_time_chirp, channel)
```

TDM-MIMO 配置下，Range FFT 后的复数数据由 `organize_virtual_array.m` 按 `block` 或 `interleaved` 方式拆分 chirp group，再按物理 TX×RX 展开虚拟通道。

显式 DDMA 配置下，同一 group 内的多个 TX 会按配置给出的逐 chirp 相位增量解调；若同时发射但配置未给出 DDMA/BPM 编码，程序会停止而不是猜测。

随附四个 profile 均为单 TX、4 RX。Pf0/Pf2 使用物理 TX3，对应 `ant_pos`/`ant_comps` 第 9–12 项；Pf1/Pf3 使用物理 TX1，对应第 1–4 项。

## 6. Range FFT 原理

FMCW 拍频近似满足：

```text
fb = 2 × slope × R / c
```

距离 FFT 将快时间采样变换到拍频域。距离栅格为：

```text
ΔR = c × fs / (2 × slope × NrangeFFT)
```

实现步骤：

1. 使用配置中的有效 ADC 采样区间；
2. 可选去除每个 chirp 的 ADC 均值；
3. 加 Hann/Hamming/矩形窗；
4. 做 `rng_nfft` 点 FFT；
5. 仅保留正频率半谱；
6. 对 chirp 和通道做非相干积累得到距离谱。

## 7. 杂波抑制

Range FFT 和 MIMO/TDM/DDMA组织后、Doppler FFT 前增加独立杂波处理阶段，输入输出均为：

```text
rangeCube(range, slow_time_chirp, virtual_channel)
```

支持以下模式：

- `NONE`：不抑制，用于基线；
- `MEAN`：逐距离和通道去除慢时间均值；
- `MTI2`：二脉冲抵消；
- `MTI3`：三脉冲抵消；
- `SVD`：将 `range × channel` 合并为观测维，删除慢时间矩阵的前若干低秩分量；
- `SVD_MEAN`、`SVD_MTI2`：组合处理。

默认使用 `SVD`、删除 1 个奇异分量。`clutter_suppression_comparison.png` 对比处理前后的 Range-Doppler Map，`processing_result.mat` 保存奇异值、删除秩、删除能量比例和零多普勒抑制度。秩数过高可能同时删除慢速目标。

## 7.1 DDMA 严格处理边界

本工程不会把 `tx_phase_value`、相位扰码或 chirp shifting 自动解释成 DDMA。只有 HXX 明确提供 `ddma_phase_increment_deg`（或等价 Doppler offset）时才启用 DDMA解调。当前随附配置没有这些字段，也没有同时启用多个 TX，因此严格模式为 SISO。详见 `DDMA_MIMO_REPAIR.md`。

## 8. Doppler FFT 原理

同一距离单元随 chirp 的相位变化包含径向速度。慢时间 FFT 后，速度栅格为：

```text
Δv = λ / (2 × T_same_tx × NdopplerFFT)
```

工程对 Doppler 维加窗、FFT，再使用 `fftshift`，因此速度轴包含负速度和正速度。正负号取决于雷达的相位和坐标约定，应通过已知运动方向标定。

## 9. CFAR 检测

### 9.1 CA-CFAR

CA-CFAR 对 CUT 周围训练单元取均值：

```text
noise = mean(training cells)
threshold = alpha × noise
alpha = N × (Pfa^(-1/N) - 1)
```

默认训练单元为 `[3,6]`、保护单元为 `[1,2]`，主要是为了让随附示例中靠近雷达的目标也能进入有效 CFAR 区域。

### 9.2 OS-CFAR

OS-CFAR 对训练样本排序并选择第 `k` 个次序统计量，适合训练窗内含有干扰目标的情况。工程通过指数噪声假设下的 Pfa 方程数值求解阈值倍率。OS-CFAR 逐 CUT 排序，运行速度明显慢于默认 CA-CFAR。


### 9.3 GOCA-CFAR 与 SOCA-CFAR

训练环被划分为四个互不重叠扇区。GOCA 取扇区均值最大值，适合杂波边缘的保守检测；SOCA 取最小值，对弱目标更灵敏但更容易产生边缘虚警。

### 9.4 二维 VI-CFAR

VI-CFAR 为每个扇区计算 `variance/mean^2` 和扇区最大/最小均值比。工程按局部均匀性自动选择：

- `CA`：训练环整体均匀；
- `GOCA`：出现明显杂波边缘；
- `VI_SELECTED`：只积累未被目标或干扰污染的均匀扇区；
- `GOCA_FALLBACK`：没有可信扇区时保守回退。

`cfar_diagnostics.png` 展示变异指数和分支图，`detections.csv` 的 `CFARMethod` 保存每个检测点实际使用的分支。

### 9.5 检测点整理

CFAR 掩码还会经过：

- 距离范围筛选；
- 零多普勒附近可选排除；
- 二维局部峰值筛选；
- 距离/速度最小间隔抑制；
- 最低 SNR 门限、按 SNR 排序和数量限制。


## 10. 亚栅格距离与速度估计

整数 FFT 峰值附近提取 3×3 对数功率邻域，拟合带交叉项的二维二次曲面：

```text
z = aΔr² + bΔd² + cΔrΔd + dΔr + eΔd + f
```

利用 Hessian 和梯度计算峰值小数偏移。仅当 Hessian 为负定、条件数合理且偏移位于 ±0.5 bin 内时接受二维解，否则回退到两个方向的一维抛物线插值。

输出保留粗估计 `Range_m`、`Velocity_mps`，并新增 `RangeRefined_m`、`VelocityRefined_mps`、偏移、拟合 R² 和有效性标志。亚栅格估计提高的是离散峰值位置估计精度，并不等于突破雷达物理分辨率。

## 11. 角度估计

阵列导向矢量使用配置中的 `ant_pos`（以波长为单位）和 `ant_comps` 相位标定。

### 11.1 Angle FFT

将非均匀阵列采样映射到 0.5 波长栅格，缺失阵元补零后做空间 FFT。该方法快速，但对非均匀阵列、栅格映射和旁瓣敏感。

### 11.2 DML

单源 DML 在角度网格上拟合：

```text
x ≈ a(theta) × s
```

选择残差最小的角度。单目标、单快拍条件下，其峰值与常规波束形成接近。

### 11.3 MUSIC

MUSIC 使用检测点周围小型 Range-Doppler 邻域作为多个快拍，构造协方差矩阵并分解信号/噪声子空间。当前默认信号数为 1，并使用对角加载增强数值稳定性。

### 11.4 OMP

OMP 把角度导向矢量组成字典，逐次选择与残差相关性最大的原子。默认只恢复 1 个角度；可提高 `omp_max_sources`，但四通道条件下不宜估计过多源。

## 12. 输出解释

`detections.csv` 包含：

- `Range_m`、`Velocity_mps`：整数 FFT 栅格的粗估计；
- `RangeRefined_m`、`VelocityRefined_mps`：二维亚栅格精修结果；
- `RangeOffset_bin`、`DopplerOffset_bin`：小数栅格偏移；
- `Power_dB`、`Noise_dB`、`Threshold_dB`、`SNR_dB`；
- `CFARMethod`、`VariabilityIndex`、`SectorMeanRatio`；
- `AngleFFT_deg`、`DML_deg`、`MUSIC_deg`、`OMP_deg`；
- `SelectedAngle_deg`：配置指定的最终角度。

点云坐标使用：

```text
x = refined_range × sin(angle)
y = refined_range × cos(angle)
z = refined_radial_velocity
```
