# Pipelined ADC 仿真

## 文件分工

| 文件 | 内容 |
| --- | --- |
| `parameters.m` | ADC 参数、直流扫描点数及正弦测试参数 |
| `system_model.m` | 四种工况的级联配置、单级 MDAC 和完整 ADC 模型 |
| `tb_Vres.m` | 单级残差测试，调用 `plot_Vres.m` |
| `tb_dc_transfer.m` | 直流扫描测试，调用 `plot_transfer.m` |
| `tb_ac_FFT.m` | 正弦加白噪声测试；局部函数计算 FFT、PSD、SINAD、ENOB |
| `plot_Vres.m` | 三种非理想工况与理想残差的对比图 |
| `plot_transfer.m` | 输入电压与输出码的传输曲线 |
| `plot_FFT.m` | 四种工况的频谱，标题显示 SINAD 和 ENOB |
| `plot_PSD.m` | 四种工况的功率谱密度 |

公共参数和模型由各 testbench 加载，绘图脚本使用对应 testbench 的工作区变量。频谱分析函数保留在 `tb_ac_FFT.m` 内。

## 运行方式

在 MATLAB 中打开任意 `tb_*.m`，点击运行。也可以在项目根目录分别执行：

```matlab
run('Pipelined_ADC_Model/tb_Vres.m');         % 单级残差
run('Pipelined_ADC_Model/tb_dc_transfer.m');  % 直流传输特性
run('Pipelined_ADC_Model/tb_ac_FFT.m');       % FFT、PSD、SINAD、ENOB
```

每个入口都会清空工作区、命令窗口并关闭已有图窗，因此应按需单独运行。仿真结果保留在工作区；需要重新画图时，在对应测试运行后调用 `plot_*.m`。

代码使用 `tiledlayout`，需使用支持该函数的 MATLAB 版本。Hann 窗通过公式生成，频谱分析使用基础 MATLAB 函数，无需 Signal Processing Toolbox。

## 模型与参数

默认分辨率为 8 bit、参考电压为 1 V，输入范围为 `[0,VREF]`。前 `Nbits-1` 级完成比较和残差放大，末级仅比较，输出各位按二进制权重合成数字码。

四种工况依次为：理想、电容失配、比较器失调、有限运放增益。非理想工况仅第一级引入对应误差，其余级保持理想。

在 `parameters.m` 中修改参数：

| 参数 | 默认值 | 含义 |
| --- | --- | --- |
| `VREF` | `1` | 参考电压，V |
| `Nbits` | `8` | ADC 分辨率 |
| `C1` | `1e-12` | 电容，F；模型实际使用电容比 |
| `mismatch` | `0.30` | 电容失配 `C2/C1-1` |
| `Vos` | `0.10*VREF` | 比较器输入失调，V |
| `A0` | `20` | 运放直流开环增益，V/V |
| `nPoints` | `4001` | 残差和直流传输测试的扫描点数 |
| `Fs` | `1e6` | 交流测试采样率，Hz |
| `Nfft` | `2^14` | 交流测试采样点数，也是 FFT 点数 |
| `nCycles` | `127` | 采样记录内的正弦周期数 |
| `Fin` | `nCycles*Fs/Nfft` | 输入频率，Hz |
| `Ain` | `0.499*VREF` | 正弦峰值幅度，V |
| `Vcm` | `VREF/2` | 输入直流偏置，V |

模型通过 `model.mdacStage`、`model.pipelineADC` 两个函数句柄调用。必须先执行 `parameters`，再执行 `system_model`。

## 白噪声与加窗

在 `tb_ac_FFT.m` 开头设置：

```matlab
noisePower = 1e-8;  % 输入白噪声方差，V^2；0 为关闭
useHann = true;     % true：周期 Hann 窗；false：矩形窗
rng(1);            % 固定随机种子，便于重复比较
```

输入噪声由 `sqrt(noisePower)*randn(Nfft,1)` 生成，是零均值高斯白噪声。`noisePower` 是目标方差，不是 dB 或每 Hz 的功率密度；有限记录的实际均方值会略有波动。默认噪声 RMS 为 `1e-4 V`，四种工况使用同一份带噪输入。

当前分析仍按相干采样设计：保持 `Fin=nCycles*Fs/Nfft`，使用偶数 `Nfft` 和整数 `nCycles`，建议二者互质。基波还需远离直流和 Nyquist 频点，满足 `1<nCycles<Nfft/2-1`。开启 Hann 窗不代表支持任意非相干输入频率。

关闭加窗时，基波功率取中心频点；开启 Hann 时，合计中心及相邻两个频点。两种模式均按窗能量归一化，SINAD 分母统计除直流与基波频点外的功率，包含谐波。基波频点内的噪声未另行估计。

## 结果读取

直流测试保留各工况的 `code*`、`bits*`、`residues*`，分别表示输出码、各级判决和各级输入残差；`residues*` 第一列为原始输入。

交流测试的 `codes` 每列对应一种工况，顺序为理想、电容失配、比较器失调、有限增益。分析结果存入 `result`：

| 字段 | 含义 |
| --- | --- |
| `f` | 单边频率轴，Hz |
| `FFT_dBFS` | 每个频点的功率，以满量程正弦功率 `VREF^2/8` 为参考 |
| `PSD` | 线性功率谱密度，V²/Hz；图中转换为相对 1 V²/Hz 的 dB 值 |
| `SINAD` | 基波功率与噪声加失真功率之比，dB |
| `ENOB` | `(SINAD-1.76)/6.02`，适用于接近满量程正弦测试 |

Hann 窗会将基波功率分布到相邻频点，因此单个频点的峰值不能直接当作整个基波功率。PSD 乘频率间隔 `Fs/Nfft` 后求和，得到窗加权的去直流信号均方值。

## 模型范围

模型不包含采样开关、运放建立时间、时钟抖动或流水线时延；`Fs` 用于生成激励和频率轴，不会自动引入动态电路误差。内部残差不裁剪，输入白噪声也不额外限幅。增大噪声功率时应关注输入是否超出 `[0,VREF]`。

源自 Behzad Razavi 的 *A Tale of Two ADCs: Pipelined Versus SAR*，IEEE Solid-State Circuits Magazine，Summer 2015，pp. 38–46，DOI：10.1109/MSSC.2015.2442372。
