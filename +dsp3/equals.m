function tf = equals(varargin)

%   EQUALS -- True if inputs have equivalent contents.
%
%     tf = ... equals( a, b ) returns true if `a` and `b` are of the same
%     class and have equivalent contents. For struct inputs, the order of
%     fields does not matter. For numeric inputs, NaN values are compared
%     as equal. For fcat and Container objects, the `==` operator, rather
%     than the function `isequaln`, is called. Struct fields and cell
%     elements are recursively checked for equivalence.
%
%     tf = ... equals( a, b, c, ... ) returns true if all of `a`, `b`, `c`
%     ... are equal.
%
%     See also isequaln, fcat, Container
%
%     IN:
%       - `varargin` (/any/)
%     OUT:
%       - `tf` (logical)

narginchk( 2, Inf );

for i = 1:numel(varargin)-1
  a = varargin{i};
  b = varargin{i+1};
  
  tf = eq_ab( a, b );
  
  if ( ~tf )
    return
  end
end

end

function tf = eq_ab(a, b)

if ( ~isequaln(class(a), class(b)) )
  tf = false;
  return
end

if ( isstruct(a) )
  tf = test_struct( a, b );
  
elseif ( iscell(a) )
  if ( iscellstr(a) )
    tf = isequaln( a, b );
  else
    tf = test_cell( a, b );
  end
  
elseif ( fcat.is(a) || isa(a, 'Container') )
  tf = a == b;
  
else
  tf = isequaln( a, b );
end

end

function tf = test_cell(a, b)

tf = false;

if ( ~isequaln(size(a), size(b)) )
  return
end

tf = true;

for i = 1:numel(a)
  va = a{i};
  vb = b{i};
  
  tf = eq_ab( va, vb );
  
  if ( ~tf )
    return
  end
end

end

function tf = test_struct(a, b)

tf = false;

fs1 = sort( fieldnames(a) );
fs2 = sort( fieldnames(b) );

if ( ~isequaln(fs1, fs2) )
  return
end

tf = true;

for i = 1:numel(fs1)
  va = a.(fs1{i});
  vb = b.(fs1{i});
  
  tf = eq_ab( va, vb );
  
  if ( ~tf )
    return
  end
end

end