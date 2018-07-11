function [prefdat, preflabs] = get_pref(preflabs, spec)

if ( nargin < 2 )
  spec = { 'days', 'trialtypes', 'administration' };
end

prefdat = rowones( length(preflabs) );
opfunc = @(a, b) (a-b) ./ (a+b);
sfunc = @sum;

shared = { prefdat, preflabs, spec };

[sbdat, sblabs] = dsp3.summary_binary_op( shared{:}, 'both', 'self', opfunc, sfunc );
[ondat, onlabs] = dsp3.summary_binary_op( shared{:}, 'other', 'none', opfunc, sfunc );

setcat( sblabs, 'outcomes', 'selfMinusBoth' );
setcat( onlabs, 'outcomes', 'otherMinusNone' );

prefdat = [ sbdat; ondat ];
preflabs = append( sblabs', onlabs );

end