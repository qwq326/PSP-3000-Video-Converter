# PSP 3000 专用视频转换器

一键把 **MP4 / MKV / AVI / MOV / M4V / TS** 批量转换成 PSP-3000（PSP-3000 / 300x 系列）可直接播放的 `MAQxxxxx.MP4`。

> **本工具基于 FFmpeg 运行**：解封装、解码、缩放、H.264 编码、AAC 编码与 MP4 封装全部由 [FFmpeg](https://ffmpeg.org/) 完成；`PSPConverter.cmd` 只负责批量遍历、编号和拼装参数，本身不含任何编解码代码。

脚本针对 PSP-3000 的 480×272 屏幕与硬件解码能力做了专门调校：H.264 **Constrained Baseline @ Level 3.0** + AAC-LC 立体声 + PSP 专用 MP4 封装，避免常见的“不支持的数据”提示。

---

## 特性

- **批量处理**：自动扫描 `input\` 下所有视频，依次输出 `MAQ00001.MP4`、`MAQ00002.MP4` …
- **不中断**：单个文件转换失败只提示 `FAILED`，不会终止整个批次
- **自动找 FFmpeg**：环境变量/脚本目录/系统 PATH 均可
- **不污染仓库**：`input\`、`output\`、本机私有配置 `local.cmd` 已在 `.gitignore` 中排除

## 基于 FFmpeg 运行

```
PSPConverter.cmd  ──调用──▶  ffmpeg.exe  ──▶  MAQ00001.MP4
（批处理壳）                （编解码核心）
```

- 本仓库**不附带** FFmpeg 二进制，也不修改 FFmpeg，只调用它；
- 实际执行的核心命令等价于：

```bat
ffmpeg -y -i "输入视频" -map 0:v:0 -map 0:a:0? ^
       -vf "scale=480:272,setsar=1" -c:v libopenh264 ^
       -profile:v constrained_baseline -level 3.0 -pix_fmt yuv420p ^
       -b:v 384k -r 24000/1001 -c:a aac -b:a 96k -ar 48000 -ac 2 ^
       -f psp "输出\MAQ00001.MP4"
```

- 因此画质、速度、兼容性都取决于你使用的 FFmpeg 版本与其包含的编码器（需 `libopenh264` + `aac`）。

## 输出规格

| 项目 | 参数 |
| --- | --- |
| 分辨率 | 480×272（PSP-3000 原生分辨率，SAR 1:1） |
| 视频编码 | H.264 / AVC（libopenh264） |
| Profile / Level | Constrained Baseline / 3.0 |
| 像素格式 | yuv420p |
| 视频码率 | 384 kbps |
| 帧率 | 23.976 fps（24000/1001） |
| 音频编码 | AAC-LC，96 kbps，48 kHz，双声道 |
| 封装 | MP4（FFmpeg `-f psp`，PSP 兼容封装） |
| 命名 | `MAQ00001.MP4`（PSP 要求的 5 位序号 + `MAQ` 前缀） |

## 环境要求

- Windows 7 及以上
- [FFmpeg](https://ffmpeg.org/download.html)（Windows 构建需包含 `libopenh264` 与 `aac` 编码器，官方 gpl 版即可）
- 使用 `libopenh264` 时，`ffmpeg.exe` 同目录下必须有 `openh264-*.dll`

### FFmpeg 查找顺序

1. `local.cmd` 中设置的 `FFMPEG`（本机私有配置，已被 `.gitignore` 忽略）
2. 环境变量 `FFMPEG`
3. 脚本同目录 `ffmpeg\bin\ffmpeg.exe`
4. 脚本同目录 `ffmpeg.exe`
5. 系统 `PATH` 中的 `ffmpeg.exe`

## 使用方法

1. 把待转换的视频放进 `input\` 目录（没有会自动创建）
2. 双击 `PSPConverter.cmd`
3. 转换完成后，从 `output\` 取 `MAQxxxxx.MP4`
4. 拷贝到记忆棒：

```
ms0:\MP_ROOT\100MNV01\MAQ00001.MP4     ← AVC 视频（推荐）
ms0:\VIDEO\                            ← 也可以直接放这里
```

> PSP-3000 会自动在“视频”分类中列出这些文件。

### 自定义（可选）

- **指定 FFmpeg 路径**：在脚本同目录新建 `local.cmd`：

```bat
set "FFMPEG=D:\path\to\ffmpeg.exe"
```

- **修改画质/码率**：编辑 `PSPConverter.cmd` 中的 `-b:v 384k`（视频）与 `-b:a 96k`（音频）
- **保持原始分辨率比例**：如需上下黑边而非拉伸，把 `-vf "scale=480:272,setsar=1"` 改为
  `-vf "scale=480:272:force_original_aspect_ratio=decrease,pad=480:272:(ow-iw)/2:(oh-ih)/2,setsar=1"`

## 常见问题

**Q：提示 `[ERROR] FFmpeg not found.`**
A：按上面三种方式之一指定 FFmpeg 路径，最快的是在同目录放 `local.cmd` 并写入 `FFMPEG` 变量。

**Q：转换成功，但 PSP 提示“不支持的数据”**
A：多为 `openh264-*.dll` 缺失或 FFmpeg 版本过旧，换用官方 gpl 全功能构建；也有可能视频时长/码率超限，可把 `-b:v` 降到 `256k`。

**Q：文件太大 / 太大装不下记忆棒**
A：降低 `-b:v`（如 `256k`）或 `-b:a`（如 `64k`）。

**Q：能转 720p/1080p 吗？**
A：可以。PSP-3000 最高只能显示 480×272，脚本会自动缩放，源视频越大转换越慢。

## 目录结构

```
PSPConverter.cmd   主脚本（双击运行）
input\             待转换视频（不入库）
output\            转换结果 MAQxxxxx.MP4（不入库）
local.cmd          本机私有配置，指定 FFmpeg 路径（不入库）
```

## 免责声明

本脚本仅调用 FFmpeg 做格式转换，不包含、不下载任何受版权保护的内容。请仅转换你有权使用的视频。
