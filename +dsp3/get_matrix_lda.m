function [totdata, totlabs, freqs, t_series] = get_matrix_lda( transformed )

t_series = get_time_series( transformed );

n_band = numel( transformed('band') );
I = transformed.get_indices( setdiff(transformed.categories(), 'band') );

totdata = zeros( numel(I), n_band, numel(t_series) );

new_labs = SparseLabels();

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  subset_band = transformed(I{i});
  bands = subset_band( 'band' );
  
  assert( numel(bands) == n_band );
  
  for j = 1:numel(bands)
    ind = subset_band.where(bands{j});
    totdata(i, j, :) = subset_band.data(ind);
  end
  
  labs = one( subset_band.labels );
  new_labs = append( new_labs, labs );
end

totlabs = fcat.from( new_labs );

freqs = transformed.frequencies;

end