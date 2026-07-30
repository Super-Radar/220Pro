# DDMA-MIMO 配置审计与修复说明

## 1. 当前工程实际配置模式

四份 `sensor_config_init*.hxx` 的 `tx_groups` 按原始 legacy 代码使用的位定义解码：

- `tx_groups` 有四个 16 位字，分别对应物理 TX1…TX4；
- bit 1、5、9、13 分别对应 chirp group 1…4；
- 某一位为 1 表示该物理 TX 在对应 group 中发射。

当前结果：

| Profile | `tx_groups` | 活动物理 TX | 模式 |
|---|---|---:|---|
| Pf0 | `{0,0,1,0}` | TX3 | SISO / 4 RX |
| Pf1 | `{1,0,0,0}` | TX1 | SISO / 4 RX |
| Pf2 | `{0,0,1,0}` | TX3 | SISO / 4 RX |
| Pf3 | `{1,0,0,0}` | TX1 | SISO / 4 RX |

配置中没有启用多个同时发射 TX，也没有提供 DDMA 所需的逐 TX、逐 chirp 相位增量或 Doppler 偏移。因此，严格按当前 HXX 文件处理时不能生成 16 通道 DDMA 虚拟阵列。

`bpm_mode`、`phase_scramble_on`、`freq_hopping_on` 和 `chirp_shifting_on` 在四份配置中也均为 `false`。`tx_phase_value={45,45,45,45}` 的固件语义没有在工程中定义，本修复不会把它猜测成 DDMA 相位斜坡。


## 2. 显式 DDMA 配置接口

修复后的代码仅在 HXX 中出现以下任一显式字段时启用 DDMA：

```cpp
.ddma_phase_increment_deg = {0, 90, 180, 270},
```

或：

```cpp
.ddma_doppler_offsets_bins = {0, 64, 128, 192},
```

可选初始相位：

```cpp
.ddma_initial_phase_deg = {0, 0, 0, 0},
```

字段可包含四个物理 TX 的值，或仅包含活动 TX 的值。所有活动 TX 的相位增量必须唯一。只有在设备固件确实把这些字段定义为“每次同组发射之间的相位增量”时，才应加入配置。

DDMA 解调在 Range FFT 后执行：对 TX `t` 的第 `n` 个慢时间样本乘以

```text
exp(-j × (initial_phase_t + n × phase_step_t))
```

然后执行杂波抑制和 Doppler FFT。这样每个 TX 的指定 DDMA 频移被搬移回公共物理速度轴，同时保留 TX×RX 虚拟通道。


## 3. 验证

MATLAB 中运行：

```matlab
cd('<修复后工程目录>');
addpath(fullfile(pwd, 'tests'));
run_configuration_tests;
main;
```

`run_configuration_tests` 会验证：

- 四个 profile 的活动物理 TX；
- Pf0/Pf2 与 Pf1/Pf3 的天线块映射；
- 合成 TDM 分组；
- 合成 DDMA 相位解调；
- 未定义同时发射配置必须被拒绝。
