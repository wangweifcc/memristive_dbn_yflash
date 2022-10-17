function [pa,Qfg,G]=prog_yflash(pa,Qfg,tp)
    [Qfg, ~, ~, ~] = yflash(pa,Qfg, 5, 'z', 0, tp);
    [~, i2v, ~, ~] = yflash(pa,Qfg, 2, 0, 0, 0);
    pa.pa_i.Va = pa.pa_i.Va+(pa.cyc.Va_max-pa.pa_i.Va)*(exp(tp/pa.cyc.tau_Va)-1);
    G=i2v/2;