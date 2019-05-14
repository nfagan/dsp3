function f = auto_filename(labels, path)

%   AUTO_FILENAME -- Create filename that does not collide with existing files.
%
%     filename = dsp3.auto_filename( labels, path ); creates a filename
%     from the most significant categories in `labels`, such that it does
%     not collide with any folder or file present in `path`.
%
%     See also dsp3.make_filename

if ( nargin == 1 || ~shared_utils.io.dexists(path) )
  existing_filenames = {};
else
  existing_filenames = shared_utils.io.filenames( dir_contents(path) );
end

f = dsp3.make_filename( labels, existing_filenames );

end

function names = dir_contents(path)

contents = dir( path );

is_dot = arrayfun( @(x) strcmp(x.name, '.') || strcmp(x.name, '..'), contents );

names = { contents(~is_dot).name };

end