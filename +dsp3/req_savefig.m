function req_savefig(f, p, labs, cats, prefix)

if ( nargin < 5 ), prefix = ''; end

shared_utils.io.require_dir( p );

non_un = dsp3.except_uniform( labs, cats );
if ( isempty(non_un) ), non_un = cats; end
fname = dsp3.prefix( prefix, dsp3.fname(labs, non_un) );

dsp3.savefig( f, fullfile(p, fname) );

end