function [totdata, totlabs, freqs] = get_matrix_rf( date_dir )

conf = dsp3.config.load();

mats = shared_utils.io.find( fullfile(conf.PATHS.dsp2_analyses, 'rf', date_dir), '.mat' );

N = numel( mats );

specificity = { 'administration', 'drugs', 'days', 'contexts', 'measure' };

totdata = [];
totlabs = fcat();

for i = 1:N
  fprintf( '\n %d of %d', i, N );
  
  rf = shared_utils.io.fload( mats{i} );
  
  rf = only( rf, {'real_percent'} );
  
  pcorr = rf.data;
  plabs = fcat.from( rf.labels );
  freqs_str = incat( plabs, 'band' );
  freqs = shared_utils.container.cat_parse_double( 'band__', freqs_str );
  [freqs, sort_ind] = sort( freqs );
  freqs_str = freqs_str(sort_ind);
  
  n_bands = numel( incat(plabs, 'band') );
  
  [newlabs, I] = keepeach( plabs', specificity );
  
  cellfun( @(x) assert(numel(x) == n_bands, 'More than 1 frequency per element.'), I );
  
  mat = zeros( numel(I), n_bands, size(pcorr, 2) );
  
  for j = 1:numel(I)
    lab_ind = I{j};
    
    for k = 1:numel(freqs_str)
      
      freq_ind = intersect( lab_ind, find(plabs, freqs_str{k}) );
      
      assert( numel(freq_ind) == 1 );
      
      mat(j, k, :) = pcorr(freq_ind, :);
      
    end
  end
  
  append( totlabs, newlabs );
  totdata = [ totdata; mat ];
end

end