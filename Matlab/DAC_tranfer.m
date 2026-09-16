clc;clear;close all;
% (ADC)对正弦信号采样量化为数字信号
N = 7;
n = 0:2^N-1;
fin = 10;
M = 37;
fs = 2^N/M*fin;
Ts = 1/fs;
t = -2^(N-1)*Ts:Ts:(2^(N-1)-1)*Ts;
x = tripuls(t,2^N*Ts,1);
% figure(1)
% plot(t,x)
LSB = 1/2^N;
x = round(x/LSB);%变为一个整数形式
% 将输入信号的十进制码变为二进制形式
a = zeros(2^N,N); %DAC的输入为N位数字码
code = zeros(2^N,1);
for i=1:2^N
b = dec2bin(x(i),N);
for j=1:N
code(i) = code(i)+2^(-j)*b(j);
a(i,j) = str2num(b(j));
end
end
% 模拟3+4bit的DAC(高三位任意，只要权重求和与原来相同即可;第四位为二进制加权)
dac_out = zeros(2^N,1);
dac_out = dac_out+0.4*a(:,1)+0.29*a(:,2)+0.185*a(:,3);
c = 0.125;
for i=4:N
c = c/2;
dac_out = dac_out + c*a(:,i);
end
%画出传输特性曲线
plot(code,dac_out);
% scatter(code,dac_out);