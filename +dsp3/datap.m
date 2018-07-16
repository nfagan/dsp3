function p = datap(kind, components, conf)

%   DATAP -- Get absolute path to data subfolder.
%
%     p = ... datap() returns the absolute path to the root data folder.
%     p = ... datap( SUBFOLDER ) returns the absolute path to the
%     subfolder `SUBFOLDER` within the root data folder.
%     p = ... datap( ..., COMPONENTS ) returns the absolute path(s) to the
%     additional subfolder(s) within `SUBFOLDER` as given by `COMPONENTS`. 
%     Paths are created with `shared_utils.io.fullfiles()`.
%
%     See also shared_utils.io.fullfiles, dsp3.config.create
%
%     IN:
%       - `kind` (char)
%       - `components` (cell array of strings, char)
%       - `conf` (config_file) |OPTIONAL|
%     OUT:
%       - `p` (cell array of strings)

if ( nargin < 1 ), kind = ''; end
if ( nargin < 2 ), components = ''; end

if ( nargin < 3 )
  conf = dsp3.config.load();
else
  dsp3.util.assertions.assert__is_config( conf );
end

components = reqcell( components );
base_p = dsp3.fullfiles( conf.PATHS.data_root, kind );
p = dsp3.fullfiles( base_p, components{:} );

end