function weight=initialize_weight(pa,qfg_ini, sz)
    weight.pos.Qfg=qfg_ini*(1+0.01*randn(sz));
    
    for i = 1:sz(1)
        for j=1:sz(2)
            pa.pa_i.Va=random('normal',23.4,0.8);
            pa.pa_i.beta=random('normal',9,0.8);
            weight.pa(i,j).Va=pa.pa_i.Va;
            weight.pa(i,j).beta=pa.pa_i.beta;
            [~, i2v, ~, ~] = yflash(pa,weight.pos.Qfg(i,j), 2, 0, 0, 0);
            weight.pos.G(i,j)=i2v/2;
        end
    end
    weight.pos.count=zeros(sz);
    
    Qfg=qfg_ini*(1+0.01*randn(sz));
    for i = 1:sz(1)
        for j=1:sz(2)
            pa.pa_i.Va=random('normal',23.4,0.8); 
            pa.pa_i.beta=random('normal',9,0.8);
            [~, i2v, ~, ~] = yflash(pa,Qfg(i,j), 2, 0, 0, 0);
            weight.neg.G(i,j)=i2v/2;
        end
    end