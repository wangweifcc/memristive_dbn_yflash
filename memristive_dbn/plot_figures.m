clc
clear
close all

load('dataset/MNIST.mat') 

% You need to first run the "mnistdeepbn.m" to genearte the "*.mat" file
load trained_dbn_784_ep_30_bs_100_CDaccprogram_erase.mat

figure(1)
ax1=axes('Position',[0.1300 0.15 0.7750 0.2]); 
recon_err=dbn.rbm(1).recont_error;
plot(1:numel(recon_err),recon_err,'rs-','linewidth',2,'markersize',10,'markerfacecolor','w'); 
xlabel('Epoch');
ylim([0.025,0.075])
set(gca,'fontsize',15,'linewidth',1.5);
legend('<v_1-v_1^''>','box','off')

ax2=axes('Position',[0.1300 0.35 0.7750 0.2]);
recon_err=dbn.rbm(2).recont_error;
plot(1:numel(recon_err),recon_err,'bs-','linewidth',2,'markersize',10,'markerfacecolor','w');
xlabel('');xticklabels([]);
ylim([0.055,0.155])
set(gca,'fontsize',15,'linewidth',1.5);
legend('<v_2-v_2^''>','box','off')

ax3=axes('Position',[0.1300 0.55 0.7750 0.2]);
recon_err=dbn.rbmsm.recont_error;
plot(1:numel(recon_err),recon_err,'gs-','linewidth',2,'markersize',10,'markerfacecolor','w');
xlabel('');xticklabels([]);
ylim([0.03,0.105])
ylabel("Reconstruction Error");
set(gca,'fontsize',15,'linewidth',1.5);
legend('<v_3-v_3^''>','box','off')

ax4=axes('Position',[0.1300 0.75 0.7750 0.2]);
recon_err=dbn.rbmsm.recont_error_lab;
plot(1:numel(recon_err),recon_err,'cs-','linewidth',2,'markersize',10,'markerfacecolor','w');
xlabel('');xticklabels([]);
ylim([0.005,0.05])
set(gca,'fontsize',15,'linewidth',1.5);
legend('<l-l^''>','box','off')

gf=gcf;
gf.Position=[488 342 840 420];
drawnow


figure(100)
train_acc=[dbn.accuracy(1).train;dbn.accuracy(2).train];
test_acc_bin_frz =[dbn.accuracy(1).test_bin_frz;dbn.accuracy(2).test_bin_frz];
test_acc_bin_samp=[dbn.accuracy(1).test_bin_samp;dbn.accuracy(2).test_bin_samp];
plot(1:numel(test_acc_bin_frz),test_acc_bin_frz*100,'s-','linewidth',2,'markersize',12,'markerfacecolor','w'); hold on;
plot(1:numel(test_acc_bin_samp),test_acc_bin_samp*100,'o-','linewidth',2,'markersize',12,'markerfacecolor','w'); hold off;
xticks([0:10:60]);
xlabel('Epoch');ylabel("Accuracy [%]");
set(gca,'fontsize',18,'linewidth',2);
legend({'Deterministic',['Sampling #',num2str(dbn.n_sampling)]},'location','southeast')
drawnow


acc_soft=0.983;
tic
acc_bin1=test_acc_bin_frz(end);
fprintf('\nTest accuracy of binarized activation (freezing): %.2f%%\n',acc_bin1*100);
toc

N_test=[1,10,50,100];
acc_bin2=zeros(1,numel(N_test));
for i=1:numel(N_test)
    n_test=N_test(i);
    tic
    dbn.n_sampling=n_test;
    acc_bin2(i)=test_networks(dbn,images_ts,labels_ts,'binary_samp');
    fprintf('\nTest accuracy of binarized activation (sampling %d): %.2f%%\n',n_test,acc_bin2(i)*100);
    toc
end
% acc_analog=test_networks(dbn,images_ts,labels_ts,'analog');
%%
acc_dnn_PCM=0.9795;
acc_DCNN_RRAM=0.9583;
acc_dnn_PCM_2=0.9747;
% acc_all=[acc_soft,acc_bin1,acc_bin2,acc_analog,acc_dnn_PCM,acc_DCNN_RRAM, acc_dnn_PCM_2]*100;
acc_all=[acc_soft,acc_bin1,acc_bin2,acc_dnn_PCM,acc_DCNN_RRAM, acc_dnn_PCM_2]*100;
figure;
b=bar(acc_all,'linewidth',2);
b.FaceColor = 'flat';
ylim([80,100]);
% xticklabels({'Software DBN','Deter.','Samp. #1','Samp. #10','Samp. #50','Samp. #100', 'Analog Neuron', 'DNN, PCM','DCNN, RRAM','DNN, PCM(2)'})
xticklabels({'Software DBN','Deter.','Samp. #1','Samp. #10','Samp. #50','Samp. #100', 'DNN, PCM','DCNN, RRAM','DNN, PCM(2)'})
set(gca,'linewidth',2,'fontsize',18)
ylabel('Accuracy [%]');
ax=gca;
ax.XTickLabelRotation=30;

cmap=colormap(parula(numel(acc_all)));
for i=1:numel(acc_all)
    b.CData(i,:) = cmap(i,:);
end
grid on

set(gca,'color','none')