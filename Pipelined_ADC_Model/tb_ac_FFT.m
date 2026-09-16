clear; clc; close all;
addpath(fileparts(mfilename('fullpath')));

parameters;
system_model;

noisePower = 1e-8;              % 输入白噪声功率（方差），V^2；设为 0 关闭
useHann = true;                 % true：Hann 窗；false：矩形窗
rng(1);                         % 固定随机种子，便于比较

assert(isscalar(noisePower) && isfinite(noisePower) && noisePower>=0, ...
    'noisePower must be a finite nonnegative scalar (V^2).');
t = (0:Nfft-1).'/Fs;
Vin = Vcm+Ain*sin(2*pi*Fin*t)+sqrt(noisePower)*randn(Nfft,1);
stages = {stagesIdeal,stagesMismatch,stagesOffset,stagesFinite};
codes = zeros(Nfft,4);
for k = 1:4
    codes(:,k) = model.pipelineADC(Vin,stages{k});
end

result = analyzeSpectrum(codes*VREF/2^Nbits,Fs,Fin,VREF,useHann);

plot_FFT;
plot_PSD;

function result = analyzeSpectrum(vout,Fs,Fin,Vref,useHann)
    N = size(vout,1);
    tone = Fin*N/Fs;
    w = ones(N,1);
    if useHann
        w = 0.5-0.5*cos(2*pi*(0:N-1).'/N);   
    end
    vout = vout-mean(vout,1);                  
    Y = fft(vout.*w)/sqrt(N*sum(w.^2));       
    power = abs(Y(1:N/2+1,:)).^2;
    power(2:end-1,:) = 2*power(2:end-1,:);     
    signalBins = round(tone)+1+(-double(useHann):double(useHann));
    signal = sum(power(signalBins,:),1);
    noise = power;
    noise([1 signalBins],:) = 0;             
    result.f = (0:N/2).'*Fs/N;
    result.PSD = power/(Fs/N);               
    result.FFT_dBFS = 10*log10(max(power/(Vref^2/8),realmin));
    result.SINAD = 10*log10(signal./sum(noise,1));
    result.ENOB = (result.SINAD-1.76)/6.02;   
end
