function out = get_messy_lda_data(lda_dir)

fnames = shared_utils.io.dirnames( lda_dir, 'all_data.mat', false );

unds = strfind( fnames, '_' );
numinds = percell( @(x) [{x(1)+1:x(2)-1}, {x(2)+1:x(3)-1}], unds );
inds = cell( size(numinds) );

for i = 1:numel(numinds)
  start = str2double( fnames{i}(numinds{i}{1}) );
  stop = str2double( fnames{i}(numinds{i}{2}) );
  assert( ~isnan(start) && ~isnan(stop) );
  inds{i} = [ start, stop ];
end

[~, I] = sort( cellfun(@(x) min(x), inds) );

inds = inds(I);
fnames = fnames(I);

ranges = cellfun( @(x) x(1):x(2), inds, 'un', false );
ranges = horzcat( ranges{:} );

assert( issorted(ranges) && all(diff(ranges) == 1) );

full_fnames = percell( @(x) fullfile(lda_dir, x), fnames );
files = cell( size(full_fnames) );

for i = 1:numel(files)
  shared_utils.general.progress( i, numel(files) );
  files{i} = shared_utils.io.fload( full_fnames{i} );
end

all_data = zeros( size(files{1}.data) );

for i = 1:numel(files)
  crange = inds{i}(1):inds{i}(2);
  all_data(:, crange, :, :) = files{i}.data(:, crange, :, :);
end

out = set_data( files{1}, all_data );

end