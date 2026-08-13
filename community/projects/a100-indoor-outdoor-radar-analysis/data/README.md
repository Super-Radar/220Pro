# CTSAI-A100 Indoor / Outdoor ADC Dataset



## Dataset Overview



本项目使用 CTSAI-A100 采集室内和室外场景 ADC TXT 数据。



完整实验共包含四组数据：



* `indoor_case_01`

* `indoor_case_02`

* `indoor_case_03`

* `outdoor_case_01`



每组实验实际采集 20 个 run，每个 run 包含 Rx0-Rx3 四个接收通道。



因此完整原始数据包含：



* 20 runs / scene

* 4 RX files / run

* 80 TXT files / scene

* 4 scenes

* 共 320 个 ADC TXT 文件



完整原始数据总量约为 379 MB。



## Repository Sample Data



考虑到完整原始 ADC 数据量较大，本 Community Project 不直接提交全部 320 个 TXT 文件。



仓库中为每个场景提供 `run_001` 作为可复现实验的代表样本：



```text

measured/

├── indoor_case_01/

│   └── run_001_Pf0_Rx0~Rx3.txt

├── indoor_case_02/

│   └── run_001_Pf0_Rx0~Rx3.txt

├── indoor_case_03/

│   └── run_001_Pf0_Rx0~Rx3.txt

└── outdoor_case_01/

    └── run_001_Pf0_Rx0~Rx3.txt

```



仓库共包含 16 个代表性 ADC TXT 文件。



完整 20-run 数据集保留在原始实验数据存储位置，用于本地批量分析；仓库中的代表数据足以运行项目主要 MATLAB 信号处理和结果复现实验。



## Data Format



每个 run 包含：



* `Rx0`

* `Rx1`

* `Rx2`

* `Rx3`



数据格式为 CTSAI-A100 ADC TXT。



具体 ADC 解析由项目 `functions/common/` 下的 MATLAB 函数完成。



## Using Your Own Data



如需使用自己的 CTSAI-A100 ADC 数据：



1. 按照相同格式准备 Rx0-Rx3 ADC TXT 文件；

2. 将数据放入对应场景目录；

3. 确认 `config/sensor_config_init0.hxx` 与实际采集配置一致；

4. 运行项目 `main.m` 或对应测试脚本。



## Full Dataset Note



完整实验数据没有全部提交到 Git 仓库，主要原因是原始 ADC TXT 数据总量约 379 MB。



项目 README 和实验文档会明确区分：



* 完整实验采集规模；

* 仓库中提供的代表性可复现数据；

* 基于代表数据生成的示例结果。



