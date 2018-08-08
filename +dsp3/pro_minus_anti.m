function [dat, labs] = pro_minus_anti(data, labels, spec, mask)

if ( nargin < 4 ), mask = rowmask( labels ); end

a = 'pro';
b = 'anti';

opfunc = @minus;
sfunc = @(x) nanmean( x, 1 );
  
[dat, labs] = dsp3.summary_binary_op( data, labels', spec, a, b, opfunc, sfunc, mask );

setcat( labs, 'outcomes', 'proMinusAnti' );

end