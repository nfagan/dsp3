function y = sem1d(x)
      
  %   SEM1D -- Standard error across the first dimension.
  %
  %     IN:
  %       - `x` (double) -- Data.
  %     OUT:
  %       - `y` (double) -- Vector of the same size as `x`.

N = size( x, 1 );
y = std( x, [], 1 ) / sqrt( N );

end