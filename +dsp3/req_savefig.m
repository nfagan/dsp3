function fname = req_savefig(f, p, labs, cats, prefix, formats)

if ( nargin < 4 )
  cats = dsp3.nonun_or_all( labs );
end

if ( nargin < 5 ), prefix = ''; end
if ( nargin < 6 ), formats = { 'epsc', 'png', 'fig' }; end

shared_utils.io.require_dir( p );
fname = dsp3.prefix( prefix, dsp3.fname(labs, cats) );
fname = strrep( fname, filesep, '_' );

dsp3.savefig( f, fullfile(p, fname), formats );

end