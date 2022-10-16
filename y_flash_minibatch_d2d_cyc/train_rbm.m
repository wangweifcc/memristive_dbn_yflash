function [dbn]=train_rbm(dbn,layer,batchdata)

para=dbn.rbm(layer).para;
rbm=dbn.rbm(layer);
mem=rbm.para.mem;

[batchsize,~,numbatches]=size(batchdata);

CDsum=zeros(size(rbm.vishid));
CDsum_vis = zeros(size(rbm.visbiases));
CDsum_hid = zeros(size(rbm.hidbiases));

errsum_epoch=zeros(para.maxepoch,1);

for epoch = 1:para.maxepoch
    time=toc;
    fprintf(1,'   epoch %d, ',epoch); 
    nchar=0;
    for batch = 1:numbatches
        if batch==1 || batch==numbatches || toc-time > 1
            time = toc;
            fprintf(repmat('\b',[1,nchar]));
            nchar=fprintf('batch %d ...',batch); 
        end

        %%%%%%%%% START POSITIVE PHASE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        posvisprobs = batchdata(:,:,batch);
        posvisstates = posvisprobs > 0.5;rand(size(posvisprobs));
        for i=1:layer-1
            Iout=read_matrix(posvisstates,dbn.rbm(i).vishid,dbn.rbm(i).hidbiases,mem);
            posvisprobs=1./(1+exp(- Iout/mem.I0));
            posvisstates = posvisprobs > 0.5;rand(size(posvisprobs));
        end
        Iout=read_matrix(posvisstates,rbm.vishid,rbm.hidbiases,mem);
        poshidprobs = 1./(1 + exp(- Iout/mem.I0 ));    
        
        %%%%%%%%% END OF POSITIVE PHASE  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        poshidstates = poshidprobs > rand(size(poshidprobs));

        %%%%%%%%% START NEGATIVE PHASE  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Iout=read_matrix(poshidstates,rbm.vishid,rbm.visbiases,mem,'back');
        negvisprobs = 1./(1 + exp(- Iout/mem.I0));
        negvisstates = negvisprobs > rand(size(negvisprobs));
        
        Iout=read_matrix(negvisstates,rbm.vishid,rbm.hidbiases,mem);
        neghidprobs = 1./(1 + exp(- Iout/mem.I0));     
        neghidstates = neghidprobs > rand(size(neghidprobs));
        
        %%%%%%%%% END OF NEGATIVE PHASE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        err= sum(sum( abs(posvisprobs-negvisprobs) ))/numel(posvisprobs);
        errsum_epoch(epoch) = err + errsum_epoch(epoch);


        %%%%%%%%% UPDATE WEIGHTS AND BIASES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        posprods    = posvisstates' * poshidstates;
        poshidact   = sum(poshidstates,1);
        posvisact = sum(posvisstates,1);
        
        negprods  = negvisstates'*neghidstates;
        neghidact = sum(neghidstates,1);
        negvisact = sum(negvisstates,1);
        
        CDsum = CDsum + (posprods-negprods);
        CDsum_vis = CDsum_vis + (posvisact-negvisact);
        CDsum_hid = CDsum_hid + (poshidact-neghidact);

        [rbm.vishid, CDsum] = weight_update(rbm.vishid,para,CDsum);
        
        
        [rbm.visbiases, CDsum_vis] = weight_update(rbm.visbiases,para,CDsum_vis);
        [rbm.hidbiases, CDsum_hid] = weight_update(rbm.hidbiases,para,CDsum_hid);

        %%%%%%%%%%%%%%%% END OF UPDATES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    end
    errsum_epoch(epoch) = errsum_epoch(epoch)/numbatches;
    fprintf(1, '    error: %f  \n', errsum_epoch(epoch)); 
end

rbm.recont_error=errsum_epoch;
dbn.rbm(layer)=rbm;
