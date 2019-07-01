function fname = req_savefig(f, p, labs, cats, prefix, formats)

%   REQ_SAVEFIG -- Save figure in directory with auto-generated filename,
%   	creating the directory if it does not exist.
%
%     dsp3.req_savefig( f, p, labels, categories ); saves the figure `f`
%     to a file in the directory given by `p`, creating `p` if it does not
%     exist. The filename for `f` is generated from entries in `categories` 
%     of `labels`, an fcat object.
%
%     dsp3.req_savefig( ..., prefix ) prepends `prefix`, a char vector, to
%     the filename before saving.
%
%     dsp3.req_savefig( ..., formats ) saves figures in each of `formats`,
%     a cell array of strings.
%
%     filename = dsp3.req_savefig(...) returns the filename used to save
%     `f`.
%
%     See also fcat, savefig

if ( nargin < 4 )
  cats = dsp3.most_significant_categories( labs );
end

if ( nargin < 5 ), prefix = ''; end
if ( nargin < 6 ), formats = { 'epsc', 'png', 'fig' }; end

shared_utils.io.require_dir( p );
fname = dsp3.prefix( prefix, dsp3.fname(labs, cats) );
fname = strrep( fname, filesep, '_' );

dsp3.savefig( f, fullfile(p, fname), formats );

end