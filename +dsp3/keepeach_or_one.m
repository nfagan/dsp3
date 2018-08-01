function [obj, I] = keepeach_or_one(obj, cats, varargin)

%   KEEPEACH_OR_ONE -- Keep-each subset or single subset for empty cell.
%
%     [obj, I] = keepeach_or_one( obj, cats ) where cats is a char or
%     non-empty cell array of strings is the same as keepeach( obj, cats );
%
%     ... = keepeach( obj, {} ) retains a single row of `obj`, and returns
%     a mask vector equivalent to 1:length(obj).
%
%     `obj` is modified unless explicitly copied.
%
%     IN:
%       - `obj` (fcat)
%       - `cats` (cell array of strings, char)
%       - `mask` (uint64, double) |OPTIONAL|
%     OUT:
%       - `obj` (fcat)
%       - `I` (cell array of uint64)

narginchk( 2, 3 );

if ( csisempty(cats) )
  %
  % {}, but not '', [], etc.
  %
  if ( nargin < 3 )
    I = { rowmask(obj) };
    obj = one( obj );
  else
    I = varargin(1);
    obj = one( obj(I{1}) );
  end
else
  [obj, I] = keepeach( obj, cats, varargin{:} );
end

end