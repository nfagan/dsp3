function [prefdat, preflabs] = get_pref(preflabs, spec, varargin)

if ( nargin < 2 )
  spec = { 'days', 'trialtypes', 'administration' };
end

prefdat = rowones( length(preflabs) );
opfunc = @(a, b) (a-b) ./ (a+b);
sfunc = @sum;

shared = { prefdat, preflabs, spec };

[sbdat, sblabs] = dsp3.sbop( shared{:}, 'both', 'self', opfunc, sfunc, varargin{:} );
[ondat, onlabs] = dsp3.sbop( shared{:}, 'other', 'none', opfunc, sfunc, varargin{:} );

setcat( sblabs, 'outcomes', 'selfMinusBoth' );
setcat( onlabs, 'outcomes', 'otherMinusNone' );

prefdat = [ sbdat; ondat ];
preflabs = append( sblabs', onlabs );

end