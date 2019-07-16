function [ps, labels] = lda_p_value_from_null(real_perf, null_perf, each_I)

assert_ispair( real_perf );
assert_ispair( null_perf );

ps = zeros( numel(each_I), 1 );
labels = cell( numel(each_I), 1 );

parfor i = 1:numel(each_I)
  real_ind = each_I{i};
  
  if ( numel(real_ind) ~= 1 )
    error( 'Expected 1 real p value; got %d.', numel(real_ind) );
  end
  
  uniques = combs( real_perf.labels, getcats(real_perf.labels), real_ind );
  
  null_ind = find( null_perf.labels, uniques );
  num_null = numel( null_ind );
  
  real_p = real_perf.data(real_ind);
  null_ps = null_perf.data(null_ind); 
  
  labels{i} = append1( fcat, real_perf.labels, real_ind );
  ps(i) = 1 - ( sum(real_p > null_ps) / num_null );
end

labels = vertcat( fcat, labels{:} );

end