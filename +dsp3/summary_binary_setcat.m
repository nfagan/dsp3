function labs = summary_binary_setcat(labs, a, b, joinchar)

a = cellstr( a );
b = cellstr( b );

a( ~haslab(labs, a) ) = [];
b( ~haslab(labs, b) ) = [];

cats_a = whichcat( labs, a );
cats_b = whichcat( labs, b );

if ( ~isequal(cats_a, cats_b) )
  error( 'Categories of A and B must match.' );
end

for i = 1:numel(cats_a)
  setcat( labs, cats_a{i}, sprintf('%s%s%s', a{i}, joinchar, b{i}) );
end

end