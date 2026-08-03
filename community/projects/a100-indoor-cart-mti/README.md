# CTSAI-A100 室内低速目标检测与 MTI 静态杂波抑制

本项目是 [CTSAI-A100 Issue #8](https://github.com/Super-Radar/CTSAI-A100/issues/8) 的可复现实验案例，面向校园室内房间、走廊或实验室门口的小推车/箱子与人员低速目标。项目使用 GNU Octave 11.3.0 和免费的 `signal` 包，代码为 MATLAB 兼容 `.m` 文件，不依赖付费工具箱。

> **数据边界：** `data/` 中是 2026-08-02 的真实 CTSAI-A100 实测文件；`src/simulate_lfmcw_scene.m` 生成的是用于解释 LFMCW、2D-FFT 和 MTI 原理的确定性教学仿真。两者不会混写。由于 ADC 文本缺少完整可核验的硬件波形/DDMA 参数，实测 ADC 图只使用距离 bin 和归一化多普勒轴，不换算成准确物理速度。

完整推导、参数研究和实测对比见 [`docs/technical-article.md`](docs/technical-article.md)。

## 项目完成了什么

- 严格解析 A100 ADC 的 3 字段头部、32 位打包字和经验证的零填充；
- 生成 LFMCW 发射信号、目标回波、差频信号和时频图；
- 完成距离 FFT、距离—多普勒 2D-FFT 与可配置阶数 MTI；
- 分析带宽、chirp 时宽、PRF、目标速度、目标数量和 MTI 阶数；
- 处理 10 个有效 ADC 通道和 7 组点云/跟踪实测场景；
- 对比新空场与约 3 米静止人员；
- 展示小推车/箱子靠近、远离和人员短距离远离的真实运动包络；
- 输出 PNG、CSV 指标和带 SHA-256 的数据清单。

## 实验场景

采集地点为室内房间。雷达倾斜安装，中心离地约 `0.95 m`，具体倾角未测。静止受控目标为塑料材质，尺寸约 `1.00 m × 0.80 m`。房间内墙面、地面、门框和其他固定物体形成静态背景；可用纵向空间有限，因此新增人员场景采用约 3 米静止和短距离远离测试。

```text
室内固定背景（墙面、地面、门框、家具）

       约 3 m 人员/静止目标位置
                 ●
                 │  靠近 / 远离的径向运动方向
                 │
       [ CTSAI-A100 ]  倾斜安装，中心离地约 0.95 m
```

RadarTools 新增人员会话使用近波模式 3、CAN-FD、CAN1、500K/2M。没有连接摄像头，所以软件创建的 MP4 为 0 字节；这些视频不在项目中。

## 数据集

项目包含 31 个正式文件，共 51,666,387 字节。逐文件大小与 SHA-256 位于 [`data/manifest.csv`](data/manifest.csv)。

### ADC

| 场景 | 通道 | 处理范围 |
| --- | --- | --- |
| 静止塑料目标 | Rx0–Rx3 | 距离 bin、四通道对比、MTI |
| 空场背景 | Rx0–Rx3 | 底噪、静态杂波参考 |
| 小推车/箱子靠近 | Rx0 | 原始 2D-FFT 与 MTI |
| 小推车/箱子远离 | Rx0 | 原始 2D-FFT 与 MTI，使用最终 retry3 |

详细格式见 [`data/adc/README.md`](data/adc/README.md)。

### 点云/CAN

正式场景包括静止塑料目标、空场、小推车靠近、小推车远离、新空场、3 米静止人员和人员短距离远离。每组保留非空 ASC、RawTarget 和 TraTarget。详细时间戳、稀疏跟踪说明及排除记录见 [`data/targets/README.md`](data/targets/README.md)。

## 开发环境

- 雷达：CTSAI-A100
- 上位机：RadarTools V1.4.7.1
- 操作系统：Windows
- GNU Octave：11.3.0
- Octave `signal`：1.4.7
- 其他依赖：无付费 MATLAB 工具箱、无 Python 包

代码使用 `fullfile` 等跨平台路径操作；本项目在 Windows 上完成验证。绘图使用无界面模式，`save_png.m` 会在包含中文路径时通过临时 ASCII 路径规避 Ghostscript 输出限制。

## 快速运行

进入本项目目录后执行：

```powershell
& 'C:\Program Files\GNU Octave\Octave-11.3.0\mingw64\bin\octave-cli.exe' `
  --no-gui --quiet --eval "run_all"
```

如果 `octave-cli` 已在 `PATH`：

```powershell
octave-cli --no-gui --quiet --eval "run_all"
```

运行测试：

```powershell
octave-cli --no-gui --quiet --eval "addpath('tests'); run_tests"
```

单独运行模块：

```matlab
addpath('scripts');
run_simulation(pwd);
run_parameter_studies(pwd);
run_measured_adc_analysis(pwd);
run_target_analysis(pwd);
```

## 目录结构

```text
a100-indoor-cart-mti/
├── README.md
├── project.yaml
├── run_all.m
├── data/
│   ├── manifest.csv
│   ├── adc/
│   └── targets/
├── docs/
│   ├── design.md
│   ├── implementation-plan.md
│   └── technical-article.md
├── figures/
├── results/
├── scripts/
├── src/
└── tests/
```

## 关键结果

### 教学仿真

默认仿真假设 `77 GHz` 载频、`1 GHz` 带宽、`60 μs` chirp、`70 μs` 重复周期和 `256` 个 chirp。它们不是对 A100 实测波形的反推。

| 指标 | 结果 |
| --- | ---: |
| 理论距离分辨率 | 0.1499 m |
| 速度 bin 间隔 | 0.1086 m/s |
| 移动目标距离误差 | 0.0042 m |
| 移动目标速度误差 | 0.0241 m/s |
| 含噪默认场景静态抑制度 | 76.5 dB |

MTI 前后二维图共用 MTI 前峰值作为 0 dB 参考，因此图中的目标衰减和静态抑制可以直接比较，不会被分别归一化掩盖。

![教学仿真的 MTI 前后距离—多普勒图](figures/simulation_range_doppler_mti.png)

### 实测 ADC

10 个通道均被严格加载为 `1024 × 256`。每个文件包含 131072 个有效打包字和 1 个已验证为零的尾部填充。一次脉冲对消后的零多普勒邻域抑制度为：

| 场景 | Rx | 抑制度 |
| --- | ---: | ---: |
| 小推车/箱子靠近 | 0 | 49.3 dB |
| 小推车/箱子远离 | 0 | 51.4 dB |

该数值是 bin 域静态分量变化，不是目标检测增益，也不能证明对应某个物理速度。
静止目标与空场的每个 Rx 距离谱使用同一个参考峰值，只在同一 Rx 内比较绝对幅度；不同 Rx 仍可能具有不同通道增益。

![实测静止目标与空场的 MTI 前后图](figures/measured_adc_static_background_mti.png)

### 真实目标输出

固定 ROI 为 `2.5–3.1 m`、`−20°–5°`。新空场 268 帧中没有 ROI 检测；约 3 米静止人员在 266 帧中有 163 帧出现 ROI 检测，帧检出比例 61.3%，中位距离 2.79 m，中位 SNR 29.5 dB。

![新空场与 3 米静止人员实测对比](figures/measured_stationary_person.png)

保守 RawTarget 检测包络得到：

| 场景 | 起点→终点 | 距离斜率 | 中位径向速度 |
| --- | ---: | ---: | ---: |
| 小推车/箱子靠近 | 2.62→1.57 m | −0.0750 m/s | −0.15 m/s |
| 小推车/箱子远离 | 1.20→2.89 m | +0.1772 m/s | +0.15 m/s |
| 人员短距离远离 | 3.24→4.01 m | +0.0700 m/s | +0.10 m/s |

![真实靠近与远离检测包络](figures/measured_target_motion_trends.png)

这里的“包络”不是身份跟踪结果。算法不接收场景方向标签，而是分别构建靠近和远离假设，仅保留时间、距离连续且整体斜率与径向速度符号一致的分段，再自动选择证据较强的一侧。三组运动场景的自动推断方向均与采集记录一致。特别是原小推车远离场景的 TraTarget 只有 5 条记录、1 帧，因此仍只能依据 RawTarget 展示总体趋势。

## 参数研究结论

- 带宽从 0.5 GHz 增至 1.5 GHz，理论距离分辨率从约 0.300 m 改善到 0.100 m；
- 固定 ADC 速率下，chirp 时宽增长会降低同一目标的差频并扩大 ADC 限制的距离范围；
- 固定 chirp 数时，提高 PRF 扩大无模糊速度范围，但速度 bin 变粗；
- 0.15 m/s 目标更靠近 MTI 零频陷波，比 0.70 m/s 目标受到更强衰减；
- 目标数量增加会提高谱峰重叠和动态范围压力；
- 更高阶 MTI 加深静态陷波，也会进一步损失低速目标幅度。

全部机器可读结果位于 [`results/parameter_studies.csv`](results/parameter_studies.csv)。

## 局限与正确解释

1. 仿真用于说明标准 LFMCW 原理，不是实测 A100 波形复刻。
2. ADC 结果没有标定到米和米每秒；不把 DDMA 固定频带解释成真实目标速度。
3. 室内多径、倾斜安装、墙面/地面强反射和未知硬件增益会改变实测谱。
4. MTI 会抑制静态背景，也会衰减非常慢或暂时停止的目标；不能仅凭更干净的图认定检测性能提升。
5. RawTarget 包络只证明总体运动方向，不提供身份连续性或高精度真值。
6. 人工距离标记与雷达反射中心不同，3 米人员测得中位距离 2.79 米被原样保留。

## 作者

- GitHub：[@yyqdbngt](https://github.com/yyqdbngt)
- 项目：Super-Radar/CTSAI-A100 Community Project
