clc
clear
close all

filename='20210825_101003_cycle2cycle.txt';
fid=fopen(filename);

t_prog=200e-6;
t_erase=100e-6;

tline = fgetl(fid);

Gtrace={};
lin=1;
cycle=1;
while ~feof(fid)
    tline = fgetl(fid);
    if mod(lin,2)==1
        Gtrace(cycle).Gprog=str2num(tline(7:end));
    else
        Gtrace(cycle).Gerase=str2num(tline(7:end));
        cycle=cycle+1;
    end
    lin=lin+1;
end
fclose(fid);


fig=figure(1);
fig.Position=[100 342 1200 380];
Pulse_n_cycle=zeros(1,numel(Gtrace)+1);

for cyc=1:numel(Gtrace)
    Gprog=Gtrace(cyc).Gprog;
    Gerase=Gtrace(cyc).Gerase;
    Gcycle=[Gprog,Gerase];
    Pulse_n_cycle(cyc+1)=Pulse_n_cycle(cyc)+numel(Gcycle);
end

gap=50;
for cyc=1:numel(Gtrace)
    Gprog=Gtrace(cyc).Gprog;
    Gerase=Gtrace(cyc).Gerase;
    Gcycle=[Gprog,Gerase];
    
    range1=[0,Pulse_n_cycle(6)];
    range1_ax=range1;
    if (cyc>=1 && cyc<=5)
        PulseN=Pulse_n_cycle(cyc)+(0:numel(Gcycle)-1);
        lin1=semilogy(PulseN,Gcycle,'s-','linewidth',2,'color','b','markerfacecolor','w');hold on
    end 
    range2=[Pulse_n_cycle(101), Pulse_n_cycle(106)];
    range2_ax=range2-range2(1)+range1_ax(2)+gap;
    if (cyc>=101 && cyc<=105) 
        PulseN=Pulse_n_cycle(cyc)-range2(1)+range1_ax(2)+gap+(0:numel(Gcycle)-1);
        semilogy(PulseN,Gcycle,'s-','linewidth',2,'color','b','markerfacecolor','w');hold on
    end
    
    range3=[Pulse_n_cycle(numel(Gtrace)-5), Pulse_n_cycle(numel(Gtrace)+1)];
    range3_ax=range3-range3(1)+range2_ax(2)+gap;
    if (cyc>=numel(Gtrace)-5 && cyc<=numel(Gtrace)) 
        PulseN=Pulse_n_cycle(cyc)-range3(1)+range2_ax(2)+gap+(0:numel(Gcycle)-1);
        semilogy(PulseN,Gcycle,'s-','linewidth',2,'color','b','markerfacecolor','w');hold on
    end
end

ticks1=[0,100,200,300];
ticks2=[10200:200:10700];
ticks3=[52600:200:53600];
xticks([ticks1,ticks2-range2(1)+range1_ax(2)+gap,ticks3-range3(1)+range2_ax(2)+gap])
labels={};
for i=1:numel(ticks1)
    labels{i}=num2str(ticks1(i));
end
for i=(1:numel(ticks2))
    labels{numel(ticks1)+i}=num2str(ticks2(i));
end
for i=(1:numel(ticks3))
    labels{numel(ticks1)+numel(ticks2)+i}=num2str(ticks3(i));
end
xticklabels(labels)

xlim([-10,2030])
ylim([7e-10,1.2e-6])
xlabel('Pulse number');
ylabel('G=I_R/V_R [S]');
ax=gca;
set(ax,'fontsize',15,'linewidth',2);
set(ax,'box','off')
ax.Position=[0.07,0.15,0.9,0.7];
ax.YScale='log';

% setup top axis
ax_top = axes('Position',ax.Position);
hold(ax_top);
xlim(ax.XLim)
ylim(ax.YLim)
ax_top.XAxisLocation = 'top';
ax_top.YAxisLocation = "right";
ax_top.YTick = [];
ax_top.YScale='log';
ax_top.Color = 'none';
xlabel(ax_top, 'Cycle');
set(gca,'fontsize',15,'linewidth',2);

ax_top_ticks1=0:5;
ax_top_ticks2=101:105;
ax_top_ticks3=395:400;
xticks([Pulse_n_cycle(ax_top_ticks1+1),...
    Pulse_n_cycle(ax_top_ticks2+1)-range2(1)+range1_ax(2)+gap,...
    Pulse_n_cycle(ax_top_ticks3+1)-range3(1)+range2_ax(2)+gap])
labels={};
for i=1:numel(ax_top_ticks1)
    labels{i}=num2str(ax_top_ticks1(i));
end
for i=(1:numel(ax_top_ticks2))
    labels{numel(ax_top_ticks1)+i}=num2str(ax_top_ticks2(i));
end
for i=(1:numel(ax_top_ticks3))
    labels{numel(ax_top_ticks1)+numel(ax_top_ticks2)+i}=num2str(ax_top_ticks3(i));
end
xticklabels(labels)


Nprog=200;
Nerase=200;
mem.tp_prog=200e-6;
mem.tp_erase=100e-6;

% parameters for Va and beta degradation with cycling
pa.cyc=struct('Va0', 22.5, 'Va_max', 24, 'tau_Va', 1,...
            'beta0', 8, 'beta_max', 11.5, 'tau_beta', 0.5);
% parameter for read out transistor
pa.pa_r=struct('Vth', 0.87,  'K', 1.7e-5,  'Is0', 3e-8,  'n', 1.85,...  % transistor I-V parameter
      'Prob0', 0,  'Va', 0,...                 % parameters for hot electron injection
      'beta', 10,   'Vbi', 5,  'xi', 2.5e-8...   % paprameter for tunneling current to gate 
      );
% parameter for injection transistor
pa.pa_i=struct('Vth', 0.87+0.45, 'K', 1.7e-5*2, 'Is0', 3e-8*2,  'n', 1.85*1.3,...
      'Prob0', 5e-3,  'Va', pa.cyc.Va0, ...
      'beta', pa.cyc.beta0,     'Vbi' , 5,  'xi'  , 3e-9...
      );  
col=[1,1,1]*0.9;

for ww=1:400  
    G=[];
    if ww==1
        qfg=-0.7e-11;
    end
    [~,~,g]=prog_yflash(pa,qfg,0);
    G(1)=g;
    for i=2:Nprog
        [pa, qfg,g]=prog_yflash(pa,qfg,mem.tp_prog);
        G(i)=g;
        if g<0.9e-9
            break
        end
    end
    Gtrace_sim(ww).Gprog=G;
    
    G=[];
    [~, ~,g]=erase_yflash(pa,qfg,0);
    G(1)=g;
    for i=2:Nerase
        [pa, qfg,g]=erase_yflash(pa,qfg,mem.tp_erase);
        G(i)=g;
        if g>1.05e-6
            break
        end
    end
    Gtrace_sim(ww).Gerase=G;
    
end

gap=50;
for cyc=1:numel(Gtrace)
    Gprog=Gtrace_sim(cyc).Gprog;
    Gerase=Gtrace_sim(cyc).Gerase;
    Gcycle=[Gprog,Gerase];
    
    range1=[0,Pulse_n_cycle(6)];
    range1_ax=range1;
    if (cyc>=1 && cyc<=5)
        PulseN=Pulse_n_cycle(cyc)+(0:numel(Gcycle)-1);
        semilogy(PulseN,Gcycle,'-','linewidth',1.5,'color','r','markerfacecolor','w');hold on
    end 
    range2=[Pulse_n_cycle(101), Pulse_n_cycle(106)];
    range2_ax=range2-range2(1)+range1_ax(2)+gap;
    if (cyc>=101 && cyc<=105) 
        PulseN=Pulse_n_cycle(cyc)-range2(1)+range1_ax(2)+gap+(0:numel(Gcycle)-1);
        semilogy(PulseN,Gcycle,'-','linewidth',1.5,'color','r','markerfacecolor','w');hold on
    end
    
    range3=[Pulse_n_cycle(numel(Gtrace)-5), Pulse_n_cycle(numel(Gtrace)+1)];
    range3_ax=range3-range3(1)+range2_ax(2)+gap;
    if (cyc>=numel(Gtrace)-5 && cyc<=numel(Gtrace)) 
        PulseN=Pulse_n_cycle(cyc)-range3(1)+range2_ax(2)+gap+(0:numel(Gcycle)-1);
        lin2=semilogy(PulseN,Gcycle,'-','linewidth',1.5,'color','r','markerfacecolor','w');hold on
    end
end

legend(ax_top,[lin1,lin2],{'Data','Model'},'location','southeast','color','w')
