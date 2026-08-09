# ADC 数据格式速查

- 文件粒度：一个 TXT 对应一个 RX 通道。
- 头部：`rx_index, samples_per_chirp, chirp_count`。
- 载荷：无符号 32 位十进制字。
- 高 16 位：先到采样；低 16 位：后到采样。
- 16 位值：二进制补码有符号数。
- MATLAB 立方体：`adcCube(sample, chirp, channel)`。
- Pf0 示例：1024 sample × 256 chirp × 4 RX。
- 每 RX 有效 32 位字：`1024/2 × 256 = 131072`。
- 随附文件多 1 个尾部值，读取器按有效长度截取并记录尾部数量。
