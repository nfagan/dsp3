function [prefdat, preflabs] = get_pref(preflabs)

prefdat = rowones( length(preflabs) );
spec = { 'days', 'trialtypes', 'administration' };
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