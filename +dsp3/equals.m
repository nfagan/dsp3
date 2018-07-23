function tf = equals(a, b)

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
  
elseif ( fcat.is(a) )
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

for i = 1:numel(a)
  va = a{i};
  vb = b{i};
  
  tf = dsp3.equals( va, vb );
  
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

for i = 1:numel(fs1)
  va = a.(fs1{i});
  vb = b.(fs1{i});
  
  tf = dsp3.equals( va, vb );
  
  if ( ~tf )
    return
  end
end

end