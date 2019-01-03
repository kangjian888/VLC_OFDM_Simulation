function [Noise, Mean, RMS, STD] = NoiseTimeDomain(Noise_RMS, Length)

%%Generate 
Noise = rand(1,Length);
Noise = Noise(1,:)-mean(Noise(1,:));
Noise = Noise_RMS * Noise / rms(Noise);

%Parameter Calculation 
Mean = mean(Noise);
RMS = rms(Noise);
STD = std(Noise);