function out = require_intermediate_mats( user_files, intermediate_path, containing )

%   REQUIRE_INTERMEDIATE_MATS -- Obtain all intermediate files in a
%     directory, if none are specified manually.
%
%     IN:
%       - `user_files` (cell array of strings, {})
%       - `intermediate_path` (char)
%       - `containing` (char) -- Substring to search for.
%     OUT:
%       - `out` (cell array of strings)

if ( nargin == 1 )
  if ( ischar(user_files) )
    out = find_intermediate_dir( user_files );
  else
    shared_utils.assertions.assert__is_cellstr( user_files, 'intermediate paths' );
    all_files = cellfun( @find_intermediate_dir, user_files, 'un', false );
    out = horzcat( all_files{:} );
  end
  return;
end

if ( nargin < 3 )
  containing = [];
end

if ( isempty(user_files) )
  out = shared_utils.io.find( intermediate_path, '.mat' );
else
  user_files = shared_utils.cell.ensure_cell( user_files );
  out = cellfun( @(x) fullfile(intermediate_path, x), user_files, 'un', false );
end

if ( ~isempty(containing) )
  out = shared_utils.cell.containing( out, containing );
end

end

function files = find_intermediate_dir(x)
files = shared_utils.io.find( dsp3.get_intermediate_dir(x), '.mat' );
end