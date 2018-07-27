function vecs = ncombvec(varargin)

%   NCOMBVEC -- Combination of N-length vectors 1:N.
%
%     vecs = ... ncombvec( 3, 3 ) is the same as combvec( 1:3, 1:3 )
%     vecs = ... ncombvec( a, b, c, ... ) is the same as 
%     combvec( 1:a, 1:b, 1:c, ... )
%
%     See also combvec
%
%     IN:
%       - `varargin` (double)
%     OUT:
%       - `vecs` (double)

cellfun( @(x) validateattributes(x, {'double', 'uint64'} ...
  , {'scalar', 'real', 'integer'}, 'ncomb'), varargin );

base_vecs = cellfun( @(x) 1:x, varargin, 'un', 0 );
vecs = combvec( base_vecs{:} );

end