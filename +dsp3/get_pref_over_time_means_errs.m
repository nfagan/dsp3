function [t_series_means, t_series_errs, map, outs] = get_pref_over_time_means_errs( pref )

import shared_utils.container.cat_parse_double;

[I, C] = pref.get_indices( {'outcomes', 'administration'} );

outs = unique( C(:, 1) );
map = containers.Map( outs, 1:numel(outs) );

bin_pre = max( cat_parse_double('trial_bin__', pref.uniques_where('trial_bin', 'pre')) );
bin_post = max( cat_parse_double('trial_bin__', pref.uniques_where('trial_bin', 'post')) );

t_series_means = nan( 1, bin_pre+bin_post );
t_series_errs = nan( size(t_series_means) );

for i = 1:numel(I)
  subset = pref(I{i});
  
  if ( strcmp(C{i, 2}, 'pre') )
    start_from = 0;
  else
    start_from = bin_pre;
  end
  
  bins = subset( 'trial_bin' );
  bin_ns = shared_utils.container.cat_parse_double( 'trial_bin__', bins );
  [~, sorted_ind] = sort( bin_ns );
  bins = bins( sorted_ind );
  
  for j = 1:numel(bins)
    one_bin = subset(bins(j));
    
    y_coord = shared_utils.container.cat_parse_double( 'trial_bin__', bins{j} );
    
    t_series_means(map(C{i, 1}), start_from+y_coord) = nanmean( one_bin.data );
    t_series_errs(map(C{i, 1}), start_from+y_coord) = rowops.sem( one_bin.data );
    
  end
end