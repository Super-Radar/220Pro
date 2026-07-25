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
  ├─ organize_virtual_array
  ├─ range_fft
  ├─ doppler_fft
  ├─ cfar_2d / extract_detections
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

TDM-MIMO 配置下，`organize_virtual_array.m` 按 `block` 或 `interleaved` 方式把 TX 维展开为虚拟通道：

```text
virtual_channel = tx_index × rx_count + rx_index
```

随附 profile 0 为单 TX、4 RX，因此最终角度通道数为 4。

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

## 7. Doppler FFT 原理

同一距离单元随 chirp 的相位变化包含径向速度。慢时间 FFT 后，速度栅格为：

```text
Δv = λ / (2 × T_same_tx × NdopplerFFT)
```

工程对 Doppler 维加窗、FFT，再使用 `fftshift`，因此速度轴包含负速度和正速度。正负号取决于雷达的相位和坐标约定，应通过已知运动方向标定。

## 8. CFAR 检测

### 8.1 CA-CFAR

CA-CFAR 对 CUT 周围训练单元取均值：

```text
noise = mean(training cells)
threshold = alpha × noise
alpha = N × (Pfa^(-1/N) - 1)
```

默认训练单元为 `[3,6]`、保护单元为 `[1,2]`，主要是为了让随附示例中靠近雷达的目标也能进入有效 CFAR 区域。

### 8.2 OS-CFAR

OS-CFAR 对训练样本排序并选择第 `k` 个次序统计量，适合训练窗内含有干扰目标的情况。工程通过指数噪声假设下的 Pfa 方程数值求解阈值倍率。OS-CFAR 逐 CUT 排序，运行速度明显慢于默认 CA-CFAR。

### 8.3 检测点整理

CFAR 掩码还会经过：

- 距离范围筛选；
- 零多普勒附近可选排除；
- 二维局部峰值筛选；
- 距离/速度最小间隔抑制；
- 最低 SNR 门限、按 SNR 排序和数量限制。

## 9. 角度估计

阵列导向矢量使用配置中的 `ant_pos`（以波长为单位）和 `ant_comps` 相位标定。

### 9.1 Angle FFT

将非均匀阵列采样映射到 0.5 波长栅格，缺失阵元补零后做空间 FFT。该方法快速，但对非均匀阵列、栅格映射和旁瓣敏感。

### 9.2 DML

单源 DML 在角度网格上拟合：

```text
x ≈ a(theta) × s
```

选择残差最小的角度。单目标、单快拍条件下，其峰值与常规波束形成接近。

### 9.3 MUSIC

MUSIC 使用检测点周围小型 Range-Doppler 邻域作为多个快拍，构造协方差矩阵并分解信号/噪声子空间。当前默认信号数为 1，并使用对角加载增强数值稳定性。

### 9.4 OMP

OMP 把角度导向矢量组成字典，逐次选择与残差相关性最大的原子。默认只恢复 1 个角度；可提高 `omp_max_sources`，但四通道条件下不宜估计过多源。

## 10. 输出解释

`detections.csv` 包含：

- `Range_m`：目标距离；
- `Velocity_mps`：带符号径向速度；
- `Power_dB`、`Noise_dB`、`SNR_dB`；
- `AngleFFT_deg`、`DML_deg`、`MUSIC_deg`、`OMP_deg`；
- `SelectedAngle_deg`：配置指定的最终角度。

点云坐标使用：

```text
x = range × sin(angle)
y = range × cos(angle)
z = radial velocity
```

## 11. 当前限制

1. 角度估计只有 4 个接收通道，阵列非均匀且相位标定可能随硬件变化，分辨率和歧义必须实测验证。
2. 当前 DML 是单源网格搜索；未实现完整多目标联合 DML。
3. MUSIC 快拍取自邻近 RD 单元，强多目标或扩展目标会违反单源假设。
4. 未包含 BPM 解码、相位扰码、频率跳变、抗干扰、速度解模糊和目标跟踪。
5. CFAR 参数是示例默认值，不是任何场景下的产品参数。
6. 速度正负方向、天线坐标和相位补偿符号需用已知目标完成系统级标定。

## 12. 后续扩展

- 增加 profile 1/2/3 的公开 ADC 数据与回归测试；
- 支持多帧输入、帧间积累和跟踪；
- 增加二维/三维阵列的方位角与俯仰角联合估计；
- 增加 Capon、ESPRIT、二维 MUSIC 和多源 DML；
- 增加恒虚警参数自动化评估和检测性能统计；
- 加入真实标定文件、通道幅相均衡和近场波束模型；
- 增加 MATLAB Unit Test 和 CI 自动运行。
