clc
clear
close all

Vread=linspace(0,3,100);
Qfg=(-0.6:-0.3:-1.8)*1e-11;

for n=1:numel(Qfg)
    Iread=zeros(1,numel(Vread));
    for i=1:numel(Vread)
       qfg=Qfg(n);
       [~, Iread(i), ~, ~] = yflash(qfg, Vread(i), 0, 0, 0);
    end
    
    figure(1)
    Iread(Iread<1e-12)=1e-12; % too small current wouldn't be able to be measured out.
    semilogy(Vread,Iread,'s','linewidth',2,'markersize',8,'markerfacecolor','w');hold on;
    xlabel('V_{Read} [V]');
    ylabel('I_{Read} [A]');
    set(gca,'linewidth',2,'fontsize',15)

end