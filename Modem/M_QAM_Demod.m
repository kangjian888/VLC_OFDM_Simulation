function [DataDemod] = M_QAM_Demod(SymbolReceive, qamDemod, EffChannel,M_est_NonZero)
%This function is used to do the domodulation of the received signal
%Parameter list:
%SymbolReceive: Received signal symbol
%EffChannel: the number of the effective channel
%M_est_NonZero: index of data carrier subchannel

DataDemod = [];

for  i = 1 : EffChannel
	qamDemod.ModulationOrder = M_est_NonZero(i);
	DataDemod = [DataDemod ;  step(qamDemod, SymbolReceive(i))];
	release(qamDemod);
end