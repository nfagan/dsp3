function req_writetable(tbl, p, labs, cats, prefix, ext)

%   REQ_WRITETABLE -- Save table in directory, ensuring it exists.
%
%     dsp3.req_writetable( T, p, labs, cats ); writes the table `T`
%     to a .csv file in the directory given by the absolute path `p`, 
%     creating `p` if it does not already exist. The filename is generated
%     automatically from the unique combinations of labels in `cats`
%     categories, as present in the fcat object `labs`.
%
%     dsp3.req_writetable( ..., prefix ) prepends the character vector
%     `prefix` to the filename.
%
%     dsp3.req_writeable( ..., ext ) creates a file of type `ext` instead
%     of '.csv'.
%
%     See also writetable, fcat, dsp3.fname
%
%     IN:
%       - `tbl` (table)
%       - `p` (char)
%       - `labs` (fcat)
%       - `cats` (cell array of strings, char)
%       - `prefix` (char) |OPTIONAL|
%       - `ext` (char) |OPTIONAL|

if ( nargin < 5 ), prefix = ''; end
if ( nargin < 6 ), ext = '.csv'; end

shared_utils.io.require_dir( p );
fname = dsp3.prefix( prefix, dsp3.fname(labs, cats) );

dsp3.writetable( tbl, fullfile(p, fname), ext );

end