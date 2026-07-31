# Contributing to CTSAI-A100

感谢你参与 SuperRadar 社区共建。

CTSAI-A100 仓库包含 SuperRadar 官方维护的开发资源，以及开发者基于 A100 创建的 Community Projects。

目前社区主要欢迎开发者贡献 **基于 CTSAI-A100 的独立项目、算法实验和应用案例**。

## 贡献 Community Project

如果你基于 CTSAI-A100 完成了 ADC 数据分析、雷达信号处理、点云算法、AI 感知、机器人、低空或其他应用实践，可以将成果提交至：

`community/projects/<project-name>/`

项目提交要求请参考：

`community/template/README.md`

## 提交流程

1. Fork `Super-Radar/CTSAI-A100`
2. 在自己的 Fork 中创建开发分支
3. 在 `community/projects/` 下创建自己的独立项目目录
4. 将项目相关代码、数据说明、实验结果和文档统一放入该目录
5. Commit 修改并 Push 到自己的 Fork
6. 向 `Super-Radar/CTSAI-A100` 的 `main` 分支提交 Pull Request
7. 根据 Review 意见完善项目
8. PR 合并后，项目正式进入 A100 Community Projects

例如：

```text
community/projects/a100-human-mti/
├── README.md
├── src/
├── data/
├── figures/
└── docs/
```

## 官方资源

以下内容主要由 SuperRadar 官方维护：

* RadarTools
* USB-CAN 驱动
* ADC 数据采集相关官方资源
* Python / MATLAB 官方基础示例
* 产品技术文档

除非 SuperRadar 官方明确邀请，请不要通过 Community Project PR 修改上述官方资源。

如果发现官方工具、代码或文档存在问题，建议优先提交 GitHub Issue。

## 提交前检查

提交 Pull Request 前，请确认：

* 项目基于 CTSAI-A100 开发
* 项目位于 `community/projects/<project-name>/`
* 已提供项目说明
* 已提供主要代码
* 已说明数据来源或获取方式
* 已说明开发环境和运行方法
* 已提供实际运行或实验结果
* 未无故修改官方资源
* 未上传无权公开的数据、代码或其他内容

我们希望社区项目能够做到：

**看得懂、跑得起来、可以继续开发。**
