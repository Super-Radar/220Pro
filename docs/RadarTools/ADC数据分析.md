---
doc_id: "2064911668388741120"
title: "ADC数据分析"
parent_id: "2064910734866694144"
sort: 4
content_type: 1
---

本节用于说明如何基于示例工程读取和分析 CTSAI-A100 ADC 数据。

### Matlab 示例工程目录

Matlab 示例工程位于：

```text
ADC数据采集/matlab_signal_processing_platform_231023_for_txt_A100/
```

示例工程中包含 CTSAI-A100 ADC 数据处理入口脚本：

```text
ct_signal_processing_main_simple_CTASIA100.m
```

### 选择波形配置文件

打开以下文件：

```text
ADC数据采集/matlab_signal_processing_platform_231023_for_txt_A100/ct_signal_processing_main_simple_CTASIA100.m
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
    '.\cfg\CTASI-A100配置\sensor_config_init0.hxx'
};
```

### 拷贝 ADC 数据

将 RadarTools 采集到的 ADC 数据文件或完整会话目录从以下位置：

```text
RadarTools/RadarTools_Release/adcData/
```

拷贝到 Matlab 示例工程的数据目录：

```text
ADC数据采集/matlab_signal_processing_platform_231023_for_txt_A100/data/
```

若数据包含多个接收通道，请确保所有通道文件均已拷贝完整。会话目录中的 `Pf0` 表示 profile，`Rx0`～`Rx3` 表示接收通道。

### 配置数据路径和文件名

在 `ct_signal_processing_main_simple_CTASIA100.m` 中配置 ADC 数据所在目录：

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

### ADC 文件头与长度校验

示例工程兼容两种 RadarTools 导出格式：

```text
旧版平铺格式：<ADC samples>,0
会话目录格式：<Rx>,<Sample>,<Chirp_N>,<ADC samples>,0
```

会话目录格式开头的三项依次为接收通道、每 chirp 采样点数和 chirp 数量，不属于 ADC 样本。`load_adc_data.m` 会调用 `read_adc_capture_file.m` 自动移除文件头和可选的末尾零值，并检查文件头是否与所选波形配置一致。

当文件长度不正确，或文件头中的 `Sample`、`Chirp_N` 与配置不一致时，程序会停止并报告错误。此时应核对采集 profile、配置文件和数据文件，不能通过补零或截断继续处理，否则会造成整个采样序列错位。

### 运行 Matlab 处理脚本

在 Matlab 中运行：

```matlab
ct_signal_processing_main_simple_CTASIA100
```

运行后，可根据示例工程输出查看处理结果。

该流程适合用于：

* ADC 数据读取
* 波形参数加载
* 距离向处理
* 速度向处理
* 基础目标检测
* 雷达信号处理流程验证
