function results = estimate_model_orders(event_name, varargin)

defaults = dsp3.get_common_make_defaults();
defaults.get_data_func = @(x) x.data;
defaults.get_labels_func = @(x) fcat.from(x.labels);
defaults.get_identifier_func = @(x) char(x('days'));

inputs = { fullfile('original_aligned_lfp', event_name) };

[params, runner] = dsp3.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();
runner.get_identifier_func = params.get_identifier_func;

results = runner.run( @main, event_name, params );

end

function main(files, event_name, params)

[~, base_mask] = dsp3.get_subset( labels', 'nondrug_wbd' );
base_mask = fcat.mask( labels, base_mask ...
  , @findnone, {'errors', 'cued'} ...
);

pairs_are = { 'days' };
vars_are = { 'regions', 'channels', 'days' };

[formatted, var_labs, trial_labs] = ...
  dsp3_gr.paired_formatted_data( data, labels', site_pairs, pairs_are, vars_are, base_mask );

[model_orders, order_labs] = dsp3_gr.estimate_model_order( formatted, var_labs', 32, 'LWR' );

end