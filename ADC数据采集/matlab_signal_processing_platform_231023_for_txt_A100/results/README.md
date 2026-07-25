# Results

运行 `main.m` 后，本目录会保存图像、`detections.csv` 和 `processing_result.mat`。

竞赛增强版新增：

- `clutter_suppression_comparison.png`：杂波抑制前后对比；
- `cfar_diagnostics.png`：VI、扇区选择和 CFAR 分支；
- `subbin_refinement.png`：粗 FFT 峰值与亚栅格估计对比。

仓库中附带的 `example_*` 文件是对随附 Pf0 数据进行独立数值验证得到的参考输出；MATLAB 实际输出会使用不带 `example_` 前缀的文件名。参考输出仅用于检查处理链路和量纲，不代表产品性能。
