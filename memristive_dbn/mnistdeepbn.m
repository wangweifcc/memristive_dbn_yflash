clc
clear
close all

tic
file_save_folder='';

fprintf('Loading MNIST dataset...\n')
load('dataset/MNIST.mat'); 
fn_save_str1=sprintf([file_save_folder,'trained_dbn_784']);

whos

fprintf('MNIST dataset loaded.\n\n')

fprintf('Making batches ... \n');
totnum = size(images_tr,1);
numdims= size(images_tr,2);
numdims_lab= size(labels_tr,2);
batchsize = 100;
numbatches=floor(totnum/batchsize);

batchdata=zeros(batchsize,numdims,numbatches);
batchdata_lab=zeros(batchsize,numdims_lab,numbatches);
for batch=1:numbatches
  batchdata(:,:,batch) = images_tr((batch-1)*batchsize+1:batch*batchsize, :);
  batchdata_lab(:,:,batch) = labels_tr((batch-1)*batchsize+1:batch*batchsize, :);
end
fprintf('Training set was partitioned to %d batches with %d cases each.\n\n', numbatches, batchsize);


fprintf('  Initialize the Deep belief nets... \n');

dbn.numdims=numdims;
dbn.numlab=numdims_lab;
dbn.n_sampling=50;

dbn.numhid=500;
dbn.numpen=500;
dbn.numtop=2000;
dbn.para.maxepoch = 30;
dbn.para.numCDiters=zeros(dbn.para.maxepoch,1);
dbn.para.numCDiters(:)=20;


% define how weight and biases updates
wup.type = 'CDacc';
wup.CDmin = batchsize;
dbn.para.wup=wup;

% define parameters for memristor devices
mem.uptype='program_erase';
mem.Wmax=1.5;
mem.Wmin=-1.5;
mem.Imax=3e-6;
mem.Vread = 2; 
mem.Qfg_ini= -1e-11;
mem.tp_prog=200e-6;
mem.tp_erase=100e-6;
mem.I0=(mem.Imax)/(mem.Wmax-mem.Wmin);
% parameter for read out transistor
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
mem.pa=pa;
dbn.para.mem = mem;

% 1st RBM layer from input to first hidden layer
dbn.rbm(1).type='RBM';dbn.rbm(1).label='vis-hid';
dbn.rbm(1).size=[dbn.numdims,dbn.numhid];
% 2nd RBM layer from hidden to pen layer
dbn.rbm(2).type='RBM';dbn.rbm(2).label='hid-pen';
dbn.rbm(2).size=[dbn.numhid,dbn.numpen];
% 3rd RBM layer with softmax labels from pen&lab to top layer
dbn.rbmsm.type='RBM-Softmax';dbn.rbmsm.label='(pen+lab)-top';
dbn.rbmsm.size=[dbn.numpen,dbn.numtop,dbn.numlab];

rng('default');
for layer=1:numel(dbn.rbm)
    dbn.rbm(layer).para=dbn.para;
    dbn.rbm(layer).vishid     = initialize_weight(mem.pa,mem.Qfg_ini,[dbn.rbm(layer).size(1), dbn.rbm(layer).size(2)]); % weights from visible to hidden units
    dbn.rbm(layer).visbiases  = initialize_weight(mem.pa,mem.Qfg_ini,[1,dbn.rbm(layer).size(1)]);            % biases for visible units
    dbn.rbm(layer).hidbiases  = initialize_weight(mem.pa,mem.Qfg_ini,[1,dbn.rbm(layer).size(2)]);            % biases for hidden units
    dbn.rbm(layer).recont_error = zeros(dbn.rbm(layer).para.maxepoch,1);
end

dbn.rbmsm.para=dbn.para;
dbn.rbmsm.vishid = initialize_weight(mem.pa,mem.Qfg_ini,[dbn.rbmsm.size(1), dbn.rbmsm.size(2)]); % weights from visible (pen) to hidden (top) units
dbn.rbmsm.labhid = initialize_weight(mem.pa,mem.Qfg_ini,[dbn.rbmsm.size(3), dbn.rbmsm.size(2)]); % weights from label to hidden (top) units
dbn.rbmsm.visbiases = initialize_weight(mem.pa,mem.Qfg_ini,[1,dbn.rbmsm.size(1)]);            % biases for visible (pen) units
dbn.rbmsm.hidbiases = initialize_weight(mem.pa,mem.Qfg_ini,[1,dbn.rbmsm.size(2)]);                 % biases for hidden (top) units
dbn.rbmsm.labbiases = initialize_weight(mem.pa,mem.Qfg_ini,[1,dbn.rbmsm.size(3)]);                 % biases for hidden (top) units
dbn.rbmsm.recont_error = zeros(dbn.rbmsm.para.maxepoch,1);
dbn.rbmsm.recont_error_lab = zeros(dbn.rbmsm.para.maxepoch,1);

fn_str2 = sprintf(['_ep_%02d_bs_%03d_',dbn.para.wup.type,mem.uptype],dbn.para.maxepoch,batchsize);

fprintf('  Layers: %d-%d-(%d+%d)-%d\n',dbn.numdims,dbn.numhid,dbn.numpen,dbn.numlab,dbn.numtop);
fprintf('  Deep belief nets inistilzed. \n\n');

fprintf('  Pretraining with RBM layers ...\n');
for layer=1:numel(dbn.rbm)
    fprintf('    Pretraining RBM Layer ''%s'': %d-%d \n',dbn.rbm(layer).label,dbn.rbm(layer).size);
    dbn=train_rbm(dbn,layer,batchdata);
end
fprintf('  Pretraining rbm-Softmax Layer ''%s'': (%d+%d)-%d \n',dbn.rbmsm.label,dbn.numpen,dbn.numtop,dbn.numlab);
dbn=train_rbmSoftMax(dbn,batchdata,batchdata_lab,images_tr,labels_tr,images_ts,labels_ts);
fprintf('Pretrain finished ...\n\n');

fprintf('Fine-tuning the deep belief net with wake-sleep algorithm. \n');
dbn=train_finetune(dbn,batchdata,batchdata_lab,images_tr,labels_tr,images_ts,labels_ts);
fprintf('  Fine-tune finished ...\n\n');

figure(100)
train_acc=[dbn.accuracy(1).train;dbn.accuracy(2).train];
test_acc_bin_frz =[dbn.accuracy(1).test_bin_frz;dbn.accuracy(2).test_bin_frz];
test_acc_bin_samp=[dbn.accuracy(1).test_bin_samp;dbn.accuracy(2).test_bin_samp];
plot(1:numel(test_acc_bin_frz),test_acc_bin_frz*100,'o-','linewidth',2,'markersize',12,'markerfacecolor','w'); hold on;
plot(1:numel(test_acc_bin_samp),test_acc_bin_samp*100,'o-','linewidth',2,'markersize',12,'markerfacecolor','w'); 
xlabel('Epoch');ylabel("Recognition accuracy");
set(gca,'fontsize',15,'linewidth',1.5);
legend({'Test accuracy (freeze)',['Test accuracy (sampling #',num2str(dbn.n_sampling),')']},'location','southeast')
drawnow

filename=[fn_save_str1,fn_str2];
save([filename,'.mat'],'dbn')

toc



