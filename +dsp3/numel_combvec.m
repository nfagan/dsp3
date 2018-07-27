function vecs = numel_combvec(varargin)

%   NUMEL_COMBVEC -- Combination of 1:numel(...) vectors.
%
%     vecs = ... numel_combvec( a, b ) is the same as 
%     combvec( 1:numel(a), 1:numel(b) )
%     vecs = ... numel_combvec( a, b, c, ... ) is the same as 
%     combvec( 1:numel(a), 1:numel(b), 1:numel(c), ... )
%
%     See also combvec, dsp3.ncombvec
%
%     IN:
%       - `varargin` (double)
%     OUT:
%       - `vecs` (double)

ns = cellfun( @numel, varargin, 'un', 0 );
vecs = dsp3.ncombvec( ns{:} );

end