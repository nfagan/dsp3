function req_savefig(f, p, labs, cats, prefix)

if ( nargin < 5 ), prefix = ''; end

shared_utils.io.require_dir( p );
fname = dsp3.prefix( prefix, dsp3.fname(labs, cats) );

dsp3.savefig( f, fullfile(p, fname) );

end