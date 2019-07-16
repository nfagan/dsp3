function [data, all_zero] = remove_all_zero(data)

all_zero = all( data == 0, 2 );
data(all_zero, :) = [];

end