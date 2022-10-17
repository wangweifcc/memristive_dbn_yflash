function [Qfg,G]=erase_yflash(pa,Qfg,tp)
    [Qfg, ~, ~, ~] = yflash(pa,Qfg, 0, 'z', 8, tp);
    [~, i2v, ~, ~] = yflash(pa,Qfg, 2, 0, 0, 0);
    G=i2v/2;