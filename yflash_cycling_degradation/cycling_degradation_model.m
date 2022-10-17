clc
clear
close all

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
        if g<1e-9
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
        if g>1e-6
            break
        end
    end
    Gtrace_sim(ww).Gerase=G;
end

program_time_sim=zeros(1,numel(Gtrace_sim));
erase_time_sim=zeros(1,numel(Gtrace_sim));
for cyc=1:numel(Gtrace_sim)
    program_time_sim(cyc)=numel(Gtrace_sim(cyc).Gprog)*mem.tp_prog;
    erase_time_sim(cyc)=numel(Gtrace_sim(cyc).Gerase)*mem.tp_erase;
end


fig=figure(1);
col=[1,1,1]*0.9;
for cyc=1:numel(Gtrace_sim)
    subplot(1,2,1)
    Gprog=Gtrace_sim(cyc).Gprog;
    semilogy(1:numel(Gprog),Gprog,'s-','color',col);hold on
    subplot(1,2,2)
    Gerase=Gtrace_sim(cyc).Gerase;
    semilogy(1:numel(Gerase),Gerase,'s-','color',col);hold on
end
% polt program and erase trace for all cycles
cyc=200;
subplot(1,2,1)
Gprog=Gtrace_sim(cyc).Gprog;
semilogy(1:numel(Gprog),Gprog,'rs-','linewidth',2,'markerfacecolor','w');hold on
subplot(1,2,2)
Gerase=Gtrace_sim(cyc).Gerase;
semilogy(1:numel(Gerase),Gerase,'rs-','linewidth',2,'markerfacecolor','w');hold on

subplot(1,2,1)
xlabel('Pulse Number');ylabel('G [S]');
ylim([8e-10,1.2e-6]);
set(gca,'fontsize',15,'linewidth',1.5)
subplot(1,2,2)
xlabel('Pulse Number');ylabel('G [S]');
ylim([8e-10,1.2e-6]);
set(gca,'fontsize',15,'linewidth',1.5)
fig.Position=[260 300 1200 420];


% compare data with model
filename='data_cycle2cycle.txt';
fid=fopen(filename);

t_prog=200e-6;
t_erase=100e-6;

tline = fgetl(fid);
disp(tline)

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


program_time=zeros(1,numel(Gtrace));
erase_time=zeros(1,numel(Gtrace));
for cyc=1:numel(Gtrace)
    program_time(cyc)=numel(Gtrace(cyc).Gprog)*t_prog;
    erase_time(cyc)=numel(Gtrace(cyc).Gerase)*t_erase;
end

% program and erase time as a function of cycle
figure(3)
plot(1:numel(program_time),program_time,'color','b','marker','s','linestyle','-','markersize',10,'linewidth',2.5,'markerfacecolor','w');
hold on;
xlabel('Cycle');
ylabel('Full program time [s]');
set(gca,'fontsize',15,'linewidth',2)

figure(4)
plot(1:numel(erase_time),erase_time,'color','b','marker','s','linestyle','-','markersize',10,'linewidth',2.5,'markerfacecolor','w');
hold on;
xlabel('Cycle');
ylabel('Full erase time [s]');
set(gca,'fontsize',15,'linewidth',2)

% program and erase time as a function of cycle
figure(3)
plot(1:numel(program_time_sim),program_time_sim,'color','r','marker','none','linestyle','-','markersize',10,'linewidth',2.5,'markerfacecolor','w');
legend({'Data','Model'},'location','SouthEast')
figure(4)
plot(1:numel(erase_time_sim),erase_time_sim,'color','r','marker','none','linestyle','-','markersize',10,'linewidth',2.5,'markerfacecolor','w');
legend({'Data','Model'},'location','SouthEast')
