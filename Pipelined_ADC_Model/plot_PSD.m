caseName = {'Ideal','Capacitor mismatch','Comparator offset','Finite op-amp gain'};
figure('Color','w','Position',[100 100 1100 650]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
for k = 1:4
    nexttile;
    plot(result.f/1e3,10*log10(max(result.PSD(:,k),realmin)), ...
        'b-','LineWidth',1);
    xlim([0 Fs/2e3]);
    ylim(10*log10(max(result.PSD(:)))+[-120 5]);
    set(gca,'FontName','Times New Roman','FontSize',12,'Box','off', ...
        'TickDir','out');
    xlabel('Frequency (kHz)'); ylabel('PSD (dB re 1 V^2/Hz)');
    title(caseName{k});
end
