function source_pl2_files = find_pl2_files(pl2_files, root_path)

source_pl2_files = cell( size(pl2_files) );

for i = 1:numel(pl2_files)
  shared_utils.general.progress( i, numel(pl2_files) );
  
  pl2_filepath = shared_utils.io.find( root_path, pl2_files{i}, true );
  
  if ( numel(pl2_filepath) ~= 1 )
    error( 'Expected 1 pl2 file: "%s"; found %d', pl2_files{i}, numel(pl2_filepath) );
  end
  
  source_pl2_files(i) = pl2_filepath;
end

end