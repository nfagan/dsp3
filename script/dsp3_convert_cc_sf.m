function [data, labels] = dsp3_convert_cc_sf(reg, site_offset)

if ( isempty(reg) ), reg = {}; end
if ( nargin < 2 ), site_offset = 0; end

validateattributes( site_offset, {'double'}, {'scalar'}, mfilename, 'site_offset' );

reg = prune_empties( reg );

[data, labels] = linearize( reg, site_offset );

is_valid = find( ~any(any(isinf(data) | isnan(data), 3), 2) );

% is_valid = find( ~all(all(isnan(data), 3), 2) );

keep( labels, is_valid );
data = data(is_valid, :, :);

end

function [data, labels] = linearize(nested, site_offset)

if ( isempty(nested) )
  data = [];
  labels = fcat();
  return
end

n_days = numel( nested );

labels = fcat.with( {'days', 'outcomes' 'sites'} );

site_stp = site_offset + 1;

condition_map = containers.Map( {1, 2, 3, 4}, {'self', 'both', 'other', 'none'} );

all_coh = {};

for i = 1:n_days
  shared_utils.general.progress( i, n_days );
  
  current_day = nested{i};
  
  n_conditions = numel( current_day );
  
  assert( n_conditions == size(condition_map, 1), 'non-matching conditions' );
  
  day_str = sprintf( 'day__%d', i );
  
  for j = 1:n_conditions
    
    current_condition = current_day{j};
    
    n_pairs = numel( current_condition );
    
    outcome_str = condition_map(j);
    
    for k = 1:n_pairs
      current_pair = current_condition{k};
      
      assert( isstruct(current_pair) && numel(current_pair) == 1 && ...
        isfield(current_pair, 'C'), 'Wrong coherence type.' );
      
      coh = current_pair.C;
      
      if ( isempty(coh) )
        continue;
      end
      
      n_freqs = cellfun( @(x) size(x, 1), coh );
      n_trials = cellfun( @(x) size(x, 2), coh );
      
      assert( numel(unique(n_trials)) == 1, 'Incorrect N trials.' );
      assert( numel(unique(n_freqs)) == 1, 'Incorrect N frequencies.' );
      
      n_trials = n_trials(1);
      n_freqs = n_freqs(1);
      
      coh_mat = zeros( n_trials, n_freqs, numel(coh) );
      
      if ( isempty(coh_mat) )
        continue;
      end
      
      for h = 1:numel(coh)
        coh_mat(:, :, h) = coh{h}';
      end
      
      site_str = sprintf( 'site__%d', site_stp+k-1 );
      
      tmplabs = fcat.like( labels );
      
      setcat( tmplabs, {'days', 'outcomes', 'sites'} ...
        , {day_str, outcome_str, site_str} );
      
      repmat( tmplabs, n_trials );
      append( labels, tmplabs );
      
      all_coh{end+1, 1} = coh_mat;
    end
  end
  
  site_stp = site_stp + k;
end

data = vertcat( all_coh{:} );

end

function out = prune_empties(in)

out = in( ~cellfun(@isempty, in) );

end