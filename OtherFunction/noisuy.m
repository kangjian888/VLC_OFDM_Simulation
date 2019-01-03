function [Interpolated_data] = noisuy(index_Uninterpolated,value_Uninterpolated,index_Interpolated)
%this function is linear interpolation
%Parameter list:
[~,c] = size(index_Interpolated);
%Initialize output
Interpolated_data = zeros(1,c);
for j = 1:c
	fre_temp = index_Interpolated(1,j);
	index_Uninterpolated_temp = index_Uninterpolated - fre_temp;
	for k = 1: length(index_Uninterpolated_temp) -1
		test_result = index_Uninterpolated_temp(k) * index_Uninterpolated_temp(k+1);
		if test_result <= 0
			slope_bet_ori_point = ...
			(value_Uninterpolated(k+1)-value_Uninterpolated(k))....
			/(index_Uninterpolated(k+1)-index_Uninterpolated(k));
			Interpolated_data(1,j) = slope_bet_ori_point* ...
			(index_Interpolated(1,j)-index_Uninterpolated(k)) + value_Uninterpolated(k);
        end
	end
end

end


