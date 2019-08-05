function [prefdat, preflabs, I] = get_pref(preflabs, spec, varargin)

if ( nargin < 2 )
  spec = { 'days', 'trialtypes', 'administration' };
end

prefdat = rowones( length(preflabs) );
opfunc = @(a, b) (a-b) ./ (a+b);
sfunc = @sum;

shared = { prefdat, preflabs, spec };

[sbdat, sblabs, sb_I] = dsp3.sbop( shared{:}, 'both', 'self', opfunc, sfunc, varargin{:} );
[ondat, onlabs, on_I] = dsp3.sbop( shared{:}, 'other', 'none', opfunc, sfunc, varargin{:} );

setcat( sblabs, 'outcomes', 'selfMinusBoth' );
setcat( onlabs, 'outcomes', 'otherMinusNone' );

prefdat = [ sbdat; ondat ];
preflabs = append( sblabs', onlabs );

if ( nargout > 2 )
  I = [ sb_I; on_I ];
end

end