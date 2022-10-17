clc
clear
close all

Nprog=100;
Nerase=100;
Np=Nprog+Nerase;
qfg=0;

for n=1:5

Qfg=zeros(1,Nprog+Nerase);
G=zeros(1,Nprog+Nerase);

for i=1:Nprog+Nerase
   if i<=Nprog
       [qfg,g]=prog_yflash(qfg);
   else
       [qfg,g]=erase_yflash(qfg);
   end
    Qfg(i)=qfg;
    G(i)=g;
end

figure(1)
plot((n-1)*Np+(1:Np),Qfg,'s','linewidth',2,'markersize',8,'markerfacecolor','w');hold on;
xlabel('Pulse Number');
ylabel('Floating Gate Charge [C]');
set(gca,'linewidth',2,'fontsize',15)
figure(2)
semilogy((n-1)*Np+(1:Np),G,'s','linewidth',2,'markersize',8,'markerfacecolor','w');hold on;
xlabel('Pulse Number');
ylabel('Conductance [S]');
set(gca,'linewidth',2,'fontsize',15)

end