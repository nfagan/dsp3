function transformed = get_transformed_lda( lda, N, alpha )

import dsp2.analysis.lda.add_confidence_interval;

if ( nargin < 2 )
  N = 100;
end

if ( nargin < 3 )
  alpha = 0.05;
end

w_in = { 'days', 'regions', 'band', 'epochs', 'contexts' ...
  , 'trialtypes', 'drugs', 'administration' };

C = lda.pcombs( w_in );

all_transformed = cell( size(C, 1), 1 );

parfor i = 1:size(C, 1)
  fprintf( '\n %d of %d', i, size(C, 1) );
  
  shuffed_mean = only( lda, [C(i, :), 'shuffled_percent'] );
  shuffed_dev = only( lda, [C(i, :), 'shuffled_std'] );
  real_mean = only( lda, [C(i, :), 'real_percent'] );
  real_dev = only( lda, [C(i, :), 'real_std'] );
  
  assert( shape(shuffed_mean, 1) == 1 && shapes_match(shuffed_mean, shuffed_dev) );
  
  shuffed = add_confidence_interval( shuffed_mean, shuffed_dev, alpha, N, 'shuffled' );
  actual = add_confidence_interval( real_mean, real_dev, alpha, N, 'real' );
  
  all_transformed{i} = append( shuffed, actual );
end

transformed = SignalContainer.concat( all_transformed );

transformed.data = transformed.data * 100;

end