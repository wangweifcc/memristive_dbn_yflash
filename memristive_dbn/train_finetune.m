function dbn=train_finetune...
    (dbn,batchdata,batchdata_lab,images_tr,labels_tr,images_ts,labels_ts)

para=dbn.para;

numCDiters=para.numCDiters;

[batchsize,~,numbatches]=size(batchdata);

dbn.rbm(1).hidvis=dbn.rbm(1).vishid;  % generative weight matrix
dbn.rbm(2).hidvis=dbn.rbm(2).vishid;  % generative weight matrix

CDsum_hidvis=zeros(size(dbn.rbm(1).hidvis.pos.G));
CDsum_penhid=zeros(size(dbn.rbm(2).hidvis.pos.G));
CDsum_rbm1_vis=zeros(size(dbn.rbm(1).visbiases.pos.G));
CDsum_rbm2_vis=zeros(size(dbn.rbm(2).visbiases.pos.G));

CDsum_rbmsm_labhid=zeros(size(dbn.rbmsm.labhid.pos.G)); 
CDsum_rbmsm_vishid=zeros(size(dbn.rbmsm.vishid.pos.G));
CDsum_rbmsm_lab=zeros(size(dbn.rbmsm.labbiases.pos.G));
CDsum_rbmsm_vis=zeros(size(dbn.rbmsm.visbiases.pos.G));
CDsum_rbmsm_hid=zeros(size(dbn.rbmsm.hidbiases.pos.G));

CDsum_vishid=zeros(size(dbn.rbm(2).vishid.pos.G));
CDsum_hidpen=zeros(size(dbn.rbm(1).vishid.pos.G));
CDsum_rbm2_hid=zeros(size(dbn.rbm(2).hidbiases.pos.G));
CDsum_rbm1_hid=zeros(size(dbn.rbm(1).hidbiases.pos.G));

errsum_epoch=zeros(para.maxepoch,1);
train_acc_bin_frz=zeros(para.maxepoch,1);
test_acc_bin_frz=zeros(para.maxepoch,1);
test_acc_bin_samp=zeros(para.maxepoch,1);

fprintf('       epoch,  batch,    Error:,   tranin acc.:,  test acc: \n');
fprintf('                                   (bin. frz.)    (bin. frz.) (bin. samp. #%d)\n',dbn.n_sampling);
for epoch = 1:para.maxepoch
    time=toc;
    fprintf(1,'\t%d, ',epoch); 
    nchar=0;
    for batch = 1:numbatches
        if batch==1 || batch==numbatches || toc-time > 1
            time = toc;
            fprintf(repmat('\b',[1,nchar]));
            nchar=fprintf('\t%d ...',batch); 
        end

        wakevisprobs = batchdata(:,:,batch);
        wakevisstates = wakevisprobs > 0.5;rand(size(wakevisprobs));
        data_lab = batchdata_lab(:,:,batch);
        %%%%%%%%% Perform a bottom-up pass to get WAKE/POSITIVE pahse %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Iout=read_matrix(wakevisstates,dbn.rbm(1).vishid,dbn.rbm(1).hidbiases,dbn.rbm(1).para.mem);
        wakehidprobs  = 1./(1+exp(- Iout/dbn.rbm(1).para.mem.I0));
        wakehidstates = wakehidprobs > rand(size(wakehidprobs));
        
        Iout=read_matrix(wakehidstates,dbn.rbm(2).vishid,dbn.rbm(2).hidbiases,dbn.rbm(2).para.mem);
        wakepenprobs  = 1./(1+exp(- Iout/dbn.rbm(2).para.mem.I0));
        wakepenstates = wakepenprobs  > rand(size(wakepenprobs));
        
        [~,Im1,Ib]=read_matrix(wakepenstates,dbn.rbmsm.vishid,dbn.rbmsm.hidbiases,dbn.rbmsm.para.mem);
        [~,Im2,~]=read_matrix(data_lab,dbn.rbmsm.labhid,dbn.rbmsm.hidbiases,dbn.rbmsm.para.mem);
        waketopprobs  = 1./(1+exp(- (Im1 + Im2 + Ib)/dbn.rbmsm.para.mem.I0));
        waketopstates = waketopprobs  > rand(size(waketopprobs));

        %%%%%%%%% Posive phase statistics for contrastive deviergence %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        poslabtopstatistics = data_lab' * waketopstates;
        pospentopstatistics = wakepenstates' * waketopstates;
        
        %%%%%% Perform numCDiters Gibbs sampling interations using the top
        %%%%%% level undirected associative memory %%%%%%%%
        negtopstates = waketopstates;
        for iter=1:numCDiters(epoch)
            Iout=read_matrix(negtopstates,dbn.rbmsm.vishid,dbn.rbmsm.visbiases,dbn.rbmsm.para.mem,'back');
            negpenprobs  = 1./(1 + exp(- Iout/dbn.rbmsm.para.mem.I0));
            negpenstates = negpenprobs > rand(size(negpenprobs));
            
            Iout=read_matrix(negtopstates,dbn.rbmsm.labhid,dbn.rbmsm.labbiases,dbn.rbmsm.para.mem,'back');
            neglabprobs  = softmax(Iout/dbn.rbmsm.para.mem.I0);
            neglabstates = neglabprobs > rand(size(neglabprobs));
            
            [~,Im1,Ib]=read_matrix(negpenstates,dbn.rbmsm.vishid,dbn.rbmsm.hidbiases,dbn.rbmsm.para.mem);
            [~,Im2,~]=read_matrix(neglabstates,dbn.rbmsm.labhid,dbn.rbmsm.hidbiases,dbn.rbmsm.para.mem);
            negtopprobs  = 1./(1+exp(- (Im1 + Im2 + Ib)/dbn.rbmsm.para.mem.I0));

            negtopstates = negtopprobs  > rand(size(negtopprobs));
        end
        
        %%%%%%%%% Posive phase statistics for contrastive deviergence %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        neglabtopstatistics = neglabstates' * negtopstates;
        negpentopstatistics = negpenstates' * negtopstates;
        
        %%%%%%%% Starting from the end of the Gibbs sampling run, 
        %%%%%%%% perform a top-down generative pass to get sleep/negative phase probs
        %%%%%%%% and states
        sleeppenstates = negpenstates;
        
        Iout=read_matrix(sleeppenstates,dbn.rbm(2).hidvis,dbn.rbm(2).visbiases,dbn.rbm(2).para.mem,'back');
        sleephidprobs  = 1./(1+exp(- Iout/dbn.rbm(2).para.mem.I0)); 
        sleephidstates = sleephidprobs > rand(size(sleephidprobs));
        
        Iout=read_matrix(sleephidstates,dbn.rbm(1).hidvis,dbn.rbm(1).visbiases,dbn.rbm(1).para.mem,'back');
        sleepvisprobs  = 1./(1+exp(- Iout/dbn.rbm(1).para.mem.I0)); 
        sleepvisstates = sleepvisprobs > rand(size(sleepvisprobs));
        
        %%% predictions
        Iout=read_matrix(sleephidstates,dbn.rbm(2).vishid,dbn.rbm(2).hidbiases,dbn.rbm(2).para.mem);
        psleeppenprobs = 1./(1+exp(- Iout/dbn.rbm(2).para.mem.I0));
        psleeppenstates = psleeppenprobs > rand(size(psleeppenprobs));
        
        Iout=read_matrix(sleepvisstates,dbn.rbm(1).vishid,dbn.rbm(1).hidbiases,dbn.rbm(1).para.mem);
        psleephidprobs = 1./(1+exp(-Iout/dbn.rbm(1).para.mem.I0));
        psleephidstates = psleephidprobs > rand(size(psleephidprobs));
        
        Iout=read_matrix(wakehidstates,dbn.rbm(1).hidvis,dbn.rbm(1).visbiases,dbn.rbm(1).para.mem,'back');
        pvisprobs = 1./(1+exp(-Iout/dbn.rbm(1).para.mem.I0));
        pvisstates = pvisprobs > rand(size(pvisprobs));
        
        Iout=read_matrix(wakepenstates,dbn.rbm(2).hidvis,dbn.rbm(2).visbiases,dbn.rbm(1).para.mem,'back');
        phidprobs = 1./(1+exp(-Iout/dbn.rbm(1).para.mem.I0));
        phidstates = phidprobs > rand(size(phidprobs));
        
        %%%%%%%%% UPDATE WEIGHTS AND BIASES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%         r=(para.epsilonw/batchsize); % batch normalization factor for learning rate
        %%% update generative parameters %%%
        CDsum_hidvis = CDsum_hidvis + (wakehidstates'*(wakevisstates-pvisstates))';
        CDsum_penhid = CDsum_penhid + (wakepenstates'*(wakehidstates-phidstates))';
        CDsum_rbm1_vis = CDsum_rbm1_vis + (sum(wakevisstates,1)-sum(pvisstates,1));
        CDsum_rbm2_vis = CDsum_rbm2_vis + (sum(wakehidstates,1)-sum(phidstates,1));
       
        [dbn.rbm(1).hidvis, CDsum_hidvis] = weight_update(dbn.rbm(1).hidvis,para,CDsum_hidvis);
        [dbn.rbm(2).hidvis, CDsum_penhid] = weight_update(dbn.rbm(2).hidvis,para,CDsum_penhid);
        
        [dbn.rbm(1).visbiases, CDsum_rbm1_vis] = weight_update(dbn.rbm(1).visbiases,para,CDsum_rbm1_vis);
        [dbn.rbm(2).visbiases, CDsum_rbm2_vis] = weight_update(dbn.rbm(2).visbiases,para,CDsum_rbm2_vis);
        
        %%% update top level associative memory paramters %%%
        CDsum_rbmsm_labhid = CDsum_rbmsm_labhid + (poslabtopstatistics-neglabtopstatistics);
        CDsum_rbmsm_vishid = CDsum_rbmsm_vishid + (pospentopstatistics-negpentopstatistics);
        CDsum_rbmsm_lab = CDsum_rbmsm_lab + (sum(data_lab,1)-sum(neglabstates,1));
        CDsum_rbmsm_vis = CDsum_rbmsm_vis + (sum(wakepenstates,1)-sum(negpenstates,1));
        CDsum_rbmsm_hid = CDsum_rbmsm_hid + (sum(waketopstates,1)-sum(negtopstates,1));
        
        [dbn.rbmsm.labhid, CDsum_rbmsm_labhid] = weight_update(dbn.rbmsm.labhid, para, CDsum_rbmsm_labhid);
        [dbn.rbmsm.vishid, CDsum_rbmsm_vishid] = weight_update(dbn.rbmsm.vishid, para, CDsum_rbmsm_vishid);
        [dbn.rbmsm.labbiases, CDsum_rbmsm_lab] = weight_update(dbn.rbmsm.labbiases, para, CDsum_rbmsm_lab);
        [dbn.rbmsm.visbiases, CDsum_rbmsm_vis] = weight_update(dbn.rbmsm.visbiases, para, CDsum_rbmsm_vis);
        [dbn.rbmsm.hidbiases, CDsum_rbmsm_hid] = weight_update(dbn.rbmsm.hidbiases, para, CDsum_rbmsm_hid);
        
        %%% update recognition parameters %%%
        CDsum_vishid = CDsum_vishid + sleephidstates'*(sleeppenstates-psleeppenstates);
        CDsum_hidpen = CDsum_hidpen + sleepvisstates'*(sleephidstates-psleephidstates);
        CDsum_rbm2_hid = CDsum_rbm2_hid + (sum(sleeppenstates,1)-sum(psleeppenstates,1));
        CDsum_rbm1_hid = CDsum_rbm1_hid + (sum(sleephidstates,1)-sum(psleephidstates,1));
        
        [dbn.rbm(2).vishid, CDsum_vishid] = weight_update(dbn.rbm(2).vishid, para, CDsum_vishid);
        [dbn.rbm(1).vishid, CDsum_hidpen] = weight_update(dbn.rbm(1).vishid, para, CDsum_hidpen);
        
        [dbn.rbm(2).hidbiases, CDsum_rbm2_hid] = weight_update(dbn.rbm(2).hidbiases, para, CDsum_rbm2_hid);
        [dbn.rbm(1).hidbiases, CDsum_rbm1_hid] = weight_update(dbn.rbm(1).hidbiases, para, CDsum_rbm1_hid);
        
        %%%%%%%%%%%%%%%% END OF UPDATES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    end

    
    % recognition accuracy on training and tesing sets
    train_acc_bin_frz(epoch)=test_networks(dbn,images_tr,labels_tr,'binary_frz');

    test_acc_bin_frz(epoch)=test_networks(dbn,images_ts,labels_ts,'binary_frz');
    test_acc_bin_samp(epoch)=test_networks(dbn,images_ts,labels_ts,'binary_samp');
    
    fprintf('  %f,  %.2f%%      %.2f%%      %.2f%%\n',...
        errsum_epoch(epoch),train_acc_bin_frz(epoch)*100,...
        test_acc_bin_frz(epoch)*100,test_acc_bin_samp(epoch)*100);    

end

dbn.accuracy(2).label='finetune';
dbn.accuracy(2).train=train_acc_bin_frz;
dbn.accuracy(2).test_bin_frz=test_acc_bin_frz;
dbn.accuracy(2).test_bin_samp=test_acc_bin_samp;

end



function y=softmax(x)
    y = exp(x)./repmat(sum(exp(x),2),[1,size(x,2)]);
end
