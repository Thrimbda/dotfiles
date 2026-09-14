# Sunshine 网络采样：2026-09-15

已部署 **3840×2160 / 60 FPS、HEVC、40 Mbps**。Hyprland 的 SUNSHINE 虚拟输出同为 4K，使用 2 倍缩放；服务端以 RTX 5090 NVENC 编码，Charles 的 M2 使用 VideoToolbox 硬件解码及 Metal 渲染。

## 两次桌面采样

分别在 00:06:34–00:09:36（1080p）和 00:20:10–00:23:12（4K，均为 UTC+8），对 Axiom → Acorn → Charles 会话采样约 3 分钟，每 5 秒记录一次。两次均为当时已有的桌面会话，没有播放相同测试素材，也没有执行专门的高动态压力场景。因此可用于观察实际用量，不能据此比较分辨率的压缩效率或推断带宽上限。

| 指标 | 1080p60 / 20 Mbps | 4K60 / 40 Mbps |
| --- | ---: | ---: |
| Axiom → Acorn，QUIC 上传均值 | 8.450 Mbps | 4.767 Mbps |
| Axiom 上传 P95 / 5 秒窗口峰值 | 8.521 / 8.562 Mbps | 4.779 / 4.780 Mbps |
| Acorn → Moonlight，串流下载均值 | 8.035 Mbps | 4.504 Mbps |
| Moonlight 下载 P95 / 5 秒窗口峰值 | 8.098 / 8.132 Mbps | 4.516 / 4.518 Mbps |
| Acorn → Axiom，QUIC 返回均值 | 0.127 Mbps | 0.104 Mbps |
| Moonlight → Acorn，控制及返回均值 | 0.012 Mbps | 0.008 Mbps |
| Acorn QUIC 入站相对客户端出站的差额 | 5.17% | 5.86% |
| 按均值外推的 Axiom 上传 | 3.80 GB/小时 | 2.15 GB/小时 |
| 按均值外推的 Mac 下载 | 3.62 GB/小时 | 2.03 GB/小时 |
| 按均值外推的 Acorn 总公网出站 | 3.67 GB/小时 | 2.07 GB/小时 |

4K 这一段流量较低，不能解释为 4K 比 1080p 更省流量。编码器的实际输出随画面内容变化，40 Mbps 设置也不代表一直发送 40 Mbps。两次中转差额包含协议封装、加密和可能的重传，不能进一步分解成纯封装或重传开销。Acorn 总公网出站包括发给 Moonlight 和返回 Axiom 的数据，不含服务器其他业务。

## 4K 客户端表现

覆盖此次采样的完整客户端会话记录如下；客户端会话比网络计数区间稍长，包含连接启动，因此二者不是严格对齐的时间窗口。

| 指标 | 记录值 |
| --- | ---: |
| 网络接收 / 解码 / 渲染帧率 | 60.01 / 60.01 / 60.00 FPS |
| 平均网络延迟 / 日志 variance | 36 / 3 ms |
| 网络丢帧 / 网络抖动丢帧 | 0.00% / 0.01% |
| 主机处理平均延迟 | 3.1 ms |
| 平均解码时间 | 3.82 ms |
| 平均帧队列等待 | 0.04 ms |
| 平均渲染时间，含垂直同步 | 1.78 ms |

网络延迟是 Moonlight 的记录值，不是测得的端到端输入至画面延迟。采样时 Axiom 只有 SUNSHINE 虚拟输出，3840×2160、60 Hz、scale=2、DPMS 开启；已有 RustDesk、主 FRP 和独立 Sunshine FRP 服务均保持运行。4K 会话断开后可重新建立。

## 带宽规划

对于当前 **4K60 / HEVC 40 Mbps** 配置，建议先预留稳定 **50–60 Mbps** 的 Axiom 上传、Acorn 可用出站和客户端下行，给音频、纠错、封装及波动留余量。这是试跑容量建议，尚未用连续高动态画面验证。不能按本次 4.8 Mbps 上传峰值来采购或限制链路。

若视频持续达到配置的 40 Mbps，视频本身就是约 **18 GB/小时**；实际公网用量还受音频、纠错、协议及重传影响，不能按当前桌面采样的 2.07 GB/小时作为高负载预算。Acorn 出站上限为 100 Mbps，还需给其他服务留余量。

Moonlight 6.1.0 的实际源码会为 4K60 计算出 **80 Mbps** 自动码率。当前已手动保存为 **40 Mbps**；以后改分辨率或 FPS 后应再次检查码率。1080p60 / 20 Mbps 可作为低带宽回退起点，建议预留 25–30 Mbps。回退时同时调整服务端虚拟屏和客户端分辨率，避免仅缩放视频。

## 测量方法与证据

临时使用无跳转目标的 iptables 计数规则，匹配 Axiom 与 Acorn 的 UDP 7001，以及 Acorn Sunshine 的 TCP 47984/47989/48010、UDP 47998–48000。规则只计数，继续执行后续防火墙规则；两次采样后均删除并核实无残留。统计 IPv4 包字节数，含 IP/传输层头部，不抓取数据内容，不使用整机网卡流量代替串流流量。

平均值由字节增量除以实际持续时间计算；P95 使用 5 秒窗口速率的 nearest-rank 分位数。峰值也是 5 秒平均，不能揭示毫秒级突发。GB 为十进制单位；每小时数字是对当前均值的外推，没有额外执行一小时测量。

- 1080p 原始数据：[CSV](evidence/sunshine-network-20260915.csv)、[JSON 汇总](evidence/sunshine-network-20260915.json)。
- 4K 原始数据及客户端统计：[CSV](evidence/sunshine-network-20260915-4k.csv)、[JSON 汇总](evidence/sunshine-network-20260915-4k.json)。

参考：[Moonlight 6.1.0 码率计算源码](https://github.com/moonlight-stream/moonlight-qt/blob/v6.1.0/app/settings/streamingpreferences.cpp#L348)、[Sunshine FEC 配置](https://docs.lizardbyte.dev/projects/sunshine/master/md_docs_2configuration.html#fec_percentage)。
