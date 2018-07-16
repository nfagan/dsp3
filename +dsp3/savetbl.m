function savetbl(T, p, labs, fnames_are, prefix)

if ( nargin < 5 )
  prefix = '';
end

if ( isempty(T) ), return; end

shared_utils.io.require_dir( p );
fname = dsp3.prefix( prefix, dsp3.fname(labs, fnames_are) );
dsp3.writetable( T, fullfile(p, fname) ); 

end