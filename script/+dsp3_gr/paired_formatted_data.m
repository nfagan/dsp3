function [formatted, var_labs, trial_labs] = paired_formatted_data(data, labels, site_pairs, pairs_are, vars_are, mask)

assert_ispair( data, labels );

if ( nargin < 6 )
  mask = rowmask( labels );
end

% Important that 'days' be first here.
pairs_are = cshorzcat( 'days', pairs_are );

[pair_I, pair_C] = findall( labels, pairs_are, mask );

formatted = {};
var_labs = fcat();
trial_labs = {};

var_id = 0;

for i = 1:numel(pair_I)
  day = pair_C{1, i};
  pairs = site_pairs.channels{strcmp(site_pairs.days, day)};
  regions = site_pairs.channel_key;
  
  num_pairs = size( pairs, 1 );
  
  for j = 1:num_pairs
    ind_a = find( labels, [regions(1), pairs{j, 1}], pair_I{i} );
    ind_b = find( labels, [regions(2), pairs{j, 2}], pair_I{i} );
    
    pair_mask = [ ind_a; ind_b ];
    
    [tmp_formatted, tmp_var_labs, tmp_trial_labs] = ...
      dsp3_gr.formatted_samples_array( data, labels', vars_are, pair_mask );
    
    addsetcat( tmp_var_labs, 'var_id', sprintf('var_id__%d', var_id) );
    
    for k = 1:size(tmp_formatted, 1)
      formatted = [formatted; {tmp_formatted(k, :, :)}];
    end
    
    append( var_labs, tmp_var_labs );
    trial_labs = [trial_labs; repmat({tmp_trial_labs}, length(tmp_var_labs), 1)];
    var_id = var_id + 1;
  end
end

end