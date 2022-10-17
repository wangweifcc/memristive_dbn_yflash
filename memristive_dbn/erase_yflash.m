function [pa,Qfg,G]=erase_yflash(pa,Qfg,tp)
    [Qfg, ~, ~, ~] = yflash(pa,Qfg, 0, 'z', 8, tp);
    [~, i2v, ~, ~] = yflash(pa,Qfg, 2, 0, 0, 0);
    pa.pa_i.beta = pa.pa_i.beta+(pa.cyc.beta_max-pa.pa_i.beta)*(exp(tp/pa.cyc.tau_beta)-1);
    G=i2v/2;