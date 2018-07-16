function varargout = multcompare(stats, varargin)

[c, m, h, nms] = multcompare( stats, 'display', 'off', varargin{:} );

cg = arrayfun( @(x) nms(x), c(:, 1:2) );
cc = [ cg, arrayfun(@(x) x, c(:, 3:end), 'un', 0) ];

varargout{1} = cc;

if ( nargout > 1 ), varargout{2} = c; end
if ( nargout > 2 ), varargout{3} = m; end
if ( nargout > 3 ), varargout{4} = h; end
if ( nargout > 4 ), varargout{5} = nms; end

end