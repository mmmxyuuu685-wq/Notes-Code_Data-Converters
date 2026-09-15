%% Pipelined ADC: reproduce Figure 6 of A Tale of Two ADCs
% 来源：Behzad Razavi, "A Tale of Two ADCs: Pipelined Versus SAR",
% IEEE Solid-State Circuits Magazine, Summer 2015, pp. 38-46.
% DOI: 10.1109/MSSC.2015.2442372，图 6 位于印刷页 41（PDF 第 4 页）。
%
% 注意：图 6(b) 的图注写为 finite op-amp gain，但正文（p.40）及
% 图中的 V_OS 标记均指向 comparator offset。本程序按正文和图形复现。
% 图 6 是单端 1-bit/stage MDAC 的静态残差图，不是 1.5-bit/stage
% 的差分残差图（后者见图 7），也不是 FFT 频谱。
%
% 建模：C1 为反馈电容，r = C2/C1，D = double(Vin >= VREF/2 + Vos)。
% 理想采样后，由电荷守恒得
%   (C1+C2)*Vin = C1*Vres + C2*D*VREF - (C1+C2)*Vx.
% 令 Vx = -Vres/A0，则
%   Vres = ((1+r)*Vin - r*D*VREF)/(1+(1+r)/A0).
% A0=Inf、r=1 时退化为原文式 (1)、(2)：Vres=2*Vin-D*VREF。
% Vos>0 在此定义为判决阈值向右移动，避免不同失调符号约定的混淆。
% 有限增益项假定采样理想、忽略寄生电容，仅描述放大相的静态误差。
% 不裁剪残差，否则会掩盖论文关注的 overrange/underrange。
%
% 运行：在编辑器中点击 Run，或 run('Matlab/Pipelined-ADC.m')。
% 无需额外工具箱。自动保存 PNG、FIG 到脚本旁的 Pipelined_ADC_results。
% 附带 N 位级联行为模型及理想量化检查；不模拟时钟、流水线延迟、
% 建立时间、热噪声、数字校准等图 6 未涉及的效应。

clear; clc; close all;

%% 1. 参数：论文图 6 未提供数值，以下仅选择便于观察的示意值
VREF = 1;                       % V，单端输入范围 [0,VREF]
C1 = 1e-12;                     % F，静态模型实际只依赖电容比
mismatch = 0.30;                % C2/C1-1 = 30%，用于突出图 6(a) 的形状
Vos = 0.10*VREF;                % V，用于突出图 6(b) 的右移和越界
nPoints = 4001;
Nbits = 8;                      % 附加级联验证的分辨率，非论文指定值

pIdeal = struct('Vref',VREF,'C1',C1,'C2',C1,'A0',Inf,'Vos',0);
pMismatch = pIdeal;
pMismatch.C2 = (1+mismatch)*C1;
pOffset = pIdeal;
pOffset.Vos = Vos;
% 可在上述参数中设置 A0（线性开环增益，而非 dB）来研究有限增益；
% 为单独复现失配和失调，两幅图默认均取 A0=Inf。

Vin = linspace(0,VREF,nPoints).';
[VresIdeal,Dideal] = mdacStage(Vin,pIdeal);
[VresMismatch,Dmismatch] = mdacStage(Vin,pMismatch);
[VresOffset,Doffset] = mdacStage(Vin,pOffset);

%% 2. 图 6：虚线为理想残差，实线为带误差的残差
fig6 = figure('Color','w','Name','A Tale of Two ADCs - Figure 6', ...
    'Position',[100 100 1200 540]);
layout = tiledlayout(fig6,1,2,'TileSpacing','compact','Padding','compact');
layout = tiledlayout(fig6,1,2,'TileSpacing','compact','Padding','loose');
title(layout,'Pipelined ADC: MDAC residue (Figure 6)', 'FontSize',16);
subtitle(layout,'Illustrative parameters; panel (b) follows the text and V_{OS} label', ...
    'FontSize',11);

ax1 = nexttile(layout);
drawResiduePanel(ax1,pIdeal,pMismatch);
title(ax1,'(a) Capacitor mismatch: C_2 > C_1');
r = pMismatch.C2/pMismatch.C1;
peakMismatch = (1+r)*VREF/2;    % 阈值左极限；阈值处实际采用 D=1
lowMismatch = (1-r)*VREF/2;     % 阈值右极限
plot(ax1,[0.5 1.04]*VREF,[peakMismatch peakMismatch],':', ...
    'Color',[0.45 0.45 0.45],'HandleVisibility','off');
plot(ax1,[0.5 0.73]*VREF,[lowMismatch lowMismatch],':', ...
    'Color',[0.45 0.45 0.45],'HandleVisibility','off');
drawVerticalRange(ax1,1.035*VREF,VREF,peakMismatch);
text(ax1,0.76*VREF,1.23*VREF,'Overrange','FontSize',11);
text(ax1,0.56*VREF,-0.24*VREF,'Underrange','FontSize',10);
text(ax1,0.70*VREF,-0.22*VREF,'Underrange','FontSize',10);
text(ax1,0.05*VREF,1.23*VREF,sprintf('C_2/C_1 = %.2f',r),'FontSize',11);

ax2 = nexttile(layout);
drawResiduePanel(ax2,pIdeal,pOffset);
title(ax2,'(b) Comparator offset');
threshold = VREF/2+Vos;
peakOffset = 2*threshold;       % 越界高度为 2*Vos
plot(ax2,[threshold 1.04*VREF],[peakOffset peakOffset],':', ...
    'Color',[0.45 0.45 0.45],'HandleVisibility','off');
drawVerticalRange(ax2,1.035*VREF,VREF,peakOffset);
text(ax2,0.76*VREF,1.27*VREF,'Overrange','FontSize',11);
plot(ax2,[VREF/2 threshold],[0.46 0.46]*VREF,'k-', ...
    'HandleVisibility','off');
plot(ax2,VREF/2,0.46*VREF,'k<','MarkerFaceColor','k','HandleVisibility','off');
plot(ax2,threshold,0.46*VREF,'k>','MarkerFaceColor','k','HandleVisibility','off');
text(ax2,(VREF/2+threshold)/2,0.35*VREF,'V_{OS}', ...
    'HorizontalAlignment','center','FontSize',12);
text(ax2,0.05*VREF,1.23*VREF,sprintf('V_{OS} = %.2f V_{REF}',Vos/VREF), ...
    'FontSize',11);

%% 3. 级联 N 位 1-bit/stage ADC：前 N-1 级 MDAC，末级比较器
% 同一输入样本依次传过各级；输出 bits 已按同一样本对齐。
% 示意非理想系统仅让第一级有误差，其余级为理想级。
stagesIdeal = repmat(pIdeal,1,Nbits);
stagesMismatch = stagesIdeal;
stagesMismatch(1) = pMismatch;
stagesOffset = stagesIdeal;
stagesOffset(1) = pOffset;
[codeIdeal,bitsIdeal,residuesIdeal] = pipelineADC(Vin,stagesIdeal);
[codeMismatch,bitsMismatch,residuesMismatch] = pipelineADC(Vin,stagesMismatch);
[codeOffset,bitsOffset,residuesOffset] = pipelineADC(Vin,stagesOffset);

%% 4. 数值检查（不用从离散网格估算跳变点的峰值）
idealCode = min(floor(Vin/VREF*2^Nbits),2^Nbits-1);
assert(isequal(codeIdeal,idealCode),'Ideal pipeline does not match ideal quantization.');
assert(all(VresIdeal >= 0 & VresIdeal <= VREF),'Ideal residue out of range.');
assert(abs(peakMismatch-VREF-mismatch*VREF/2) < 1e-12*VREF);
assert(abs(lowMismatch+mismatch*VREF/2) < 1e-12*VREF);
assert(abs(peakOffset-VREF-2*Vos) < 1e-12*VREF);
% A0 有限时，放大相增益按 1/(1+(1+r)/A0) 缩小，阈值保持不变。
pFinite = pIdeal;
pFinite.A0 = 100;
[finiteResidue,finiteDecision] = mdacStage(Vin,pFinite);
assert(isequal(finiteDecision,Dideal));
assert(max(abs(finiteResidue-VresIdeal/(1+2/pFinite.A0))) < 1e-12*VREF);

fprintf('Figure 6 reproduction (illustrative parameter values)\n');
fprintf('(a) C2/C1 = %.2f: upper overrange = %.4f V, lower underrange = %.4f V\n', ...
    r,peakMismatch-VREF,-lowMismatch);
fprintf('(b) Vos = %.4f V: threshold = %.4f V, upper overrange = %.4f V\n', ...
    Vos,threshold,peakOffset-VREF);
fprintf('Ideal %d-bit pipeline: all %d ramp samples passed.\n',Nbits,numel(Vin));
fprintf('First-stage errors: maximum absolute output error = %.0f LSB (mismatch), %.0f LSB (offset).\n', ...
    max(abs(codeMismatch-codeIdeal)),max(abs(codeOffset-codeIdeal)));

%% 5. 导出图形；所有各级残差、判决位及输出码同时保留在工作区
scriptDir = fileparts(mfilename('fullpath'));
outDir = fullfile(scriptDir,'Pipelined_ADC_results');
if ~exist(outDir,'dir')
    mkdir(outDir);
end
exportgraphics(fig6,fullfile(outDir,'Figure6_reproduction.png'),'Resolution',200);
savefig(fig6,fullfile(outDir,'Figure6_reproduction.fig'));
fprintf('Figure saved to: %s\n',outDir);

%% 本地函数
function [vout,decision] = mdacStage(vin,p)
% 单端 1-bit MDAC：比较器、1-bit DAC、相减和残差放大。
    ratio = p.C2/p.C1;
    decision = double(vin >= p.Vref/2+p.Vos);
    vout = ((1+ratio).*vin-ratio.*decision*p.Vref) ...
        /(1+(1+ratio)/p.A0);
end

function [code,bits,residues] = pipelineADC(vin,stages)
% 未裁剪的解析残差用于观察越界；末级仅量化、不再生成残差。
    nBits = numel(stages);
    residues = zeros(numel(vin),nBits);
    residues(:,1) = vin(:);
    bits = zeros(numel(vin),nBits);
    for k = 1:nBits-1
        [residues(:,k+1),bits(:,k)] = mdacStage(residues(:,k),stages(k));
    end
    bits(:,nBits) = double(residues(:,nBits) >= ...
        stages(nBits).Vref/2+stages(nBits).Vos);
    code = bits*(2.^(nBits-1:-1:0)).';
end

function drawResiduePanel(ax,pIdeal,pError)
% 分支分别绘制，精确显示阈值两侧极限；竖线仅为论文式跳变示意。
    hold(ax,'on');
    ax.Color = [0.92 0.97 0.92];
    hIdeal = drawBranches(ax,pIdeal,'--',[0.45 0.45 0.45],1.3);
    hError = drawBranches(ax,pError,'-',[0.10 0.10 0.10],1.9);
    yline(ax,pIdeal.Vref,':','Color',[0.25 0.25 0.25], ...
        'HandleVisibility','off');
    xlim(ax,[0 1.12]*pIdeal.Vref);
    ylim(ax,[-0.28 1.40]*pIdeal.Vref);
    ax.XAxisLocation = 'origin';
    ax.YAxisLocation = 'origin';
    ax.XTick = [0 0.5 1]*pIdeal.Vref;
    ax.XTickLabel = {'0','V_{REF}/2','V_{REF}'};
    ax.XTickLabel = {'0','','V_{REF}'};
    text(ax,0.5*pIdeal.Vref,-0.19*pIdeal.Vref,'V_{REF}/2', ...
        'HorizontalAlignment','center','VerticalAlignment','top','FontSize',11);
    ax.YTick = [0 1]*pIdeal.Vref;
    ax.YTickLabel = {'0','V_{REF}'};
    ax.FontSize = 11;
    ax.TickLabelInterpreter = 'tex';
    box(ax,'off');
    xlabel(ax,'V_{in}');
    ylabel(ax,'V_{res}');
    legend(ax,[hIdeal hError],{'Ideal','Nonideal'}, ...
        'Location','southoutside','Orientation','horizontal','Box','off');
end

function h = drawBranches(ax,p,lineStyle,color,lineWidth)
    threshold = p.Vref/2+p.Vos;
    assert(threshold > 0 && threshold < p.Vref, ...
        'The plotted decision threshold must be inside (0,Vref).');
    ratio = p.C2/p.C1;
    gainDenom = 1+(1+ratio)/p.A0;
    xLow = [0 threshold];
    xHigh = [threshold p.Vref];
    yLow = (1+ratio)*xLow/gainDenom;
    yHigh = ((1+ratio)*xHigh-ratio*p.Vref)/gainDenom;
    h = plot(ax,xLow,yLow,lineStyle,'Color',color,'LineWidth',lineWidth);
    plot(ax,xHigh,yHigh,lineStyle,'Color',color,'LineWidth',lineWidth, ...
        'HandleVisibility','off');
    plot(ax,[threshold threshold],[yLow(end) yHigh(1)],lineStyle, ...
        'Color',color,'LineWidth',lineWidth,'HandleVisibility','off');
end

function drawVerticalRange(ax,x,yLow,yHigh)
    plot(ax,[x x],[yLow yHigh],'k-','HandleVisibility','off');
    plot(ax,x,yLow,'k^','MarkerFaceColor','k','HandleVisibility','off');
    plot(ax,x,yHigh,'kv','MarkerFaceColor','k','HandleVisibility','off');
end