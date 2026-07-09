---
doc_id: "2075059413825564672"
title: "ADC数据分析"
parent_id: "2064910734866694144"
sort: 9
content_type: 1
---

本节用于说明如何基于示例工程读取和分析 CTSAI-A100 ADC 数据。

### Matlab 示例工程目录

Matlab 示例工程位于：

```text
examples/matlab-adc-processing/
```

示例工程中包含 CTSAI-A100 ADC 数据处理入口脚本：

```text
ct_signal_processing_main_simple_CTSAIA100.m
```

### 选择波形配置文件

打开以下文件：

```text
examples/matlab-adc-processing/ct_signal_processing_main_simple_CTSAIA100.m
```

根据采集时使用的波形选择对应配置文件。

远波 ADC 数据使用：

```text
sensor_config_init0.hxx
```

近波 ADC 数据使用：

```text
sensor_config_init1.hxx
```

配置示例：

```matlab
cell_cfg_file_path = {
    '.\cfg\CTSAIA100配置\sensor_config_init0.hxx'
};
```

### 拷贝 ADC 数据

将 RadarTools 采集到的 ADC 数据文件从以下目录：

```text
tools/RadarTools_Release/adcData/
```

拷贝到 Matlab 示例工程的数据目录：

```text
examples/matlab-adc-processing/data/
```

若数据包含多个接收通道，请确保所有通道文件均已拷贝完整。

### 配置数据路径和文件名

在 `ct_signal_processing_main_simple_CTSAIA100.m` 中配置 ADC 数据所在目录：

```matlab
cell_data_file_path = {
    '.\data\'
};
```

配置接收通道对应的数据文件名：

```matlab
cell_data_file_name_list = {
    'adc_rx0.txt'
    'adc_rx1.txt'
    'adc_rx2.txt'
    'adc_rx3.txt'
};
```

文件名需与 `data/` 目录中的实际文件保持一致。

### 运行 Matlab 处理脚本

在 Matlab 中运行：

```matlab
ct_signal_processing_main_simple_CTSAIA100
```

运行后，可根据示例工程输出查看处理结果。

该流程适合用于：

* ADC 数据读取
* 波形参数加载
* 距离向处理
* 速度向处理
* 基础目标检测
* 雷达信号处理流程验证