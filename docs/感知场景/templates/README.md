# 室内出入口采集记录模板

本目录保存室内出入口场景的空白记录模板。模板不是实测数据，开始采集前应复制一份再填写，原文件保留用于复现字段结构。

## 文件

- `indoor-entryway-site.csv`：记录一批实验共享的场地尺寸、安装参数和软件版本；
- `indoor-entryway-captures.csv`：每行对应一次连续采集，预置 S0～S6 各三次记录。

两张表通过 `environment_id` 关联。`record_id` 在本批数据内必须唯一，建议沿用 `S3-R02` 形式，其中前半部分为场景编号，后半部分为重复序号。

## 新建一次采集会话

建议在仓库外建立独立数据目录。以下命令会复制两张空白模板并生成一份现场提示，不会扫描或复制已有雷达数据：

```bash
python "docs/感知场景/scripts/prepare_entryway_session.py" --output "D:/A100-data/entryway-YYYYMMDD" --environment-id E01
```

`--output` 必须指向不存在或为空的目录。只要目录中已有文件，脚本就会退出，不会覆盖原记录。`--environment-id` 可替换为本次场地编号，只允许使用字母、数字、点、下划线和连字符。

## 填写规则

- `capture_date` 使用 `YYYY-MM-DD`；`start_time` 使用带时区的 ISO 8601 时间，例如 `YYYY-MM-DDThh:mm:ss+08:00`；
- 距离和尺寸统一使用米，角度统一使用度，时长统一使用秒；未知值保持为空，不使用 `0` 代替；
- `participant_id` 只填写匿名编号，不记录姓名、学号或联系方式；
- `data_types` 可填写 `point_cloud`、`target`、`can`、`adc`，同次采集包含多种数据时使用分号分隔；
- 配置、数据和人工真值文件使用相对于数据集根目录的路径，统一使用 `/`；多个文件可使用分号分隔；
- `privacy_checked` 仅在确认文件不含未授权人脸、姓名、门牌等信息后填写 `true`；
- 采集中断、人员动作偏离、临时遮挡或雷达移动等情况写入 `notes`，不删除失败记录。

## 动作标签

| 场景 | `action_label` | 含义 |
|---|---|---|
| S0 | `empty` | 空场基线 |
| S1 | `approach` | 由远端向雷达靠近 |
| S2 | `recede` | 由近端向远端离开 |
| S3 | `stationary` | 在固定位置静止 |
| S4 | `stop_continue` | 运动、停留后继续运动 |
| S5 | `lateral_pass` | 横向经过但不进入 |
| S6 | `turn_back` | 靠近参考线后折返 |

`reference_distance_m` 表示本次动作对应的人工参考点：S3 填静止位置，S4 填停留位置，S5 填最近点，S6 填折返点；不适用时留空。场地固定的近端和远端距离应填写在场地表中。
