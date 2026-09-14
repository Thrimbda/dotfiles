# Sunshine 网络采样：2026-09-15

00:06:34–00:09:36（UTC+8）对正在运行的 Axiom → Acorn → Charles 会话采样约 3 分钟，每 5 秒记录一次。设置为 1920×1080、60 FPS、HEVC、Moonlight 20 Mbps。实际平均流量低于配置码率；本次没有执行专门的高动态压力场景，不能把观察到的峰值当作带宽上限。

| 路径 | 平均 Mbps | P95 Mbps | 5 秒窗口峰值 Mbps | 按此次均值持续使用 GB/小时 |
| --- | ---: | ---: | ---: | ---: |
| Axiom → Acorn，QUIC 上传 | 8.450 | 8.521 | 8.562 | 3.803 |
| Acorn → Moonlight，串流下载 | 8.035 | 8.098 | 8.132 | 3.616 |
| Acorn → Axiom，QUIC 返回数据 | 0.127 | 0.136 | 0.137 | 0.057 |
| Moonlight → Acorn，控制及返回数据 | 0.012 | 0.020 | 0.021 | 0.006 |

Acorn 上同一采样区间内，QUIC 入站比转发给 Moonlight 的出站多 **5.17%**。这个差值包含协议封装、加密和可能的重传，不能进一步分解成纯封装或重传开销。串流产生的 Acorn 总公网出站约 **3.67 GB/小时**，包含发给 Moonlight 的数据与返回 Axiom 的数据，不包含服务器其他业务。

## 带宽规划

当前会话约用 8.5 Mbps 上传，但只准备 9 Mbps 会缺少画面变化时的余量。1080p60 / 20 Mbps 配置可先按稳定 **25–30 Mbps** 的 Axiom 上传与客户端下行规划；连续高动态画面仍需单独测试。视频变化量、帧率、音频、FEC 和网络重传都会影响实际用量。

高分辨率候选配置如下，尚未部署或采样：

| 候选 | 初始 HEVC 码率 | 建议预留稳定带宽 | 满配置码率连续使用的基准流量 |
| --- | ---: | ---: | ---: |
| 4K：3840×2160 / 60 FPS | 40 Mbps | 50–60 Mbps | 18 GB/小时，另加中转开销 |
| 5K：5120×2880 / 60 FPS | 50–60 Mbps | 65–80 Mbps | 22.5–27 GB/小时，另加中转开销 |

这些是桌面场景的试跑起点，并非实测所需码率或画质保证。Acorn 出站带宽上限为 100 Mbps，还要给其他服务留余量。Moonlight 6.1.0 的实际源码会给 4K60 计算出 80 Mbps 默认值，高于这里建议的起点；手动改分辨率后应复核码率，不能直接沿用自动推荐值。

需要同时改变 Hyprland 虚拟输出和 Moonlight 分辨率。仅修改 Moonlight 的视频分辨率，会放大当前 1080p 桌面。最终选择 4K 或 5K 后，还需验证匹配分辨率的 NVENC / VideoToolbox 编解码、文字缩放、持续串流及网络余量。

## 测量方法与边界

临时使用无跳转目标的 iptables 计数规则，匹配 Axiom 与 Acorn 的 UDP 7001，以及 Acorn Sunshine 的 TCP 47984/47989/48010、UDP 47998–48000。规则只计数，继续执行后续防火墙规则；采样结束后删除。统计 IPv4 包字节数，含 IP/传输层头部，不抓取数据内容，不使用整机网卡流量代替串流流量。

平均值由字节增量除以实际持续时间计算；P95 使用 5 秒窗口速率的 nearest-rank 分位数。峰值也是 5 秒平均，不能揭示毫秒级突发。GB 为十进制单位；每小时数字是对当前均值的外推，不是额外执行了一小时测量。

原始数据：[CSV](evidence/sunshine-network-20260915.csv)、[JSON 汇总](evidence/sunshine-network-20260915.json)。

参考：[Moonlight 6.1.0 码率计算源码](https://github.com/moonlight-stream/moonlight-qt/blob/v6.1.0/app/settings/streamingpreferences.cpp#L348)、[Sunshine FEC 配置](https://docs.lizardbyte.dev/projects/sunshine/master/md_docs_2configuration.html#fec_percentage)。
