function outs = parse_file_identifiers(files)

filenames = shared_utils.io.filenames( files );

outcomes = cell( numel(filenames), 1 );
file_parts = nan( size(outcomes) );
file_ids = cell( size(outcomes) );
regions = cell( size(outcomes) );

for i = 1:numel(filenames)
  components = strsplit( filenames{i}, '-' );
  assert( numel(components) == 3, 'Expected 3 components per file identifier; got %d', numel(components) );
  
  outcomes{i} = components{1};
  file_parts(i) = str2double( components{2} );
  file_ids{i} = components{3};
  regions{i} = components{3}(1:3);
end

outs = struct();
outs.outcomes = outcomes;
outs.file_parts = file_parts;
outs.file_ids = file_ids;
outs.regions = regions;

end