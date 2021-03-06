clc;
clear all;
%Add Path
addpath('.\Channel');
addpath('.\Equalizer');
addpath('.\OtherFunction');
addpath('.\Modem');
addpath('.\PreEmphasis');
addpath('.\Source');
addpath('.\Destination');

NoiseRMS = 2.5e-3; %what is the meaning of this parameter


%% Paramter in the spec:
 N=8192; %FFT size or total number of subcarriers (used + unused)
 Nsd = 8172; %Number of data subcarriers 
 Nlg = 10; % Number of left guard band sub-carriers.
 Nrg = 9; %Number of right guard band sub-carriers.
 Ndc = 1; %Number of DC Null sub-carriers.
 Ncp = N/4;  %Cyclic Prefix: how to make sure this parameter
 OFDMBandwidth = 21.3e06;% 2 side Bandwidth = 10.65 Mhz *2, measured value
 Pb_require = 1e-3;% error rate of each subchannel
%Check Parameter
if N ~= Nsd + Nlg + Nrg + Ndc
	disp('error: The channel allocation is not consistent with total subchannel number');
	exit;
end
%% Derived Parameters
NumSubDataCarriers = Nsd/2;
TotalSymRate = OFDMBandwidth/2;

Vin = 0.0966;

%% BER Block
BER = comm.ErrorRate;  
%% QAM and DeQAM Mapper
qamMapper = comm.RectangularQAMModulator(...
'BitInput', true, ...
'NormalizationMethod', 'Average power');%tao doi tuong

qamDemod = comm.RectangularQAMDemodulator(...
'BitOutput', true, ...
'NormalizationMethod', 'Average power');

%% Noise Generation
[Noise,~,rmsNoise,stdNoise] = NoiseTimeDomain(NoiseRMS,(N+Ncp));
%% Cnannel Attenuation
H = 1;
%% Estimate Channel Level Modulation
[M_est, H_th_Loss, EsN] = M_estimate(N/2, NumSubDataCarriers, TotalSymRate, H, Pb_require);%M-level for each channel
nonZeroLevelIndex = find(M_est ~= 0);
M_est_NonZero = M_est(nonZeroLevelIndex);

EffChannel = length(nonZeroLevelIndex);
if(EffChannel == 0)
	disp('Channel is too bad to transmit any information');
	exit;
end

%% Bits per OFDM symbol and bit total rate
BitPerOFDMSymbol = sum(log2(M_est_NonZero));
BitRateTotal = OFDMBandwidth / (N + Ncp) * BitPerOFDMSymbol;

[ParBitStream, OFDMSymbol, PaddingNum, SizePicture, im] = BitStreamGeneration(BitPerOFDMSymbol); %Bitstreaming generation

%% Buffer
ZFBuffer = zeros(BitPerOFDMSymbol, OFDMSymbol);
MMSEBuffer = zeros(BitPerOFDMSymbol,OFDMSymbol);
BERMMSESymbol = zeros(3,OFDMSymbol); %Store the bit error rate per symbol using mmse 
BERZFSymbol   = zeros(3,OFDMSymbol); %Store the bit error rate per symbol using zf

% Transmitting nSymbol'th symbol
for nSymbol = 1 : OFDMSymbol
	Temp = ParBitStream(:,nSymbol);
	% modulate data using M-QAM
	ParDataMode = M_QAM(Temp, qamMapper, EffChannel, M_est_NonZero);
	% Add unused channel for later calculating
	NormTotalStream = zeros(NumSubDataCarriers, 1);
	% Puting the data in the suitable place in the symbol
	NormTotalStream(nonZeroLevelIndex) = ParDataMode;
	% 20 remaining sub-carrier for zeropadding
	LeftGuardBand = zeros(Nlg,1);
	RightGuardBand = zeros(Nrg,1);
	DCNull = zeros(Ndc,1);
	%Total data
	TotalData = [LeftGuardBand; flipud(conj(NormTotalStream)); DCNull; NormTotalStream; RightGuardBand];
	H_th_Total = [fliplr(H_th_Loss(2:end)), H_th_Loss(1:end-1)];
	TotalData = TotalData' .* H_th_Total; %Add Channel Loss

	%IFFT
	TotalDataIFFT = (sqrt(Nsd/(N+Ncp)))*ifft(ifftshift(TotalData'));
	%Add CP
	DataCP1 = [TotalDataIFFT(N-Ncp+1:N);TotalDataIFFT];
	%Parallel to Serial Data
	SerDataIFFT = reshape(DataCP1,[1,numel(DataCP1)]);

	%Add DC bias
	DCOffset = (-min(SerDataIFFT));
	SerDataIFFTOffset = SerDataIFFT + DCOffset;
	%Normlized
	normvalue = abs(max(SerDataIFFTOffset));
	SerDataIFFTOffsetNorm = SerDataIFFTOffset/normvalue;

	%Transmit
	Trans = Vin * SerDataIFFTOffsetNorm;

	%Received signal
	Y_total = H*Trans + Noise;

	%Equalizer
	[T_ZF, T_MMSE] = ZF_MMSE(H, Vin, Y_total, stdNoise);
	TZF = T_ZF(1,:)'*normvalue;
	TMMSE = T_MMSE(1,:)'*normvalue;

	%Remove cyclic prefix
	TZF_NonCP = TZF(Ncp+1:end);
	TZMMSE_NonCP = TMMSE(Ncp+1:end);

	%Fast Fourier Transform
	ParDataFFT_ZF = (sqrt((N+Ncp)/Nsd))*ifftshift(fft(TZF_NonCP));
	ParDataFFT_MMSE = (sqrt((N+Ncp)/Nsd))*ifftshift(fft(TZMMSE_NonCP));

	%Channel Equalizing 
	ParDataFFT_ZF = ParDataFFT_ZF ./ H_th_Total';
	ParDataFFT_MMSE =ParDataFFT_MMSE ./ H_th_Total';

	%Remove Guardband
	ParReceiveZF = ParDataFFT_ZF     (end - Nrg - NumSubDataCarriers + 1 : end - Nrg , :);
	ParReceiveMMSE = ParDataFFT_MMSE (end - Nrg - NumSubDataCarriers + 1 : end - Nrg , :);

	%Remove Unused Channel
	ParDataReceiveZF   = ParReceiveZF(nonZeroLevelIndex,:);
	ParDataReceiveMMSE = ParReceiveMMSE(nonZeroLevelIndex,:);

	%M-QAM Demodulation
	BitsZF = M_QAM_Demod(ParDataReceiveZF, qamDemod, EffChannel, M_est_NonZero);
	BitsMMSE = M_QAM_Demod(ParDataReceiveMMSE, qamDemod, EffChannel, M_est_NonZero);

	%Buffer
	ZFBuffer(:, nSymbol) = BitsZF;
	MMSEBuffer(:, nSymbol) = BitsMMSE;

	%BER Calculation for each OFDM symbol
	BERMMSESymbol(:,nSymbol) = step(BER, Temp, BitsMMSE);
	release(BER);
	BERZFSymbol(:,nSymbol) = step(BER, Temp, BitsZF);
	release(BER);
end
	
	%Picture Recovery
	im_received_MMSE = im_recover(MMSEBuffer, PaddingNum, SizePicture);
	im_received_ZF   = im_recover(ZFBuffer, PaddingNum, SizePicture);
	%Picture showing
	figure(1)
	subplot(1,3,1);
	imshow(im);
	title('\bfTransmitted Picture');
	subplot(1,3,2);
	imshow(im_received_MMSE);
	title('\bfMMSE Received Picture');
	subplot(1,3,3);
	imshow(im_received_ZF);
	title('\bfZF Received Picture');	



	%BER Calcualtion
	berZF = step(BER, ParBitStream(:), ZFBuffer(:));
	release(BER);
	BER_ZF = berZF(1);

	berMMSE = step(BER, ParBitStream(:), MMSEBuffer(:));
	release(BER);

	BER_MMSE = berMMSE(1);
