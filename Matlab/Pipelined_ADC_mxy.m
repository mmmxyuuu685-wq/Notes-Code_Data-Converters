% Pipelined ADC: reproduce Figure 6 of A Tale of Two ADCs
% 来源：Behzad Razavi, "A Tale of Two ADCs: Pipelined Versus SAR"
% IEEE Solid-State Circuits Magazine, Summer 2015, pp. 38-46.
% DOI: 10.1109/MSSC.2015.2442372

clear; clc; close all;

% 1. 参数设置

VREF = 1;                       % V，单端输入范围 [0,VREF]
C1 = 1e-12;                     % F，静态模型实际只依赖电容比
mismatch = 0.30;                % C2/C1-1 = 30%
Vos = 0.10*VREF;                % 比较器offset
A0 = 20;                       % 有限运放直流开环增益（V/V）
                               % 若用 dB 指定：A0 = 10^(A0_dB/20)
nPoints = 4001;
Nbits = 8;                      % 附加级联验证的分辨率

pIdeal = struct('Vref',VREF,'C1',C1,'C2',C1,'A0',Inf,'Vos',0);

pMismatch = pIdeal;
pMismatch.C2 = (1+mismatch)*C1;
pOffset = pIdeal;
pOffset.Vos = Vos;
pFinite = pIdeal;
pFinite.A0 = A0;                

Vin = linspace(0,VREF,nPoints).';
[VresIdeal,Dideal] = mdacStage(Vin,pIdeal);
[VresMismatch,Dmismatch] = mdacStage(Vin,pMismatch);
[VresOffset,Doffset] = mdacStage(Vin,pOffset);
[finiteResidue,finiteDecision] = mdacStage(Vin,pFinite);



% 2. 系统建模
% 级联 N 位 1-bit/stage ADC，前 N-1 级 MDAC，末级比较器。仅让第一级有误差，其余级为理想级。

stagesIdeal = repmat(pIdeal,1,Nbits);

stagesMismatch = stagesIdeal;
stagesMismatch(1) = pMismatch;

stagesOffset = stagesIdeal;
stagesOffset(1) = pOffset;

stagesFinite = stagesIdeal;
stagesFinite(1) = pFinite;

[codeIdeal,bitsIdeal,residuesIdeal] = pipelineADC(Vin,stagesIdeal);
[codeMismatch,bitsMismatch,residuesMismatch] = pipelineADC(Vin,stagesMismatch);
[codeOffset,bitsOffset,residuesOffset] = pipelineADC(Vin,stagesOffset);
[codeFinite,bitsFinite,residuesFinite] = pipelineADC(Vin,stagesFinite);



% 3. 画图
figure('Color','w','Position',[100 100 1200 380]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
residue = {VresMismatch,VresOffset,finiteResidue};
panelTitle = {'(a) Capacitor mismatch','(b) Comparator offset', ...
              '(c) Finite op-amp gain'};
for k = 1:3
    nexttile;
    plot(Vin,VresIdeal,'k--',Vin,residue{k},'b-','LineWidth',1.5);
    yline(VREF,':','Color',[0.6 0.6 0.6],'HandleVisibility','off');
    xlim([0 VREF]); ylim([-0.25 1.3]*VREF);
    set(gca,'FontName','Times New Roman','FontSize',12,'Box','off', ...
        'TickDir','out', ...
        'XTick',[0 0.5 1]*VREF,'XTickLabel',{'0','V_{REF}/2','V_{REF}'}, ...
        'YTick',[0 VREF],'YTickLabel',{'0','V_{REF}'});
    xlabel('V_{in}'); ylabel('V_{res}'); title(panelTitle{k});
    legend('Ideal','Nonideal','Location','southoutside', ...
        'Orientation','horizontal','Box','off');
end



% 4. 本地函数

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
