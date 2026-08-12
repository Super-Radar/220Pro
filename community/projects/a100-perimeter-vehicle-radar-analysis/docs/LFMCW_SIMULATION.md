# MATLAB LFMCW 综合仿真与参数分析



## 1. 仿真目的



本项目使用 MATLAB 建立 LFMCW 雷达综合仿真，用于分析车辆周界感知场景中的目标回波、差频信号、Range-Doppler 处理以及 MTI 静态杂波抑制过程。



仿真与 CTSAI-A100 实测数据分析相互独立。



仿真部分允许目标以已知距离和径向速度连续运动，因此适合研究实际离散采集数据难以完整展示的车辆运动和参数变化规律。



## 2. 基础雷达参数



基础仿真参数设置为：



* Carrier frequency：76.3 GHz

* FMCW bandwidth：300 MHz

* Chirp duration：43 us

* Chirp period：48 us

* ADC sample rate：25 MHz

* Samples per chirp：1024

* Chirps per frame：256



默认运动目标设置为：



* Initial range：30 m

* Radial velocity：-5 m/s



仿真中的速度符号约定为：



* `v < 0`：目标靠近雷达

* `v > 0`：目标远离雷达



该符号约定仅用于本项目 MATLAB 仿真。



## 3. LFMCW 信号仿真



项目生成复基带 LFM chirp，并模拟目标传播时延和径向运动产生的 Doppler 相位变化。



主要处理过程为：



```text

LFMCW transmitted chirp

        ↓

Propagation delay + Doppler

        ↓

Target echo

        ↓

Dechirp

        ↓

Beat signal

```



仿真结果包括：



* `lfmcw_tx_waveform.png`

* `lfmcw_target_echo.png`

* `lfmcw_beat_signal.png`

* `lfmcw_tx_spectrogram.png`



时频图用于展示 LFM chirp 的频率随时间变化特征。



## 4. Range-Doppler / 2D-FFT



对模拟 beat signal 进行两维 FFT：



1. fast-time 方向进行 Range FFT；

2. slow-time chirp 方向进行 Doppler FFT。



最终形成 Range-Doppler Map。



项目输出：



* `simulation_range_doppler_before_mti.png`

* `simulation_range_doppler_after_mti.png`



仿真中加入多个静态反射体，用于形成零 Doppler 附近的静态杂波。



## 5. MTI



项目实现二脉冲和三脉冲差分型 MTI。



MTI2：



```text

y[n] = x[n] - x[n-1]

```



MTI3：



```text

y[n] = x[n] - 2x[n-1] + x[n-2]

```



MTI 可以明显削弱 slow-time 中变化较小的静态或近静态分量。



参数实验同时展示：



* Before MTI

* MTI2

* MTI3



三个处理结果。



## 6. LFM 频宽影响



项目比较：



* 150 MHz

* 300 MHz

* 450 MHz



带宽实验使用两个距离接近的目标。



理论距离分辨能力与带宽近似满足：



```text

ΔR = c / (2B)

```



因此带宽增加时，距离分辨能力提高，相邻目标更容易在距离维上区分。



结果：



`parameter_study/bandwidth_study.png`



## 7. LFM 时宽影响



在频宽保持不变时改变 chirp duration。



由于：



```text

chirp slope = bandwidth / chirp duration

```



因此时宽发生变化时，chirp slope 发生变化，相同距离目标产生的 beat frequency 也随之改变。



结果：



`parameter_study/chirp_duration_study.png`



## 8. 重频 / Chirp Period 影响



项目比较不同 chirp period。



Chirp period 决定 slow-time 采样周期，也决定 PRF，因此会影响 Doppler 采样和无模糊速度范围。



结果：



`parameter_study/prf_study.png`



## 9. 目标数量影响



项目分别模拟：



* 1 个目标

* 2 个目标

* 3 个目标



不同目标设置不同的距离和径向速度。



随着目标数量增加，Range-Doppler 平面可以观察到多个不同距离和速度位置的目标响应。



结果：



`parameter_study/target_number_study.png`



## 10. 目标速度影响



项目比较：



* -2 m/s

* -5 m/s

* -10 m/s



随着径向速度变化，目标在 Range-Doppler 图中的 Doppler / velocity 位置发生变化。



结果：



`parameter_study/target_velocity_study.png`



## 11. MTI 阶数影响



项目比较：



* Before MTI

* MTI2

* MTI3



结果表明差分型 MTI 能够削弱零 Doppler 附近的静态杂波。



MTI3 对近零 Doppler 分量的抑制比 MTI2 更强，但其滤波作用也更加明显。



结果：



`parameter_study/mti_order_study.png`



## 12. 结果说明



本节参数实验用于说明 LFMCW 雷达信号处理中的一般变化规律。



这些结果来自 MATLAB 理想化仿真环境，不能直接等同于 CTSAI-A100 在真实环境中的最终检测性能。



CTSAI-A100 实测数据分析和仿真结果的差异在 `SIMULATION_VS_MEASUREMENT.md` 中单独说明。
