# 杂波抑制、亚栅格距离和速度估计、自适应 CFAR 算法说明

## 1. 处理链路

统一链路为：

```text
ADC 解包
  → Range FFT
  → SVD / 均值 / MTI 杂波抑制
  → Doppler FFT
  → CA / OS / GOCA / SOCA / VI-CFAR
  → 局部峰值与最小间隔抑制
  → 二维亚栅格距离、速度精修
  → Angle FFT / DML / MUSIC / OMP
  → 结果表、诊断图与点云
```

## 2. 杂波抑制

### 2.1 慢时间均值消除

对每个距离单元和阵列通道，减去所有 chirp 的复数均值：

```text
x_clean(r,n,a) = x(r,n,a) - mean_n{x(r,n,a)}
```

它相当于抑制零多普勒分量，速度很快，但会削弱极慢目标。

### 2.2 二脉冲和三脉冲 MTI

二脉冲抵消器：

```text
y[n] = x[n] - x[n-1]
```

三脉冲抵消器：

```text
y[n] = x[n] - 2x[n-1] + x[n-2]
```

MTI 对零频附近形成陷波。阶数越高，静态杂波抑制通常越强，但低速目标损失也越明显。

### 2.3 低秩 SVD 杂波抑制

将 Range FFT 数据重排为：

```text
X ∈ C^((range × channel) × chirp)
```

进行奇异值分解：

```text
X = UΣVᴴ
```

强静态背景在慢时间方向具有较高相关性，通常集中在前几个奇异分量。删除前 `K` 个分量：

```text
X_clean = X - U_K Σ_K V_Kᴴ
```

默认 `K=1`。工程同时保存奇异值、删除秩和被删除能量比例。中应比较不同秩数下：

- 零多普勒功率抑制度；
- 目标 SNR；
- 慢速目标幅度损失；
- 单帧运行时间。

不应盲目提高秩数。场景中的稳定目标、护栏和地面杂波可能是低秩成分，慢速目标也可能与其子空间重叠。

## 3. 二维亚栅格距离和速度估计

FFT 检测结果只能位于整数距离栅格和速度栅格。工程在检测峰值周围提取 3×3 对数功率邻域，并拟合：

```text
z(Δr,Δd) = aΔr² + bΔd² + cΔrΔd + dΔr + eΔd + f
```

其中 `Δr` 和 `Δd` 是相对粗峰值的小数栅格偏移。通过二次曲面的 Hessian 和梯度求极大值：

```text
[Δr, Δd]ᵀ = -H⁻¹g
```

仅当 Hessian 为负定、矩阵条件合理且偏移不超过 ±0.5 bin 时接受二维解；否则回退到距离和速度两个方向的一维抛物线插值。

输出包括：

- `RangeOffset_bin`
- `DopplerOffset_bin`
- `RangeRefined_m`
- `VelocityRefined_mps`
- `SubbinFitR2`
- `SubbinFitValid`
- `SubbinMethod`

亚栅格估计改善的是峰值位置的数值精度，不会突破由带宽、信噪比、窗函数、相干时间和模型误差共同决定的物理分辨能力。

## 4. GOCA-CFAR 与 SOCA-CFAR

训练环被划分为四个互不重叠扇区。每个扇区分别计算噪声均值：

```text
μ1, μ2, μ3, μ4
```

GOCA 使用最大扇区均值：

```text
noise = max(μ1, μ2, μ3, μ4)
```

它在杂波边缘更加保守，可降低高杂波区域的虚警。

SOCA 使用最小扇区均值：

```text
noise = min(μ1, μ2, μ3, μ4)
```

它对弱目标更敏感，但在杂波边缘容易产生虚警。

## 5. 二维 VI-CFAR

工程实现的是面向 Range-Doppler 图的实用型二维 variability-index CFAR。

每个扇区计算变异系数平方：

```text
VI_s = variance_s / mean_s²
```

并计算扇区均值比：

```text
MR = max(μs) / min(μs)
```

判决逻辑：

1. 四个扇区均匀且均值接近：使用 CA-CFAR；
2. 四个扇区均匀但均值差异明显：使用 GOCA，应对杂波边缘；
3. 部分扇区受目标或干扰污染：只积累被判定为均匀的扇区；
4. 没有可信扇区：回退到 GOCA。

`detections.csv` 的 `CFARMethod` 会记录实际分支：

- `CA`
- `GOCA`
- `VI_SELECTED`
- `GOCA_FALLBACK`

可视化 `cfar_diagnostics.png` 包含：

- CUT 与噪声估计的比值；
- 变异指数图；
- 每个 CUT 的算法分支图。

### 参数建议

```matlab
opts.cfar.vi_threshold = 2.5;
opts.cfar.mean_ratio_threshold = 2.8;
opts.cfar.min_homogeneous_sectors = 1;
```

这些数值是示例起点。应通过目标缺失率、虚警数量、杂波边缘和多目标场景做网格搜索或贝叶斯优化。
