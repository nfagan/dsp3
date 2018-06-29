function writetable(T, fname, ext)

if ( nargin < 3 ), ext = '.csv'; end
fname = shared_utils.char.require_end( fname, ext );
writetable( T, fname, 'WriteRowNames', true, 'WriteVariableNames', true );
end