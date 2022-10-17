clc
clear
close all

Nprog=100;
Nerase=100;
mem.tp_prog=200e-6;
mem.tp_erase=100e-6;

% parameter for read out transistor
pa.pa_r=struct('Vth', 0.87,  'K', 1.7e-5,  'Is0', 3e-8,  'n', 1.85,...  % transistor I-V parameter
      'Prob0', 0,  'Va', 0,...                 % parameters for hot electron injection
      'beta', 10,   'Vbi', 5,  'xi', 2.5e-8...   % paprameter for tunneling current to gate 
      );
% parameter for injection transistor
pa.pa_i=struct('Vth', 0.87+0.45, 'K', 1.7e-5*2, 'Is0', 3e-8*2,  'n', 1.85*1.3,...
      'Prob0', 5e-3,  'Va', 22, ...
      'beta', 9,     'Vbi' , 5,  'xi'  , 7e-9...
      );  
col=[1,1,1]*0.9;

for ww=1:500
    pa.pa_i.Va=random('normal',23.4,0.8);
    pa.pa_i.beta=random('normal',9,0.8);
    
    qfg=-0.85e-11;
    Qfg=zeros(1,Nprog);
    G=[];
    Qfg(1)=qfg;
    [~,g]=prog_yflash(pa,qfg,0);
    G(1)=g;
    for i=2:Nprog
        [qfg,g]=prog_yflash(pa,qfg,mem.tp_prog);
        Qfg(i)=qfg;
        G(i)=g;
        if g<1e-9
            break
        end
    end
    Gtrace_sim(ww).Gprog=G;
    
    qfg=-1.9e-11;
    Qfg=zeros(1,Nerase);
    G=[];
    Qfg(1)=qfg;
    [~,g]=erase_yflash(pa,qfg,0);
    G(1)=g;
    for i=2:Nerase
        [qfg,g]=erase_yflash(pa,qfg,mem.tp_erase);
        Qfg(i)=qfg;
        G(i)=g;
        if g>1e-6
            break
        end
    end
    Gtrace_sim(ww).Gerase=G;
end

program_time_sim=zeros(1,numel(Gtrace_sim));
erase_time_sim=zeros(1,numel(Gtrace_sim));
for dd=1:numel(Gtrace_sim)
    program_time_sim(dd)=numel(Gtrace_sim(dd).Gprog)*mem.tp_prog;
    erase_time_sim(dd)=numel(Gtrace_sim(dd).Gerase)*mem.tp_erase;
end

fig=figure(1);
col=[1,1,1]*0.9;
for dd=1:numel(Gtrace_sim)
    subplot(1,2,1)
    Gprog=Gtrace_sim(dd).Gprog;
    semilogy(1:numel(Gprog),Gprog,'s-','color',col);hold on
    subplot(1,2,2)
    Gerase=Gtrace_sim(dd).Gerase;
    semilogy(1:numel(Gerase),Gerase,'s-','color',col);hold on
end

dd=29;
subplot(1,2,1)
Gprog=Gtrace_sim(dd).Gprog;
semilogy(1:numel(Gprog),Gprog,'rs-','linewidth',2,'markerfacecolor','w');hold on
subplot(1,2,2)
Gerase=Gtrace_sim(dd).Gerase;
semilogy(1:numel(Gerase),Gerase,'bs-','linewidth',2,'markerfacecolor','w');hold on

subplot(1,2,1)
xlabel('Pulse Number');ylabel('G [S]');
ylim([8e-10,1.2e-6]);
set(gca,'fontsize',15,'linewidth',1.5)
subplot(1,2,2)
xlabel('Pulse Number');ylabel('G [S]');
ylim([8e-10,1.2e-6]);
set(gca,'fontsize',15,'linewidth',1.5)
fig.Position=[260 300 1200 420];

filename='data_device2device_prog_erase.txt';
fid=fopen(filename);

t_prog=200e-6;
t_erase=100e-6;

Gtrace={};
lin=1;
device_n=1;
while ~feof(fid)
    tline = fgetl(fid);
    if mod(lin,2)==1
        tline_split=strsplit(tline,'Gprog, ');
        Gtrace(device_n).Gprog=str2num(tline_split{2});
    else
        tline_split=strsplit(tline,'Gerase, ');
        Gtrace(device_n).Gerase=str2num(tline_split{2});
        device_n=device_n+1;
    end
    lin=lin+1;
end
fclose(fid);

program_time=zeros(1,numel(Gtrace));
erase_time=zeros(1,numel(Gtrace));
for dd=1:numel(Gtrace)
    program_time(dd)=numel(Gtrace(dd).Gprog)*t_prog;
    erase_time(dd)=numel(Gtrace(dd).Gerase)*t_erase;
end

%cummulative density function of the program and erase time
fig=figure(2);
subplot(1,2,1)
[f,x]=ecdf(program_time*1e3);
y=norminv(f,0,1);
semilogx(x,y,'color','b','marker','s','linestyle','none','markersize',12,'linewidth',3,'markerfacecolor','w');
hold on
[f,x]=ecdf(program_time_sim*1e3);
y=norminv(f,0,1);
semilogx(x,y,'color','r','linestyle','-','linewidth',3,'markerfacecolor','w');

ylim(norminv([0.001 0.999]))
set(gca,'FontSize',22,'LineWidth',2);
xlabel('Full program time [ms]','Fontsize',22);ylabel('CDF','Fontsize',22);
tick=[0.001,0.01,0.05,0.1,0.25,0.5,0.75,0.9,0.95,0.99,0.999];
set(gca,'YTick',norminv(tick));
set(gca,'YTickLabel',num2cell(tick));
legend({'Data','Model'},'location','southeast')

subplot(1,2,2)
[f,x]=ecdf(erase_time*1e3);
y=norminv(f,0,1);
semilogx(x,y,'color','b','marker','s','linestyle','none','markersize',12,'linewidth',3,'markerfacecolor','w');
hold on
[f,x]=ecdf(erase_time_sim*1e3);
y=norminv(f,0,1);
semilogx(x,y,'color','r','linestyle','-','linewidth',3,'markerfacecolor','w');

ylim(norminv([0.001 0.999]))
set(gca,'FontSize',22,'LineWidth',2);
xlabel('Full erase time [ms]','Fontsize',22);ylabel('CDF','Fontsize',22);
tick=[0.001,0.01,0.05,0.1,0.25,0.5,0.75,0.9,0.95,0.99,0.999];
set(gca,'YTick',norminv(tick));
set(gca,'YTickLabel',num2cell(tick));
legend({'Data','Model'},'location','southeast')

fig.Position=[260 300 1200 420];
