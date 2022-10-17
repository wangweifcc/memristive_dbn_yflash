function dbn=train_rbmSoftMax...
    (dbn,batchdata,batchdata_lab,images_tr,labels_tr,images_ts,labels_ts)

para=dbn.rbmsm.para;
rbmsm=dbn.rbmsm;
mem=rbmsm.para.mem;

numdims_lab=dbn.numlab;

[batchsize,~,numbatches]=size(batchdata);

CDsum_vishid = zeros(size(rbmsm.vishid));
CDsum_labhid  = zeros(size(rbmsm.labhid));
CDsum_vis = zeros(size(rbmsm.visbiases)); 
CDsum_hid = zeros(size(rbmsm.hidbiases));
CDsum_lab = zeros(size(rbmsm.labbiases));

errsum_epoch=zeros(para.maxepoch,1);
errsum_epoch_lab=zeros(para.maxepoch,1);
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

        %%%%%%%%% START POSITIVE PHASE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        posvisprobs = batchdata(:,:,batch);
        posvisstates = posvisprobs > 0.5;rand(size(posvisprobs ));
        for i=1:numel(dbn.rbm)
            Iout=read_matrix(posvisstates,dbn.rbm(i).vishid,dbn.rbm(i).hidbiases,mem);
            posvisprobs=1./(1+exp(- Iout/mem.I0));
            posvisstates = posvisprobs > 0.5;rand(size(posvisprobs ));
        end
        poslabstates = batchdata_lab(:,:,batch);
        [~,Im1,Ib]=read_matrix(posvisstates,rbmsm.vishid,rbmsm.hidbiases,mem);
        [~,Im2]=read_matrix(poslabstates,rbmsm.labhid,rbmsm.hidbiases,mem);
        poshidprobs = 1./(1 + exp(- (Im1+Im2+Ib)/mem.I0));    

        %%%%%%%%% END OF POSITIVE PHASE  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        poshidstates = poshidprobs > rand(size(poshidprobs));

        %%%%%%%%% START NEGATIVE PHASE  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Iout=read_matrix(poshidstates,rbmsm.vishid,rbmsm.visbiases,mem,'back');
        negvisprobs = 1./(1+exp(- Iout/mem.I0));
        negvisstates = negvisprobs > rand(size(negvisprobs));
        
        Iout=read_matrix(poshidstates,rbmsm.labhid,rbmsm.labbiases,mem,'back');
        negdata_lab_in=Iout/mem.I0;
        neglabprobs = exp(negdata_lab_in)...
            ./repmat(sum(exp(negdata_lab_in),2),[1,numdims_lab]);
        
        neglabstates = neglabprobs > rand(size(neglabprobs));
    
        [~,Im1,Ib]=read_matrix(negvisstates,rbmsm.vishid,rbmsm.hidbiases,mem);
        [~,Im2,~]=read_matrix(neglabstates,rbmsm.labhid,rbmsm.hidbiases,mem);
        neghidprobs = 1./(1 + exp(- (Im1+Im2+Ib)/mem.I0));  
        neghidstates = neghidprobs > rand(size(neghidprobs));
        %%%%%%%%% END OF NEGATIVE PHASE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        err= sum(sum( abs(posvisstates-negvisstates) ))/numel(posvisstates);
        errsum_epoch(epoch) = err + errsum_epoch(epoch);
        
        err_lab= sum(sum( abs(poslabstates-neglabstates) ))/numel(poslabstates);
        errsum_epoch_lab(epoch) = err_lab + errsum_epoch_lab(epoch);
        

        %%%%%%%%% UPDATE WEIGHTS AND BIASES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        posprods  = posvisstates' * poshidstates;
        posprods_lab  = poslabstates' * poshidstates;
        poshidact   = sum(poshidstates,1);
        posvisact = sum(posvisstates,1);
        poslabact = sum(poslabstates,1);
        
        negprods  = negvisstates'*neghidstates;
        negprods_lab  = neglabstates'*neghidstates;
        neghidact = sum(neghidstates,1);
        negvisact = sum(negvisstates,1); 
        neglabact = sum(neglabstates,1); 
        
        CDsum_vishid = CDsum_vishid + (posprods-negprods);
        CDsum_labhid = CDsum_labhid + (posprods_lab-negprods_lab);
        CDsum_vis = CDsum_vis + (posvisact-negvisact);
        CDsum_hid = CDsum_hid + (poshidact-neghidact);
        CDsum_lab = CDsum_lab + (poslabact-neglabact);

        [rbmsm.vishid, CDsum_vishid] = weight_update(rbmsm.vishid, para, CDsum_vishid);
        [rbmsm.labhid, CDsum_labhid] = weight_update(rbmsm.labhid, para, CDsum_labhid);
        [rbmsm.visbiases, CDsum_vis] = weight_update(rbmsm.visbiases, para, CDsum_vis);
        [rbmsm.hidbiases, CDsum_hid] = weight_update(rbmsm.hidbiases, para, CDsum_hid);
        [rbmsm.labbiases, CDsum_lab] = weight_update(rbmsm.labbiases, para, CDsum_lab);

        %%%%%%%%%%%%%%%% END OF UPDATES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    end
    errsum_epoch(epoch) = errsum_epoch(epoch)/numbatches;
    errsum_epoch_lab(epoch) = errsum_epoch_lab(epoch)/numbatches;
    
    
    % recognition accuracy on training and tesing sets
    dbn.rbmsm=rbmsm;
    
    train_acc_bin_frz(epoch)=test_networks(dbn,images_tr,labels_tr,'binary_frz');
    test_acc_bin_frz(epoch)=test_networks(dbn,images_ts,labels_ts,'binary_frz');
    test_acc_bin_samp(epoch)=test_networks(dbn,images_ts,labels_ts,'binary_samp');
    
%     fprintf('  %f,  %.2f%%     %.2f%%  %.2f%%      %.2f%%\n',...
%         errsum_epoch(epoch),train_acc(epoch)*100,test_acc(epoch)*100,...
%         test_acc_bin_frz(epoch)*100,test_acc_bin_samp(epoch)*100); 
    fprintf('  %f,  %.2f%%      %.2f%%      %.2f%%\n',...
        errsum_epoch(epoch),train_acc_bin_frz(epoch)*100,...
        test_acc_bin_frz(epoch)*100,test_acc_bin_samp(epoch)*100); 
    
end

dbn.rbmsm.recont_error = errsum_epoch;
dbn.rbmsm.recont_error_lab = errsum_epoch_lab;

dbn.accuracy(1).label='pretrain';
dbn.accuracy(1).train=train_acc_bin_frz;
dbn.accuracy(1).test_bin_frz=test_acc_bin_frz;
dbn.accuracy(1).test_bin_samp=test_acc_bin_samp;

end
