# CTSAI-A100 MATLAB ADC Signal Processing Example

本工程将 CTSAI-A100 ADC 采集工具导出的 TXT 数据处理为距离、速度和角度检测结果，提供统一入口、模块化函数、结果图像和说明文档。

## 快速运行

1. 使用 MATLAB 打开工程根目录。
2. 确认 `config/default_processing_options.m` 中 `opts.profile_id = 0`。
3. 运行：

```matlab
main
```

输出保存到 `results/`：

- `adc_overview.png`
- `range_spectrum.png`
- `range_doppler_map.png`
- `cfar_detections.png`
- `angle_spectra.png`
- `target_point_cloud.png`
- `detections.csv`
- `processing_result.mat`

## 工程结构

```text
ctsaia100_matlab_signal_processing/
├── main.m
├── config/
│   ├── default_processing_options.m
│   └── sensor_config_init0.hxx ... sensor_config_init3.hxx
├── data/
├── functions/
├── results/
├── docs/
└── README.md
```

## 配置选择

| Profile | 带宽 | FFT / chirp | 距离栅格（约） | 最大距离（约） | 典型用途 |
|---|---:|---:|---:|---:|---|
| init0 / Pf0 | 300 MHz | 1024 / 256 | 0.525 m | 268 m | 远距、较高速度范围；随附数据使用此配置 |
| init1 / Pf1 | 750 MHz | 2048 / 128 | 0.255 m | 261 m | 较长 chirp、较细距离栅格 |
| init2 / Pf2 | 500 MHz | 1024 / 256 | 0.315 m | 161 m | 中远距折中 |
| init3 / Pf3 | 2900 MHz | 1024 / 128 | 0.055 m | 28 m | 近距高距离分辨率 |

切换 profile 时，必须同时提供匹配该 profile 的 ADC 数据。随附 TXT 的头部为 `Rx,1024,256`，与 `init0` 匹配。

## 算法

- ADC：32 位无符号字拆成高 16 位、低 16 位两个有符号采样。
- 数据立方体：`[sample, slow-time chirp, virtual channel]`。
- Range FFT：距离维加窗、FFT、保留正频率半谱。
- Doppler FFT：慢时间加窗、FFT、`fftshift` 得到正负径向速度。
- 检测：支持二维 CA-CFAR 和 OS-CFAR；默认 CA-CFAR。
- 角度：对每个检测点同时计算 Angle FFT、DML、MUSIC 和 OMP。

完整说明见 [docs/CTSAIA100_SIGNAL_PROCESSING_GUIDE.md](docs/CTSAIA100_SIGNAL_PROCESSING_GUIDE.md)，验证记录见 [docs/VALIDATION.md](docs/VALIDATION.md)。

## 依赖和限制

代码优先使用 MATLAB 基础函数；Chebyshev 窗仅在 `chebwin` 可用时启用。当前示例是教学和二次开发起点，不构成产品性能承诺。四通道、非均匀阵列和有限快拍会限制角度分辨率，MUSIC/DML/OMP 结果需要结合真实阵列标定验证。
