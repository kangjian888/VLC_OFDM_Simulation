function [T_est_ZF, T_est_MMSE] = ZF_MMSE(H, Vin, Y, stdNoise)
%Parameter list
%H: Channel information
%Vin: Output voltage
%Y: Received Signal
%stdNoise: standard deviation of noise

varNosie = stdNoise^2;
H = Vin*H;

W_ZF = (eye(1)/(H'*H)) * H';

H = H + stdNoise*ones(1);
W_MMSE = (eye(1)/(H'*H))*H';

T_est_ZF = W_ZF * Y;
T_est_MMSE = W_MMSE * Y;