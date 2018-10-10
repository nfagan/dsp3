function req_savefig(f, p, labs, cats, prefix, formats)

if ( nargin < 5 ), prefix = ''; end
if ( nargin < 6 ), formats = { 'epsc', 'png', 'fig' }; end

shared_utils.io.require_dir( p );
fname = dsp3.prefix( prefix, dsp3.fname(labs, cats) );

dsp3.savefig( f, fullfile(p, fname), formats );

end