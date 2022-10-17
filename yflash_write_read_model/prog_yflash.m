function [Qfg,G]=prog_yflash(Qfg)
    [Qfg, ~, ~, ~] = yflash(Qfg, 5, 'z', 0, 200e-6);
    [~, i2v, ~, ~] = yflash(Qfg, 2, 0, 'z', 0);
    G=i2v/2;