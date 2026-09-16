Pipelined_ADC_mxy.m

---

## 一、这份代码到底在做什么？

这份程序建立了一个 **每级产生 1 bit 的流水线 ADC 静态模型**，考察三种非理想因素：

1. 电容失配。
2. 比较器失调。
3. 运算放大器开环增益有限。

它做了两层仿真：

| 层次 | 计算内容 | 用途 |
|---|---|---|
| 单级 | 输入电压与输出残差的关系 | 画出三种误差对单级特性的影响 |
| 完整 ADC | 将 8 个量化级串起来 | 得到最终数字码、各级判决和残差 |

**注意：程序最后只画了单级残差曲线。8 位 ADC 的结果已经计算出来，但没有画出来。**

这里的“静态模型”意味着：给定一个输入电压，直接根据公式计算结果。代码没有模拟时钟、采样开关动作、运放建立过程或流水线延迟。

---

## 二、先理解流水线 ADC 的基本思想

### 1. 每一级只判断一位

输入范围设为：

\[
0\le V_{\mathrm{in}}\le V_{\mathrm{REF}}
\]

第一级比较输入与参考电压的一半：

\[
D=
\begin{cases}
0,&V_{\mathrm{in}}<V_{\mathrm{REF}}/2\\
1,&V_{\mathrm{in}}\ge V_{\mathrm{REF}}/2
\end{cases}
\]

这个判决只告诉我们：

- `0`：输入在下半区间。
- `1`：输入在上半区间。

它就是最终数字结果的最高位。

### 2. 判决之后，还要把剩余信息交给下一级

理想级的残差公式是：

\[
\boxed{V_{\mathrm{res}}=2V_{\mathrm{in}}-DV_{\mathrm{REF}}}
\]

分情况看：

\[
V_{\mathrm{res}}=
\begin{cases}
2V_{\mathrm{in}},&D=0\\
2V_{\mathrm{in}}-V_{\mathrm{REF}},&D=1
\end{cases}
\]

它把输入所在的半个区间重新映射到完整输入范围。

例如，设 \(V_{\mathrm{REF}}=1\text{ V}\)：

| 输入 | 判决 | 残差 |
|---|---:|---:|
| 0.2 V | 0 | 0.4 V |
| 0.4 V | 0 | 0.8 V |
| 0.6 V | 1 | 0.2 V |
| 0.9 V | 1 | 0.8 V |

你可能会发现：`0.4 V` 和 `0.9 V` 的残差都是 `0.8 V`。

这不代表信息丢失，因为它们的判决不同：

- `0.4 V` 对应 `D=0`。
- `0.9 V` 对应 `D=1`。

**判决保存粗略位置，残差保存尚未转换的细节。**

### 3. 为什么要放大两倍？

输入被分成上下两个区间后，每个区间宽度只有：

\[
V_{\mathrm{REF}}/2
\]

放大两倍，可以让下一级继续使用同样的输入范围和同样的比较门限。

理想公式也可以写成：

\[
V_{\mathrm{res}}
=2\left(V_{\mathrm{in}}-D\frac{V_{\mathrm{REF}}}{2}\right)
\]

对应：

1. 比较器产生 \(D\)。
2. DAC 根据 \(D\) 产生等效电压。
3. 从输入中减去已确定的部分。
4. 将剩余部分放大两倍。

这些功能共同构成代码里的 **MDAC，乘法数模转换器**。

---

## 三、初始化和参数设置

对应代码第 7～18 行。

### 1. 清理环境

```matlab
clear; clc; close all;
```

分别表示：

- `clear`：清除工作区变量。
- `clc`：清空命令窗口。
- `close all`：关闭已有图窗。

目的是让本次仿真从干净的环境开始。

### 2. 参考电压

```matlab
VREF = 1;
```

设置：

\[
V_{\mathrm{REF}}=1\text{ V}
\]

整个模型采用单端输入范围：

\[
[0,1]\text{ V}
\]

理想比较器门限就是：

\[
V_{\mathrm{REF}}/2=0.5\text{ V}
\]

### 3. 电容与失配

```matlab
C1 = 1e-12;
mismatch = 0.30;
```

`1e-12 F` 就是 `1 pF`。

失配定义为：

\[
\mathrm{mismatch}=\frac{C_2}{C_1}-1
\]

因此后面的：

```matlab
C2 = (1+mismatch)*C1;
```

对应：

\[
C_2=1.3C_1=1.3\text{ pF}
\]

这里的 `0.30` 表示 **30% 的失配**。

这个模型只使用电容比 \(C_2/C_1\)。如果把两只电容同时扩大十倍，计算出来的结果不变。

真实电路中，电容绝对大小还会影响噪声、负载、速度等，但代码没有建模这些因素。

### 4. 比较器失调

```matlab
Vos = 0.10*VREF;
```

设置：

\[
V_{\mathrm{os}}=0.1\text{ V}
\]

按照本代码的符号约定，正失调会使比较门限升高：

\[
V_{\mathrm{th}}
=\frac{V_{\mathrm{REF}}}{2}+V_{\mathrm{os}}
=0.6\text{ V}
\]

所以输入要达到 `0.6 V`，比较器才输出 `1`。

### 5. 运放开环增益

```matlab
A0 = 20;
```

这里是线性电压增益：

\[
A_0=20\text{ V/V}
\]

不是 `20 dB`。换算为分贝约为：

\[
20\log_{10}(20)\approx26.02\text{ dB}
\]

如果想设置 `20 dB`，对应的线性增益应为：

```matlab
A0 = 10^(20/20);   % 等于 10
```

还要区分两个概念：

- `A0`：运放本身的开环增益。
- 理想残差放大倍数 `2`：整个 MDAC 在反馈作用下的信号增益。

这两个增益不是同一个量。

### 6. 输入点数与 ADC 位数

```matlab
nPoints = 4001;
Nbits = 8;
```

- `nPoints`：从 `0 V` 到 `1 V` 取 4001 个输入点。
- `Nbits`：完整 ADC 产生 8 位结果。

8 位 ADC 一共有：

\[
2^8=256
\]

种输出码，即 `0～255`。

---

## 四、为什么用结构体保存参数？

对应第 20～27 行：

```matlab
pIdeal = struct('Vref',VREF,'C1',C1,'C2',C1,'A0',Inf,'Vos',0);
```

这建立了一个参数结构体：

| 字段 | 数值 | 含义 |
|---|---:|---|
| `Vref` | 1 | 参考电压 |
| `C1` | \(10^{-12}\) | 电容 1 |
| `C2` | \(10^{-12}\) | 电容 2 |
| `A0` | `Inf` | 无限大的开环增益 |
| `Vos` | 0 | 无比较器失调 |

`Inf` 是 MATLAB 中的无穷大。因此公式里：

```matlab
(1+ratio)/p.A0
```

会等于零，表示忽略有限开环增益造成的误差。

接着：

```matlab
pMismatch = pIdeal;
pMismatch.C2 = (1+mismatch)*C1;
```

先复制理想参数，再只修改电容 `C2`。

另外两个类似：

```matlab
pOffset = pIdeal;
pOffset.Vos = Vos;

pFinite = pIdeal;
pFinite.A0 = A0;
```

于是得到四种独立情况：

| 参数组 | 电容匹配 | 比较器失调 | 开环增益 |
|---|---|---|---|
| `pIdeal` | 理想 | 0 | 无穷大 |
| `pMismatch` | \(C_2/C_1=1.3\) | 0 | 无穷大 |
| `pOffset` | 理想 | 0.1 V | 无穷大 |
| `pFinite` | 理想 | 0 | 20 |

**这种写法是在分别观察单一误差的影响，没有把三种误差叠加。**

---

## 五、最核心的函数：`mdacStage`
对应第 82～88 行：

```matlab
function [vout,decision] = mdacStage(vin,p)
    ratio = p.C2/p.C1;
    decision = double(vin >= p.Vref/2+p.Vos);
    vout = ((1+ratio).*vin-ratio.*decision*p.Vref) ...
        /(1+(1+ratio)/p.A0);
end
```

输入是：

- `vin`：一个或多个输入电压。
- `p`：该级的参数结构体。

输出是：

- `vout`：残差电压。
- `decision`：比较器的 0/1 判决。

### 1. 计算电容比

```matlab
ratio = p.C2/p.C1;
```

定义：

\[
r=\frac{C_2}{C_1}
\]

理想时 \(r=1\)，失配时 \(r=1.3\)。

### 2. 比较器判决

```matlab
decision = double(vin >= p.Vref/2+p.Vos);
```

对应：

\[
D=
\begin{cases}
0,&V_{\mathrm{in}}<V_{\mathrm{REF}}/2+V_{\mathrm{os}}\\
1,&V_{\mathrm{in}}\ge V_{\mathrm{REF}}/2+V_{\mathrm{os}}
\end{cases}
\]

MATLAB 会对 `vin` 中每个元素进行比较。

例如：

```matlab
vin = [0.2; 0.5; 0.8];
```

理想情况下：

```matlab
vin >= 0.5
```

得到逻辑值：

```matlab
[false; true; true]
```

`double(...)` 把它们变成数值：

```matlab
[0; 1; 1]
```

注意这里使用的是 `>=`：输入恰好等于门限时，输出为 `1`。

### 3. 残差公式

```matlab
vout = ((1+ratio).*vin-ratio.*decision*p.Vref) ...
    /(1+(1+ratio)/p.A0);
```

写成数学表达式：

\[
\boxed{
V_{\mathrm{res}}
=
\frac{(1+r)V_{\mathrm{in}}-rDV_{\mathrm{REF}}}
{1+\frac{1+r}{A_0}}
}
\]

这是整个仿真的核心。

可以分成三部分理解：

| 部分 | 作用 |
|---|---|
| \((1+r)V_{\mathrm{in}}\) | 输入信号放大项 |
| \(rDV_{\mathrm{REF}}\) | 与判决相关的参考电压扣除项 |
| \(1+(1+r)/A_0\) | 有限开环增益引入的修正项 |

这里采用了特定电容比和有限增益的行为模型。要从晶体管或开关电容电路严格推导这个表达式，还需要对应的电路连接和开关时序；当前文件没有包含那些细节。

### 4. 理想情况下，公式怎么简化？

令：

\[
r=1,\qquad A_0\rightarrow\infty,\qquad V_{\mathrm{os}}=0
\]

得到：

\[
V_{\mathrm{res}}
=\frac{2V_{\mathrm{in}}-DV_{\mathrm{REF}}}{1}
=2V_{\mathrm{in}}-DV_{\mathrm{REF}}
\]

正好是前面介绍的理想残差公式。

### 5. MATLAB 运算符说明

```matlab
.*
```

表示逐元素乘法。在这里，`ratio` 是标量，因此和向量相乘时使用 `*` 也能得到相同结果；写成 `.*` 更直接地表达逐点计算的意思。

```matlab
/
```

这里右边是标量，因此表示把整个向量除以同一个数。

```matlab
...
```

是续行符：本行语句在下一行继续。

---

## 六、三种误差具体改变了什么？

这一部分直接对应最后三幅图。以下电压数值均采用 \(V_{\mathrm{REF}}=1\text{ V}\)。

### 1. 理想残差曲线

\[
V_{\mathrm{res}}=
\begin{cases}
2V_{\mathrm{in}},&V_{\mathrm{in}}<0.5\\
2V_{\mathrm{in}}-1,&V_{\mathrm{in}}\ge0.5
\end{cases}
\]

所以：

- 输入从 `0` 增加到接近 `0.5`，残差从 `0` 上升到接近 `1`。
- 输入恰好达到 `0.5`，判决从 `0` 变成 `1`，残差跳回 `0`。
- 输入再从 `0.5` 增加到 `1`，残差再次从 `0` 上升到 `1`。

两段直线的斜率都是 `2`。

这个跳变是正常的量化分支切换。

### 2. 电容失配：斜率和扣除量都变了

此时：

\[
r=1.3,\quad A_0=\infty,\quad V_{\mathrm{os}}=0
\]

公式变为：

\[
V_{\mathrm{res}}=2.3V_{\mathrm{in}}-1.3D
\]

即：

\[
V_{\mathrm{res}}=
\begin{cases}
2.3V_{\mathrm{in}},&V_{\mathrm{in}}<0.5\\
2.3V_{\mathrm{in}}-1.3,&V_{\mathrm{in}}\ge0.5
\end{cases}
\]

关键位置：

| 输入位置 | 残差 |
|---|---:|
| 0 V | 0 V |
| 从左侧接近 0.5 V | 接近 1.15 V |
| 恰好 0.5 V | −0.15 V |
| 1 V | 1 V |

因此：

- 分支斜率从 `2` 增大到 `2.3`。
- 比较门限仍然是 `0.5 V`。
- 跳变量从 `1 V` 增大到 `1.3 V`。
- 残差会超出下一级假定的 `[0,1] V` 范围。

这说明电容失配不只是把曲线整体上移或下移，它同时改变了信号增益和参考扣除量。

### 3. 比较器失调：切换位置变了

此时电容和运放仍理想，所以：

\[
V_{\mathrm{res}}=2V_{\mathrm{in}}-D
\]

但判决门限变成 `0.6 V`：

\[
V_{\mathrm{res}}=
\begin{cases}
2V_{\mathrm{in}},&V_{\mathrm{in}}<0.6\\
2V_{\mathrm{in}}-1,&V_{\mathrm{in}}\ge0.6
\end{cases}
\]

关键位置：

| 输入位置 | 残差 |
|---|---:|
| 0.5 V | 1 V |
| 从左侧接近 0.6 V | 接近 1.2 V |
| 恰好 0.6 V | 0.2 V |
| 1 V | 1 V |

可以看到：

- 两段直线斜率仍然是 `2`。
- 跳变量仍然是 `1 V`。
- 跳变位置从 `0.5 V` 移到 `0.6 V`。
- 在 `0.5～0.6 V` 之间，比较器仍输出 `0`，残差会超过 `1 V`。

**比较器失调改变的是“什么时候切换分支”。**

这里并不是整条残差曲线水平平移，因为两条分支的表达式本身没有改变。

### 4. 运放增益有限：残差被压缩

此时：

\[
r=1,\quad A_0=20,\quad V_{\mathrm{os}}=0
\]

所以：

\[
V_{\mathrm{res}}
=\frac{2V_{\mathrm{in}}-D}{1+2/20}
=\frac{2V_{\mathrm{in}}-D}{1.1}
\]

相当于：

\[
V_{\mathrm{res,finite}}
\approx0.9091V_{\mathrm{res,ideal}}
\]

分段为：

\[
V_{\mathrm{res}}=
\begin{cases}
1.8182V_{\mathrm{in}},&V_{\mathrm{in}}<0.5\\
1.8182V_{\mathrm{in}}-0.9091,&V_{\mathrm{in}}\ge0.5
\end{cases}
\]

因此：

- 比较门限仍为 `0.5 V`。
- 两段斜率从 `2` 降为约 `1.8182`。
- 左侧峰值和右端点都降到约 `0.9091 V`。
- 残差没有充分利用下一级的输入范围。

从公式可以直接看出：\(A_0\) 越大，分母越接近 `1`，结果越接近理想情况。

---

## 七、生成输入并计算单级结果

对应第 29～33 行：

```matlab
Vin = linspace(0,VREF,nPoints).';
```

### 1. `linspace`

```matlab
linspace(0,VREF,nPoints)
```

生成从 `0` 到 `VREF`、包含两端点的等间隔序列。

这里步长是：

\[
\Delta V=\frac{1}{4001-1}=0.00025\text{ V}
\]

即 `0.25 mV`。

### 2. `.'`

`linspace` 默认生成行向量：

```matlab
[0, 0.00025, 0.00050, ..., 1]
```

`.'` 将它转成列向量。因此：

```matlab
size(Vin)
```

为：

```matlab
4001 × 1
```

`.'` 是非共轭转置。这里的数据是实数，所以用 `'` 数值上也相同。

### 3. 四次单级计算

```matlab
[VresIdeal,Dideal] = mdacStage(Vin,pIdeal);
[VresMismatch,Dmismatch] = mdacStage(Vin,pMismatch);
[VresOffset,Doffset] = mdacStage(Vin,pOffset);
[finiteResidue,finiteDecision] = mdacStage(Vin,pFinite);
```

每次都对同一组输入电压计算，只更换参数。

例如：

- `VresMismatch(i)`：第 `i` 个输入点在电容失配条件下的残差。
- `Dmismatch(i)`：同一个输入点对应的比较器判决。

所有这些输出都是 `4001×1` 列向量。

`finiteResidue` 和 `finiteDecision` 只是命名方式不同，作用与前面几组完全对应。

---

## 八、如何建立完整的 8 位 ADC？

对应第 40～54 行。

### 1. 生成八个理想级

```matlab
stagesIdeal = repmat(pIdeal,1,Nbits);
```

`repmat` 表示重复排列。

这里把 `pIdeal` 复制成一个 `1×8` 的结构体数组：

```matlab
stagesIdeal(1)
stagesIdeal(2)
...
stagesIdeal(8)
```

每个元素保存一级参数。

### 2. 只让第一级存在误差

```matlab
stagesMismatch = stagesIdeal;
stagesMismatch(1) = pMismatch;
```

得到：

```text
第 1 级：电容失配
第 2～8 级：理想
```

其余两组同理：

```matlab
stagesOffset(1) = pOffset;
stagesFinite(1) = pFinite;
```

**这里没有让每一级都带同样的误差。**

只修改第一级，有利于观察该级误差如何影响后面的量化结果。第一级还决定最高位，其残差误差会进入后续所有级。

### 3. 执行完整转换

```matlab
[codeIdeal,bitsIdeal,residuesIdeal] = pipelineADC(Vin,stagesIdeal);
```

三个输出分别是：

| 输出 | 尺寸 | 内容 |
|---|---|---|
| `codeIdeal` | 4001×1 | 每个输入对应的十进制数字码 |
| `bitsIdeal` | 4001×8 | 每个输入在各级产生的 8 个 bit |
| `residuesIdeal` | 4001×8 | 每个输入在各级入口处的电压 |

其他三次调用只是换了一组级参数。

---

## 九、逐行解释 `pipelineADC`

对应第 90～102 行。

### 1. 确定级数

```matlab
nBits = numel(stages);
```

`numel` 返回元素个数。

这里有八组参数，因此：

```matlab
nBits = 8;
```

由于模型每级产生一位，级数也就是输出位数。

### 2. 预分配残差数组

```matlab
residues = zeros(numel(vin),nBits);
```

对于 4001 个输入点、8 个级：

```matlab
residues
```

是 `4001×8` 的矩阵。

- 每一行：一个输入点的完整转换过程。
- 每一列：某一级接收到的输入电压。

预先分配数组，可以避免循环中不断扩展矩阵。

### 3. 第一列存原始输入

```matlab
residues(:,1) = vin(:);
```

`vin(:)` 将输入整理为列向量。

`residues(:,1)` 表示第一列的全部行。

这一点很容易看错：

> **`residues` 第一列不是第一级输出残差，而是第一级输入，也就是原始 `Vin`。**

具体对应关系：

| 列 | 含义 |
|---|---|
| 第 1 列 | 原始输入，即第一级输入 |
| 第 2 列 | 第一级输出，即第二级输入 |
| 第 3 列 | 第二级输出，即第三级输入 |
| … | … |
| 第 8 列 | 第七级输出，即第八级输入 |

### 4. 预分配判决矩阵

```matlab
bits = zeros(numel(vin),nBits);
```

同样生成一个 `4001×8` 矩阵。

其中：

```matlab
bits(i,k)
```

表示第 `i` 个输入点在第 `k` 级产生的 bit。

第一列是最高位，第八列是最低位。

### 5. 前七级逐级计算

```matlab
for k = 1:nBits-1
    [residues(:,k+1),bits(:,k)] = ...
        mdacStage(residues(:,k),stages(k));
end
```

对于 8 位 ADC，循环执行 `k=1～7`。

以第一级为例：

```matlab
[residues(:,2),bits(:,1)] = ...
    mdacStage(residues(:,1),stages(1));
```

意思是：

1. 取出第一级输入。
2. 使用第一级参数计算。
3. 把残差存入第二列。
4. 把判决存入第一位。

第二级再处理第二列，依此类推。

这里每次函数调用同时计算全部 4001 个输入点，所以不需要再写一层针对输入点的循环。

### 6. 最后一级只比较

```matlab
bits(:,nBits) = double(residues(:,nBits) >= ...
    stages(nBits).Vref/2+stages(nBits).Vos);
```

第八级只产生最后一位，不再生成残差。

原因是：已经得到全部 8 位，后面没有第九级需要接收剩余信息。

因此这套模型实际使用：

- 7 个产生残差的 MDAC 级。
- 1 个末级比较器。

末级参数中的 `C1`、`C2`、`A0` 没有在本函数中被使用。

### 7. 把八个 bit 转成十进制码

```matlab
code = bits*(2.^(nBits-1:-1:0)).';
```

拆开看。

首先：

```matlab
nBits-1:-1:0
```

产生：

```matlab
[7 6 5 4 3 2 1 0]
```

然后：

```matlab
2.^(nBits-1:-1:0)
```

得到：

```matlab
[128 64 32 16 8 4 2 1]
```

再转成列向量，与 `bits` 做矩阵乘法：

\[
\mathrm{code}
=128b_1+64b_2+32b_3+16b_4+8b_5+4b_6+2b_7+b_8
\]

注意这里的 `*` 必须表达矩阵乘法，因为需要把每行 bit 按权重相乘后求和。

矩阵尺寸为：

\[
(4001\times8)(8\times1)=4001\times1
\]

所以每个输入得到一个十进制数字码。

---

## 十、用一个例子走完整个转换过程

取理想情况：

\[
V_{\mathrm{in}}=0.7\text{ V},\qquad V_{\mathrm{REF}}=1\text{ V}
\]

每级按 `0.5 V` 比较，前七级再计算：

\[
V_{\mathrm{res}}=2V_{\mathrm{in}}-D
\]

结果为：

| 级数 | 本级输入 / V | 判决 | 输出残差 / V |
|---|---:|---:|---:|
| 1 | 0.7 | 1 | 0.4 |
| 2 | 0.4 | 0 | 0.8 |
| 3 | 0.8 | 1 | 0.6 |
| 4 | 0.6 | 1 | 0.2 |
| 5 | 0.2 | 0 | 0.4 |
| 6 | 0.4 | 0 | 0.8 |
| 7 | 0.8 | 1 | 0.6 |
| 8 | 0.6 | 1 | 不再计算 |

最终：

```text
10110011
```

转换为十进制：

\[
128+32+16+2+1=179
\]

也符合理想量化关系：

\[
\left\lfloor256\times0.7\right\rfloor=179
\]

对当前输入范围，理想输出可写为：

\[
\mathrm{code}
=
\min\left(
255,\left\lfloor256\frac{V_{\mathrm{in}}}{V_{\mathrm{REF}}}\right\rfloor
\right)
\]

其中 `min(255,...)` 用来说明满量程端点：输入恰好为 `VREF` 时，8 位输出仍只能是 `255`。

---

## 十一、画图代码在做什么？

对应第 59～76 行。

### 1. 创建图窗与布局

```matlab
figure('Color','w','Position',[100 100 1200 380]);
```

- 白色背景。
- 默认像素单位下，窗口位置为 `(100,100)`。
- 宽 1200，高 380。

```matlab
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
```

建立一行三列的子图，压缩子图间距和外边距。

### 2. 把三组结果放入 cell 数组

```matlab
residue = {VresMismatch,VresOffset,finiteResidue};
```

这里 `{}` 建立 cell 数组，每个单元里存一组残差向量。

```matlab
residue{k}
```

取出第 `k` 组向量。

对应标题：

```matlab
panelTitle = {'(a) Capacitor mismatch','(b) Comparator offset', ...
              '(c) Finite op-amp gain'};
```

### 3. 每幅图画两条线

```matlab
for k = 1:3
    nexttile;
    plot(Vin,VresIdeal,'k--',Vin,residue{k},'b-','LineWidth',1.5);
```

- `nexttile`：切换到下一个子图。
- `'k--'`：黑色虚线，理想残差。
- `'b-'`：蓝色实线，非理想残差。
- `LineWidth=1.5`：线宽。

三个子图始终使用同一条理想曲线作为比较基准。

### 4. 画参考上限

```matlab
yline(VREF,':','Color',[0.6 0.6 0.6],'HandleVisibility','off');
```

在：

\[
V_{\mathrm{res}}=V_{\mathrm{REF}}
\]

处画灰色点线，方便看出残差是否超过下一级输入范围。

`HandleVisibility='off'` 使这条辅助线不进入后面的自动图例。

### 5. 设置坐标范围

```matlab
xlim([0 VREF]);
ylim([-0.25 1.3]*VREF);
```

横轴覆盖整个输入范围。

纵轴故意扩展到：

\[
[-0.25,1.3]\text{ V}
\]

这样才能看到：

- 电容失配造成的负残差。
- 电容失配和比较器失调造成的上越界。

### 6. 美化坐标轴与图例

```matlab
set(gca,'FontName','Times New Roman','FontSize',12,'Box','off', ...
    'TickDir','out', ...
    'XTick',[0 0.5 1]*VREF,'XTickLabel',{'0','V_{REF}/2','V_{REF}'}, ...
    'YTick',[0 VREF],'YTickLabel',{'0','V_{REF}'});
```

`gca` 表示当前坐标轴。

这一段设置字体、字号、刻度位置、刻度标签和刻度线方向。

```matlab
xlabel('V_{in}');
ylabel('V_{res}');
title(panelTitle{k});
```

设置横轴、纵轴和标题。

```matlab
legend('Ideal','Nonideal','Location','southoutside', ...
    'Orientation','horizontal','Box','off');
```

把横排图例放在坐标轴下方外侧，并去掉边框。

还有一个读图细节：`plot` 会连接相邻采样点，所以门限附近会出现一段近似竖直的线。它表示静态传输关系的跳变，不是在模拟电压随时间的跳变过程。

---

## 十二、理解这份代码时，最需要注意的几点

### 1. `Nbits` 不影响目前画出的三幅图

三幅图使用的是：

```matlab
VresIdeal
VresMismatch
VresOffset
finiteResidue
```

这些都是单级计算结果。

修改：

```matlab
Nbits = 10;
```

会改变完整 ADC 的输出位数，但不会改变当前单级残差图。

### 2. 残差没有被限制在输入范围内

代码直接传递解析公式计算出来的残差，没有做限幅。

例如第一级输出 `−0.15 V`，第二级仍按公式处理这个负电压。

这样可以清楚暴露残差越界问题，但越界后的内部电压不一定等于真实电路行为。实际电路还可能受到电源轨、输出摆幅和饱和恢复等限制。

即便残差越界，最终 `code` 仍在 `0～255` 之间，因为它始终由八个 0/1 bit 加权组成。

### 3. 这里没有冗余级或数字纠错

程序直接使用：

\[
128b_1+64b_2+\cdots+b_8
\]

组合输出，属于直接的 1-bit/stage 模型。

因此，不能把这里比较器失调造成的结果，直接等同于带冗余和数字纠错的流水线 ADC。

### 4. 算出结果不等于已经完成性能验证

程序保存了完整 ADC 的输出，但没有进一步计算：

- DNL：每个实际码宽相对于理想码宽的偏差。
- INL：整体转换特性相对于理想直线的偏差。
- 缺码情况。
- 动态频谱指标。

所以目前最直接展示的是：**三种误差如何改变单级残差传输特性。**

---

## 总结

整份代码可以沿着这条主线理解：

```text
设置理想参数和三种误差参数
          ↓
扫描 0～VREF 的输入电压
          ↓
计算单级判决与残差
          ↓
串联各级，得到 8 位数字结果
          ↓
画出三种非理想残差与理想残差的对比
```

最重要的两个公式是：

\[
\boxed{
D=\operatorname{double}\left(
V_{\mathrm{in}}\ge\frac{V_{\mathrm{REF}}}{2}+V_{\mathrm{os}}
\right)
}
\]

\[
\boxed{
V_{\mathrm{res}}
=
\frac{(1+C_2/C_1)V_{\mathrm{in}}-(C_2/C_1)DV_{\mathrm{REF}}}
{1+(1+C_2/C_1)/A_0}
}
\]

前者决定**选哪条分支**，后者决定**该分支输出多少残差**。理解这两步，再理解各级如何传递残差、按位权组合判决，整份代码就串起来了。