\# CTSAI-A100 室内 / 室外场景与数据采集说明



\## 1. 实验目的



本项目基于 CTSAI-A100 开展室内与室外环境 ADC 数据采集实验，并结合 MATLAB 雷达信号处理和 LFMCW 综合仿真，对不同环境中的距离、多普勒及静态杂波特征进行观察。



实测部分主要包括：



\* ADC TXT 数据解析

\* Range FFT

\* Range-Doppler / 2D-FFT

\* MTI 静态与近静态杂波抑制

\* 室内与室外代表场景结果展示



MATLAB 仿真部分用于进一步分析 LFMCW 目标回波、差频信号、时频特征以及雷达参数变化规律。



\## 2. 实测数据分组



完整实验包含四组数据：



\* `indoor\_case\_01`

\* `indoor\_case\_02`

\* `indoor\_case\_03`

\* `outdoor\_case\_01`



原始采集目录分别为：



\* `adc\_test0806indoor\_20260806132405350`

\* `adc\_test0806indoor01\_20260806134148375`

\* `adc\_test0806indoor02\_20260806140024188`

\* `adc\_test0806outdoor\_20260806142735600`



当前文档使用中性的 `case\_01 / case\_02 / case\_03` 名称表示三组室内实验，不对三组室内数据的具体布置差异作额外假设。



如后续补充实际实验布置，可进一步将三个 case 修改为对应的真实场景名称。



\## 3. 数据采集规模



每个场景完整采集：



\* 20 个 run

\* 每个 run 包含 Rx0-Rx3 四个接收通道

\* 每个场景共 80 个 ADC TXT 文件



因此完整实验数据规模为：



```text

4 scenes × 20 runs × 4 RX

= 320 ADC TXT files

```



完整原始 ADC TXT 数据总量约为 379 MB。



\## 4. 仓库中的代表数据



考虑到完整 ADC 数据体积较大，本 Community Project 不直接提交全部 320 个原始 TXT 文件。



仓库中为每个场景保留 `run\_001`：



```text

data/measured/

├── indoor\_case\_01/

│   └── run\_001\_Pf0\_Rx0\~Rx3.txt

├── indoor\_case\_02/

│   └── run\_001\_Pf0\_Rx0\~Rx3.txt

├── indoor\_case\_03/

│   └── run\_001\_Pf0\_Rx0\~Rx3.txt

└── outdoor\_case\_01/

&#x20;   └── run\_001\_Pf0\_Rx0\~Rx3.txt

```



因此仓库提供：



```text

4 scenes × 1 representative run × 4 RX

= 16 ADC TXT files

```



这些代表数据用于复现项目中的主要 MATLAB 实测信号处理流程。



完整 20-run 数据保留在原始实验数据存储位置，可用于进一步的本地批量分析。



\## 5. ADC 数据规格



仓库中的代表数据已完成格式检查。



所有代表数据均具有：



\* Profile：Pf0

\* Receive channels：Rx0-Rx3

\* Samples per chirp：1024

\* Chirps per frame：256



全部 16 个 TXT 文件均能够由项目 ADC 解析程序正常读取。



每个 TXT 文件在标准 ADC payload 后还存在 1 个 trailer 数值，当前解析程序将该数值作为尾部数据忽略，不影响完整 ADC payload 的读取和解包。



\## 6. 实测雷达配置



本项目使用的 Pf0 配置主要包括：



\* Start frequency：76.3 GHz

\* FMCW bandwidth：300 MHz

\* Chirp ramp-up：43 us

\* Chirp period：48 us

\* ADC frequency：25 MHz

\* Range FFT size：1024

\* Doppler FFT size：256

\* TX mode：SISO



根据当前配置得到：



\* Range resolution：约 0.5245 m/bin

\* Velocity resolution：约 0.1599 m/s/bin

\* 当前处理对应的无模糊速度范围：约 ±20.46 m/s



这些参数用于实测 Range-Doppler 图中的距离和径向速度物理坐标计算。



\## 7. 代表性实测处理



项目默认对四个场景的 `run\_001\_Pf0\_Rx0.txt` 进行代表性处理。



每个场景生成：



\* Range Spectrum

\* Range-Doppler Map Before MTI

\* Range-Doppler Map After MTI2



结果位于：



```text

results/measured/

├── indoor\_case\_01/

├── indoor\_case\_02/

├── indoor\_case\_03/

└── outdoor\_case\_01/

```



\## 8. 室内 / 室外场景分析边界



室内环境通常可能包含墙面、家具及其他固定结构形成的复杂反射和多径。



室外环境具有不同的传播条件和背景杂波组成。



本项目通过实测 Range Spectrum、Range-Doppler 和 MTI 前后结果展示不同环境下的雷达数据特征。



由于当前仓库提供的是各场景的代表性样本，因此这些结果主要用于场景展示和信号处理流程复现，不用于声明统一的 CTSAI-A100 产品检测性能。



MATLAB 仿真结果、CTSAI-A100 实测结果以及产品实际能力在项目文档中分别说明。



