function [im_received] = im_recover(BitReceived, PaddingNum, SizePicture)
%BitReceived: Receoved matrix of the picture
%PaddingNum: The number of added to the matrix to form complete OFDM symbol
%SizePicture: The size of the picture used to recover the original picture
%im_received: The recovery picture matrix 
im_bit = BitReceived(:); %transform matrix to vector
im_bin_1 = num2str(im_bit);%transform bit to char
im_bin_remove_padding_num = im_bin_1(1:end - PaddingNum);

im_bin_2 = reshape(im_bin_remove_padding_num, 8, length(im_bin_remove_padding_num)/8);
im_bin_3 = uint8(bin2dec(im_bin_2'));
im_received = reshape(im_bin_3,SizePicture);