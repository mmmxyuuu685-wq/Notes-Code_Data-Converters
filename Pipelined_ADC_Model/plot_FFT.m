caseName = {'Ideal','Capacitor mismatch','Comparator offset','Finite op-amp gain'};
figure('Color','w','Position',[100 100 1100 650]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
for k = 1:4
    nexttile;
    plot(result.f/1e3,result.FFT_dBFS(:,k),'b-','LineWidth',1);
    xlim([0 Fs/2e3]); ylim([-140 5]);
    set(gca,'FontName','Times New Roman','FontSize',12,'Box','off', ...
        'TickDir','out');
    xlabel('Frequency (kHz)'); ylabel('Power/bin (dBFS)');
    title(sprintf('%s: SINAD %.2f dB, ENOB %.2f', ...
        caseName{k},result.SINAD(k),result.ENOB(k)));
end
