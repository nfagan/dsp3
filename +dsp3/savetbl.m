function savetbl(T, p, labs, fnames_are, prefix)

%   SAVETBL -- Write table to file.
%
%     ... savetbl( T, p, labs, fnames ); writes the table `T` to a file in
%     the directory given by `p`. The filename of `T` is generated
%     automatically from label combinations in `fnames` categories, as
%     present in the fcat object `labs`.
%
%     The directory `p` is created if it does not already exist.
%
%     ... savetbl( ..., prefix ) prepends `prefix` to the automatically
%     generated filename.
%
%     IN:
%       - `T` (table)
%       - `p` (char)
%       - `labs` (fcat)
%       - `fnames_are` (cell array of strings, char)
%       - `prefix` (char) |OPTIONAL|

if ( nargin < 5 )
  prefix = '';
end

if ( isempty(T) ), return; end

shared_utils.io.require_dir( p );
fname = dsp3.prefix( prefix, dsp3.fname(labs, fnames_are) );
dsp3.writetable( T, fullfile(p, fname) ); 

end