function [ParBitStream, OFDMSymbol,PaddingNum] = BitStreamGeneration(BitPerOFDMSymbol)
%% This function is used to transform a picture to bit stream
%BitPerOFDMSymbol: Total bit number in one OFDM symbol
%ParBitStream: Output bit matrix. Each row represents one OFDM symbol
%OFDMSymbol: Number of OFDMSymbol
%PaddingNum: Bit number needed to add to form complete OFDM symbol

%%Reading Image file
im = imread('JPG.jpg');
im_bin_1 = im(:);
im_bin_2 = dec2bin(im_bin_1,8)';
im_bin_3 = im_bin_2(:);%transfer matrix to bit sequence
%%Padding Source Signal
PaddingNum = mod(BitPerOFDMSymbol - mod(length(im_bin_3), BitPerOFDMSymbol), BitPerOFDMSymbol);
PaddingValue = repmat('0',PaddingNum,1);
im_bin_padded = [im_bin_3;PaddingValue];%Combining in row
im_bin_padded_bit = str2num(im_bin_padded);
OFDMSymbol = length(im_bin_padded_bit) / BitPerOFDMSymbol;
ParBitStream = reshape(im_bin_padded_bit,BitPerOFDMSymbol,OFDMSymbol);