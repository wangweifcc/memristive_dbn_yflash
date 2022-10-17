function [Iout, Im, Ib]=read_matrix(input_states,weight,biases,mem,direction)

if ~exist('direction','var')
    direction = 'forward';
end
Vread=input_states*mem.Vread;

switch direction
    case 'forward'
        Ipos = Vread*weight.pos.G;
        Ineg = Vread*weight.neg.G;
        Ib_pos = mem.Vread*biases.pos.G;
        Ib_neg = mem.Vread*biases.neg.G;     
    case 'back'
        Ipos = Vread*weight.pos.G';
        Ineg = Vread*weight.neg.G';
        Ib_pos = mem.Vread*biases.pos.G;
        Ib_neg = mem.Vread*biases.neg.G;
end

Im=Ipos-Ineg;
Ib=Ib_pos-Ib_neg;
Iout=Im + repmat(Ib,size(Im,1),1);

