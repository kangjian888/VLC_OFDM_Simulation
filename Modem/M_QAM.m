function [Datamod] = M_QAM(BitOneOFDMSymbol, qamMapper, Effchannel, M_est_NonZero)
%This function is used to transfer bit stream in one OFDM symbol to qam symbol
Datamod = [];

for i = 1 : Effchannel
	BitsPerSymbol = log2(M_est_NonZero(i));
	qamMapper.ModulationOrder = M_est_NonZero(i);
	Datamod = [Datamod; step(qamMapper,BitOneOFDMSymbol(1:BitsPerSymbol))];
	BitOneOFDMSymbol = BitOneOFDMSymbol(BitsPerSymbol + 1 : end);
	release(qamMapper);
end