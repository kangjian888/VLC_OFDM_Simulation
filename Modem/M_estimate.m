function [M_est_Final, H_th_OFDM , EsN]  = M_estimate(N_OFDM ,NumSubDataCarriers, SymRate,H, Pb_require)
% this function is used to determine the bit number of each subcarrier.
%%Parameter 
%N_OFDM: One side of subcarrier number if hermitian OFDM is used.
%NumSubDataCarriers: number of subcarriers which could laoding data.
%H: Input channel gain
%Pb_requirement: Bit error rate request of each subchannel
%EsN: The estimation SNR for each subcarrier
%H_th_OFDM: Channel gain 



%%The data we measured before
loss=xlsread('.\Channel\Bandwidth_white_Led.xlsx','G4:G63');
fre=xlsread('.\Channel\Bandwidth_white_Led.xlsx','A4:A63');
SNR = xlsread('.\Channel\Bandwidth_white_Led.xlsx','F4:F63');
loss=10.^(loss/20);%dB->linear value

deltaf = SymRate/N_OFDM;%frequency gap between two adjacent subcarrier
OFDMFre = deltaf'*(0:N_OFDM);%center frequency of each subcarrier
EsN = noisuy(fre,SNR,OFDMFre);%linear interpolation
H_th_OFDM = noisuy(fre,loss,OFDMFre);
H_th_OFDM = H*H_th_OFDM;%Channel gain of each subcarrier

%%Below is the bit number estimation of each subcarrier.
M = 2.^(1:16);
temp = EsN*(2*N_OFDM+N_OFDM/2)/(2*N_OFDM-20);%What does this mean?

[~,c] = size(OFDMFre);
M_est = zeros(size(EsN));
t = 1;
for j = 1 : c
	qfuncValue = sqrt(3.*temp(t,j)./(M-1));
	Pb = (4./log2(M)).*qfunc(qfuncValue);
	diff = Pb - Pb_require;
	for k = 1 : length(diff)
		if(diff(k) == max(diff(diff < 0)))
			M_est(t,j) = M(k);
		end
	end
end

M_est_Final = M_est(:,2:(NumSubDataCarriers+1));

end
