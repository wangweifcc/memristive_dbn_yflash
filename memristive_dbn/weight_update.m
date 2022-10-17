function [w,CDsum]= weight_update(w0,para,CDsum)

wup=para.wup;
mem=para.mem;
pa=mem.pa;

wup_type = wup.type;

switch wup_type
    case 'CDacc'
        CDstep = wup.CDmin;
        CDsteps=fix(CDsum/CDstep);
        CDsum=CDsum-CDsteps*CDstep;
        
        w=w0;
        switch mem.uptype
            case 'program_erase'
                for i=1:size(CDsteps,1)
                    for j=1:size(CDsteps,2)
                        if CDsteps(i,j)<0
                            pa.pa_i.Va=w.pa(i,j).Va;
                            pa.pa_i.beta=w.pa(i,j).beta;
                            [pa, w.pos.Qfg(i,j),w.pos.G(i,j)]=prog_yflash(pa, w.pos.Qfg(i,j),mem.tp_prog);
                            w.pa(i,j).Va=pa.pa_i.Va;
                            w.pa(i,j).beta=pa.pa_i.beta;
                            w.pos.count(i,j)=w.pos.count(i,j)+1;
                        elseif CDsteps(i,j)>0
                            pa.pa_i.Va=w.pa(i,j).Va;
                            pa.pa_i.beta=w.pa(i,j).beta;
                            [pa, w.pos.Qfg(i,j),w.pos.G(i,j)]=erase_yflash(pa, w.pos.Qfg(i,j),mem.tp_erase);
                            w.pa(i,j).Va=pa.pa_i.Va;
                            w.pa(i,j).beta=pa.pa_i.beta;
                            w.pos.count(i,j)=w.pos.count(i,j)+1;
                        end
                    end
                end
        end
end