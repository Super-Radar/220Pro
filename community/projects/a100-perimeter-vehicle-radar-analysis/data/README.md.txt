# CTSAI-A100 实测 ADC 数据说明

本目录保存车辆周界感知实验中使用的 CTSAI-A100 实测 ADC TXT 数据，以及对应的数据文件列表和校验信息。

## 1. 数据内容

本项目包含三类实测场景：

- 空环境（`empty`）
- 车辆靠近雷达（`vehicle_approaching`）
- 车辆远离雷达（`vehicle_receding`）

共包含 44 个 ADC TXT 文件：

- 空环境：1 个 acquisition run，Rx0-Rx3，共 4 个文件
- 车辆靠近：5 个 acquisition runs，每个 run 包含 Rx0-Rx3，共 20 个文件
- 车辆远离：5 个 acquisition runs，每个 run 包含 Rx0-Rx3，共 20 个文件

## 2. 目录结构

```text
data/
├── README.md
├── SHA256SUMS.txt
├── measured_files.txt
└── measured/
    ├── empty/
    ├── vehicle_approaching/
    └── vehicle_receding/