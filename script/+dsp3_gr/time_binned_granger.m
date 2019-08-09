function outs = time_binned_granger(var_data, var_labs, vars_are, trial_labs, subsets_are, varargin)

assert_ispair( var_data, var_labs );
assert_ispair( trial_labs, var_labs );

vars_are = cellstr( vars_are );
to_label = vars_are(hascat(var_labs, vars_are));

defaults = struct();
defaults.model_order = 32;
defaults.regression_method = 'LWR';
defaults.var_each = { 'var_id' };
defaults.var_mask = rowmask( var_labs );
defaults.trial_mask_inputs = {};
defaults.window_size = 150;
defaults.step_size = 50;
defaults.sample_rate = 1e3;
defaults.max_lags = [];
defaults.verbose = false;
defaults.min_t = 0;

params = dsp3.parsestruct( defaults, varargin );

regression_method = params.regression_method;
model_order = params.model_order;
win = params.window_size;
step = params.step_size;
sr = params.sample_rate;
max_lags = params.max_lags;

[pair_labs, pair_I] = keepeach( var_labs', params.var_each, params.var_mask );

n_freqs = sr / 2;
freqs = sfreqs( n_freqs, sr );

tot_labs = cell( size(pair_I) );
tot_dat = cell( size(pair_I) );
t = cell( size(pair_I) );

for i = 1:numel(pair_I)
  if ( params.verbose )
    fprintf( '\n %d of %d', i, numel(pair_I) );
  end
  
  pair_ind = pair_I{i};
  combined = vertcat( var_data{pair_ind} );
  
  num_combined = size( combined, 1 );
  num_samples = size( combined, 2 );
  bin_inds = shared_utils.vector.slidebin( 1:num_samples, win, step, true );

  src_dest_inds = combvec( 1:num_combined, 1:num_combined );
  same_inds = src_dest_inds(1, :) == src_dest_inds(2, :);
  src_dest_inds(:, same_inds) = [];

  num_combs = size( src_dest_inds, 2 );
  
  [subset_I, subset_labs] = ...
    get_and_validate_trial_subset_indices( trial_labs, subsets_are, pair_ind, params.trial_mask_inputs );

  tmp_granger = nan( num_combs * numel(subset_I), numel(freqs), numel(bin_inds) );
  tmp_labs = fcat();
  
  for idx = 1:numel(subset_I)
    if ( params.verbose )
      fprintf( '\n   %d of %d', idx, numel(subset_I) );
    end
    
    subset_ind = subset_I{idx};
    time_bin_granger = nan( num_combs, numel(freqs), numel(bin_inds) );
    
    parfor j = 1:numel(bin_inds)
      if ( params.verbose )
        fprintf( '\n     %d of %d', j, numel(bin_inds) );
      end
      
      X = combined(:, bin_inds{j}, subset_ind);

      try
        [A, sig] = tsdata_to_var( X, model_order, regression_method );
        [G, info] = var_to_autocov( A, sig, max_lags );
        granger = autocov_to_spwcgc( G, n_freqs );
      catch err
        warning( err.message );
        granger = nan( num_combined, num_combined, numel(freqs) );
      end
      
      for k = 1:num_combs
        comb_inds = src_dest_inds(:, k);
        
        ind_a = comb_inds(1);
        ind_b = comb_inds(2);

        % rows are dest, cols are source
        src_to_targ = squeeze( granger(ind_a, ind_b, :) );

        time_bin_granger(k, :, j) = src_to_targ;
      end
    end

    for j = 1:num_combs
      dest_ind = pair_ind(src_dest_inds(1, j));
      src_ind = pair_ind(src_dest_inds(2, j));

      base_labs = make_labels( pair_labs, i, src_ind, dest_ind, var_labs, to_label, subset_labs, idx );
      append( tmp_labs, base_labs );
    end

    assign_stp = ((idx-1) * num_combs + 1):(idx*num_combs);
    tmp_granger(assign_stp, :, :) = time_bin_granger;
  end
  
  tot_dat{i} = tmp_granger;
  tot_labs{i} = tmp_labs;
  t{i} = cellfun( @min, bin_inds ) - 1 + params.min_t;
end

outs = struct();
outs.params = params;
outs.data = vertcat( tot_dat{:} );
outs.labels = prune( vertcat(fcat(), tot_labs{:}) );
outs.t = conditional( @() isempty(outs.data), @() [], @() t{1} );
outs.f = conditional( @() isempty(outs.data), @() [], @() freqs );

end

function out_labs = make_labels(pair_labs, pair_i, src_ind, dest_ind, var_labs, to_label, subset_labs, idx)

out_labs = append1( fcat(), pair_labs, pair_i );

for i = 1:numel(to_label)   
  src_label = char( cellstr(var_labs, to_label{i}, src_ind) );
  dest_label = char( cellstr(var_labs, to_label{i}, dest_ind) );

  if ( ~strcmp(src_label, dest_label) )
    joined_label = sprintf( '%s_%s', src_label, dest_label );
    setcat( out_labs, to_label{i}, joined_label, length(out_labs) );
  end
end

conditionally_apply_labels( out_labs, subset_labs, length(out_labs), idx );

end

function conditionally_apply_labels(dest_labels, src_labels, dest_ind, src_ind)

assert( numel(dest_ind) == 1 && numel(src_ind) == 1 );

cats_to_check = intersect( getcats(src_labels), getcats(dest_labels) );

for i = 1:numel(cats_to_check)
  src_label = char( cellstr(src_labels, cats_to_check{i}, src_ind) );
  dest_label = char( cellstr(dest_labels, cats_to_check{i}, dest_ind) );
  
  if ( ~strcmp(src_label, dest_label) )
    if ( strcmp(dest_label, makecollapsed(dest_labels, cats_to_check{i})) )
      setcat( dest_labels, cats_to_check{i}, src_label, dest_ind );
    end
  end
end

end

function [subset_I, subset_labs] = get_and_validate_trial_subset_indices(trial_labels, subsets_are, pair_ind, mask_inputs)

subset_I = {};
subset_labs = fcat();

for i = 1:numel(pair_ind)
  trial_labs = trial_labels{pair_ind(i)};
  mask = fcat.mask( trial_labs, mask_inputs{:} );
  
  [tmp_subset_labs, tmp_subset_I] = keepeach( copy(trial_labs), subsets_are, mask );
  
  if ( i == 1 )
    subset_I = tmp_subset_I;
    subset_labs = tmp_subset_labs;
  else
    assert( isequal(subset_I, tmp_subset_I), 'Trial subsets were not equal.' );
  end
end

end