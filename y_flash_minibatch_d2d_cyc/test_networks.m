function accuracy=test_networks(dbn,images,labels,method)

% if ~exist('method','var')
%     method='analog';
% end

num_test=size(images,1); 
data = images;
    
switch method

    case 'analog'
        posvisprobs = data;
        posvisstates = posvisprobs;
        for i=1:numel(dbn.rbm)
            Iout=read_matrix(posvisstates,dbn.rbm(i).vishid,dbn.rbm(i).hidbiases,dbn.rbm(i).para.mem);
            posvisprobs=1./(1+exp(- Iout/dbn.rbm(i).para.mem.I0));
            posvisstates = posvisprobs;
        end
        Iout=read_matrix(posvisstates,dbn.rbmsm.vishid,dbn.rbmsm.hidbiases,dbn.rbmsm.para.mem);
        poshidprobs = 1./(1 + exp(- Iout/dbn.rbmsm.para.mem.I0));
        poshidstates = poshidprobs;
    
        Iout=read_matrix(poshidstates,dbn.rbmsm.labhid,dbn.rbmsm.labbiases,dbn.rbmsm.para.mem,'back');
        negdata_lab = Iout;
        
    case 'binary_frz'
        posvisprobs = data;
        posvisstates = posvisprobs > 0.5;
        for i=1:numel(dbn.rbm)
            Iout=read_matrix(posvisstates,dbn.rbm(i).vishid,dbn.rbm(i).hidbiases,dbn.rbm(i).para.mem);
            posvisprobs=1./(1+exp(- Iout/dbn.rbm(i).para.mem.I0));
            posvisstates = posvisprobs > 0.5;
        end
        Iout=read_matrix(posvisstates,dbn.rbmsm.vishid,dbn.rbmsm.hidbiases,dbn.rbmsm.para.mem);
        poshidprobs = 1./(1 + exp(- Iout/dbn.rbmsm.para.mem.I0));
        poshidstates = poshidprobs>0.5;
    
        Iout=read_matrix(poshidstates,dbn.rbmsm.labhid,dbn.rbmsm.labbiases,dbn.rbmsm.para.mem,'back');
        negdata_lab = Iout;
    case 'binary_samp'
        negdata_lab=zeros(size(data,1),dbn.numlab);
        for test=1:dbn.n_sampling
            posvisprobs = data;
            posvisstates = posvisprobs > rand(size(posvisprobs));
            for i=1:numel(dbn.rbm)
                Iout=read_matrix(posvisstates,dbn.rbm(i).vishid,dbn.rbm(i).hidbiases,dbn.rbm(i).para.mem);
                posvisprobs=1./(1+exp(-Iout/dbn.rbm(i).para.mem.I0));
                posvisstates = posvisprobs > rand(size(posvisprobs));
            end
            Iout=read_matrix(posvisstates,dbn.rbmsm.vishid,dbn.rbmsm.hidbiases,dbn.rbmsm.para.mem);
            poshidprobs = 1./(1 + exp(-Iout/dbn.rbmsm.para.mem.I0));
            poshidstates = poshidprobs > rand(size(poshidprobs));
            
            Iout=read_matrix(poshidstates,dbn.rbmsm.labhid,dbn.rbmsm.labbiases,dbn.rbmsm.para.mem,'back');
            negdata_lab = negdata_lab + Iout/dbn.rbmsm.para.mem.I0;
        end
    otherwise
        error("Testing method not defined");
end

[~,class] = max(negdata_lab,[],2);
[~,target]= max(labels,[],2);

accuracy=sum(class==target)/num_test;
    
end


function y=softmax(x)
    y = exp(x)./repmat(sum(exp(x),2),[1,size(x,2)]);
end