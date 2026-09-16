VREF = 1;                       % V，单端输入范围 [0,VREF]
C1 = 1e-12;                     % F，静态模型实际只依赖电容比
mismatch = 0.30;                % C2/C1-1 = 30%
Vos = 0.10*VREF;                % 比较器offset
A0 = 20;                       % 有限运放直流开环增益（V/V）
                               % 若用 dB 指定：A0 = 10^(A0_dB/20)
nPoints = 4001;
Nbits = 8;                      % 附加级联验证的分辨率

Fs = 1e6;                      % Hz，动态测试采样率
Nfft = 2^14;                    % 偶数采样点数
nCycles = 127;                  % 整数周期数，与 Nfft 互质，保证相干采样
Fin = nCycles*Fs/Nfft;
Ain = 0.499*VREF;               % 正弦峰值，接近满量程
Vcm = VREF/2;                   % 输入直流偏置

pIdeal = struct('Vref',VREF,'C1',C1,'C2',C1,'A0',Inf,'Vos',0);

pMismatch = pIdeal;
pMismatch.C2 = (1+mismatch)*C1;
pOffset = pIdeal;
pOffset.Vos = Vos;
pFinite = pIdeal;
pFinite.A0 = A0;                

