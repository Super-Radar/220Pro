---
doc_id: "2064911496346779648"
title: "ADC数据采集"
parent_id: "2064910734866694144"
sort: 3
content_type: 1
---


ADC 数据是雷达信号处理链路中的底层数据，适合用于 FFT、滤波、检测、微多普勒分析、特征提取等研究。

### 启动 ADC 采集

ADC 数据采集通过 RadarTools 完成。

操作流程：

1. 连接雷达并完成上位机配置。
2. 点击 `Start`，确认雷达数据流正常输出。
3. 在 RadarTools 中点击 `ADC采集` 按钮。
4. 进入 ADC 采集界面。
5. 按实验需求配置采集参数。
6. 点击开始采集。
7. 等待采集完成后，检查输出文件。

###  ADC 采集参数

ADC 采集界面中通常包含以下配置项：

| 配置项       | 说明           |
| --------- | ------------ |
| FrameType | 波形类型 / 帧类型   |
| RxCh      | 接收通道选择       |
| Sample    | 每 chirp 采样点数 |
| Chirp_N   | chirp 数量     |
| 文件名       | 当前采集文件名称     |
| 目标目录      | ADC 数据保存目录   |
| DataType  | 数据类型         |

不同波形对应的 ADC 数据需要使用对应配置文件进行后续解析。

###  ADC 数据保存目录

ADC 数据采集完成后，数据文件默认保存至：

```text
tools/RadarTools_Release/adcData/
```

采集完成后，请确认该目录下已生成对应数据文件。

示例目录结构：

```text
tools/RadarTools_Release/adcData/
├── adc_rx0.txt
├── adc_rx1.txt
├── adc_rx2.txt
└── adc_rx3.txt
```

实际文件名以采集工具生成结果为准。
