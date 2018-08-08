function [dat, labs] = pro_v_anti(data, labels, spec, mask)

if ( nargin < 4 ), mask = rowmask( labels ); end

pairs = { {'self', 'both'}, {'other', 'none'} };
label_as = { 'anti', 'pro' };

assert( numel(pairs) == numel(label_as) );

dat = [];
labs = fcat();

opfunc = @minus;
sfunc = @(x) nanmean( x, 1 );

for i = 1:numel(pairs)
  
  a = pairs{i}{1};
  b = pairs{i}{2};
  
  [d, l] = dsp3.summary_binary_op( data, labels', spec, a, b, opfunc, sfunc, mask );
  
  setcat( l, 'outcomes', label_as{i} );
  
  dat = [ dat; d ];
  append( labs, l );
end

end