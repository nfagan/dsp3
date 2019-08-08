x = dsp3.load_one_intermediate( 'original_aligned_lfp/targAcq-150-cc', 'day__06092017' );
y = dsp3.load_one_intermediate( 'original_aligned_lfp/targAcq-150-cc', 'day__06092016' );

z = [ x; y ];

site_pairs = dsp3.get_site_pairs();

%%

res = dsp3_gr.estimate_model_orders( 'targAcq-150-cc' ...
  , 'is_parallel', false ...
);

%%

data = z.data;
labels = fcat.from( z.labels );

[~, base_mask] = dsp3.get_subset( labels', 'nondrug_wbd' );
base_mask = fcat.mask( labels, base_mask ...
  , @findnone, {'errors'} ...
  , @find, 'self' ...
);

pairs_are = { 'days' };
vars_are = { 'regions', 'channels', 'days' };

[formatted, var_labs, trial_labs] = ...
  dsp3_gr.paired_formatted_data( data, labels', site_pairs, pairs_are, vars_are, base_mask );

granger_each = { 'outcomes', 'trialtypes' };

granger_outs = ...
  dsp3_gr.time_binned_granger( formatted, var_labs', vars_are, trial_labs, granger_each ...
  , 'var_mask', find(var_labs, 'var_id__1') ...
  , 'verbose', true ...
  , 'min_t', -500 ...
  , 'model_order', 10 ...
);

%%

estimate_model_order = true;
max_lags = 1e3;
regression_method = 'LWR';
model_order = 32;
sr = 1e3;

if ( estimate_model_order )
  [~, ~, model_order, ~] = tsdata_to_infocrit( X, model_order, regression_mode );
end

n_freqs = sr / 2;

[A, sig] = tsdata_to_var( X, model_order, regression_method );
[G, info] = var_to_autocov( A, sig, max_lags );
[spect, freqs] = autocov_to_spwcgc( G, n_freqs );