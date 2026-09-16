figure('Color','w','Position',[100 100 1200 380]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
codes = {codeMismatch,codeOffset,codeFinite};
panelTitle = {'(a) Capacitor mismatch','(b) Comparator offset', ...
              '(c) Finite op-amp gain'};
for k = 1:3
    nexttile;
    stairs(Vin,codeIdeal,'k--','LineWidth',1.2); hold on;
    stairs(Vin,codes{k},'b-','LineWidth',1.2);
    xlim([0 VREF]); ylim([0 2^Nbits-1]);
    set(gca,'FontName','Times New Roman','FontSize',12,'Box','off', ...
        'TickDir','out');
    xlabel('V_{in} (V)'); ylabel('Output code'); title(panelTitle{k});
    legend('Ideal','Nonideal','Location','southoutside', ...
        'Orientation','horizontal','Box','off');
end
