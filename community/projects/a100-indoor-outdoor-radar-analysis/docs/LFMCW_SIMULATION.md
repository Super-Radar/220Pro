# MATLAB LFMCW 综合仿真与参数实验



## 1. 仿真目的



本项目使用 MATLAB 建立 LFMCW 雷达综合仿真，用于展示雷达发射信号、目标回波、差频信号、时频特征、Range-Doppler / 2D-FFT 和 MTI 处理过程。



仿真部分独立于 CTSAI-A100 实测 ADC 数据，可在已知目标距离、径向速度和目标数量的情况下观察不同参数对雷达结果的影响。



## 2. 基础仿真参数



默认参数为：



* Carrier frequency：76.3 GHz

* FMCW bandwidth：300 MHz

* Chirp duration：43 us

* Chirp period：48 us

* ADC sample rate：25 MHz

* Samples per chirp：1024

* Chirps per frame：256



默认运动目标：



* Initial range：30 m

* Radial velocity：-5 m/s



仿真速度符号约定：



```text

v < 0 : approaching

v > 0 : receding

```



该符号约定用于本项目 MATLAB 仿真。



## 3. LFMCW 信号链



仿真信号处理流程：



```text

LFMCW transmitted chirp

        ↓

Propagation delay

        ↓

Moving-target Doppler

        ↓

Target echo

        ↓

Dechirp

        ↓

Beat signal

        ↓

Range FFT

        ↓

Doppler FFT

        ↓

Range-Doppler Map

```



## 4. 发射信号、回波与差频信号



项目输出：



* `lfmcw_tx_waveform.png`

* `lfmcw_target_echo.png`

* `lfmcw_beat_signal.png`

* `lfmcw_tx_spectrogram.png`



其中时频图用于展示 LFM chirp 的频率随时间变化特征。



## 5. Range-Doppler / 2D-FFT



仿真 beat signal 首先沿 fast-time 方向进行 Range FFT，再沿 slow-time chirp 方向进行 Doppler FFT。



结果包括：



* `simulation_range_doppler_before_mti.png`

* `simulation_range_doppler_after_mti.png`



仿真中同时加入静态反射体和噪声，以展示运动目标和零 Doppler 静态背景。



## 6. MTI



项目使用差分型 MTI 抑制 slow-time 中变化较小的静态和近静态分量。



MTI2：



```text

y[n] = x[n] - x[n-1]

```



MTI3：



```text

y[n] = x[n] - 2x[n-1] + x[n-2]

```



参数实验进一步比较：



* Before MTI

* MTI2

* MTI3



## 7. LFM 频宽实验



比较：



* 150 MHz

* 300 MHz

* 450 MHz



理论距离分辨率满足：



```text

ΔR = c / (2B)

```



带宽增加时，理论距离分辨能力提高。



结果：



`parameter_study/bandwidth_study.png`



## 8. LFM 时宽实验



保持 bandwidth 不变，改变 chirp duration。



由于：



```text

chirp slope = bandwidth / chirp duration

```



时宽变化会改变 chirp slope，从而改变同一目标距离对应的 beat frequency。



结果：



`parameter_study/chirp_duration_study.png`



## 9. Chirp Period / PRF 实验



不同 chirp period 对应不同 slow-time 采样周期和 PRF。



因此会影响 Doppler 采样以及无模糊速度范围。



结果：



`parameter_study/prf_study.png`



## 10. 目标数量实验



分别模拟：



* 1 个目标

* 2 个目标

* 3 个目标



目标被设置在不同的距离和径向速度位置。



随着目标数量增加，Range-Doppler 平面中可以观察到多个目标响应。



结果：



`parameter_study/target_number_study.png`



## 11. 目标速度实验



比较：



* -2 m/s

* -5 m/s

* -10 m/s



目标径向速度变化会使目标响应沿 Doppler / velocity 维发生移动。



结果：



`parameter_study/target_velocity_study.png`



## 12. MTI 阶数实验



比较：



* Before MTI

* MTI2

* MTI3



结果：



`parameter_study/mti_order_study.png`



差分型 MTI 能够明显削弱零 Doppler 附近的静态杂波。



MTI3 的近零 Doppler 抑制作用通常更加明显，同时其滤波作用也更加激进。



## 13. 结果使用边界



参数实验用于展示 MATLAB LFMCW 理想化模型中的基本雷达信号处理规律。



仿真使用简化目标模型、可控噪声和人工设置的静态反射体。



因此仿真结果不能直接解释为 CTSAI-A100 在真实室内或室外环境中的最终产品性能指标。



实测结果与仿真结果的差异在 `SIMULATION_VS_MEASUREMENT.md` 中单独说明。



