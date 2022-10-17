function [Qfg, Id, Isr, Isi] = yflash(pa, Qfg, Vd, Vsr, Vsi, dt)
    Cgd  = 1.5e-11;  % [F]
    Cgsr = 1e-12;   % [F]
    Cgsi = 1e-12;   % [F]

    pa_r=pa.pa_r;
    pa_i=pa.pa_i;
    % coupling between the terminals
    if Vd == 'z'
        Vd = 0;
    end
    if Vsr ~= 'z' && Vsi ~='z'
        Vfg = (Qfg+Cgsr*Vsr+Cgd*Vd+Cgsi*Vsi)/(Cgsr+Cgd+Cgsi);
    elseif Vsr ~='z' && Vsi == 'z'
        Vfg = (Qfg+Cgsr*Vsr+Cgd*Vd)/(Cgsr+Cgd);
    elseif Vsr == 'z' && Vsi ~='z'
        Vfg = (Qfg+Cgd*Vd+Cgsi*Vsi)/(Cgd+Cgsi);
    elseif Vsr == 'z' && Vsi =='z'
        Vfg = (Qfg+Cgd*Vd)/(Cgd);
    end
        
    [Isr,Igr] = mosfet(Vfg,Vd,Vsr,pa_r);
    [Isi,Igi] = mosfet(Vfg,Vd,Vsi,pa_i);
    Id = Isr+Isi;
    Ig = Igr + Igi;
    Qfg = Qfg + Ig*dt;
        
end

function [Is, Ig] = mosfet(Vfg, Vd, Vs, pa)
    kT=0.026;  % [eV]
    m=1;
    s=5; % parameter to soomth the current curve 
    if Vs=='z'
        Is = 0;
        Igl = 0;
        Igt = 0;
    else
        Vds = Vd-Vs;
        if Vd-Vs <= 0
            Is = 0;
        else
            is_sub=pa.Is0*exp((Vfg-pa.Vth)/(pa.n*kT))*(1-exp(-Vds/kT));
            is_ab=s*pa.Is0*(1-exp(-Vds/kT));
            if Vfg-pa.Vth>=0 && Vfg - pa.Vth < Vds
                is_ab = is_ab + pa.K/2*(Vfg-pa.Vth).^2;
            elseif Vfg-pa.Vth >= Vds
                is_ab = is_ab + pa.K*(Vfg-pa.Vth-Vds/2)*Vds;
            end
            Is=1./(1./(is_sub).^m+1./(is_ab).^m).^(1/m);
        end
        % lucky electron current
        if Vfg<0.1
            Igl=0;
        else
            Igl=-Is*pa.Prob0*exp(-pa.Va/Vfg); 
        end
        % tunneling current
        Vsg = Vs-Vfg;
        if Vsg<=pa.Vbi
            Igt=0;
        else
            Igt=pa.xi*(Vsg-pa.Vbi)^2*exp(-pa.beta/(Vsg-pa.Vbi));   
        end
    end
    Ig=Igl+Igt;
end