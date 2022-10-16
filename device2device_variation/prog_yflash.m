function [Qfg,G]=prog_yflash(pa,Qfg,tp)
    [Qfg, ~, ~, ~] = yflash(pa,Qfg, 5, 'z', 0, tp);
    [~, i2v, ~, ~] = yflash(pa,Qfg, 2, 0, 0, 0);
    G=i2v/2;