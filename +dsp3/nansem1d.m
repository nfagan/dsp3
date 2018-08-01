function y = nansem1d(x)

%   NANSEM -- Std error across the first dimension, excluding NaN.

nans = isnan( x );
ns = size( x, 1 ) - sum( nans, 1 );
y = nanstd( x, [], 1 ) ./ sqrt( ns );
y(:, ns == 0) = NaN;

end