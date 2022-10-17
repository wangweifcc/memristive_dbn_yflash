function [Qfg,G]=erase_yflash(Qfg)
    [Qfg, ~, ~, ~] = yflash(Qfg, 0, 'z', 8, 10e-6);
    [~, i2v, ~, ~] = yflash(Qfg, 2, 0, 'z', 0);
    G=i2v/2;