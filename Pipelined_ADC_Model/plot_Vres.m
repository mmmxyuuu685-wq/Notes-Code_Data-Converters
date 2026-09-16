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



