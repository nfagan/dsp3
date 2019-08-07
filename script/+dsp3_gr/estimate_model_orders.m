function outs = estimate_model_orders(event_name, varargin)

defaults = dsp3.get_common_make_defaults();
defaults.get_data_func = @(x) x.data;
defaults.get_labels_func = @(x) fcat.from(x.labels);
defaults.get_identifier_func = @(varargin) char(varargin{1}('days'));
defaults.mask_func = @default_mask_func;
defaults.max_model_order = 32;
defaults.regression_method = 'LWR';
defaults.site_pairs = [];

inputs = { fullfile('original_aligned_lfp', event_name) };

[params, runner] = dsp3.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();
runner.get_identifier_func = params.get_identifier_func;

if ( isempty(params.site_pairs) )
  site_pairs = dsp3.get_site_pairs( params.config );
else
  site_pairs = params.site_pairs;
end

results = runner.run( @main, event_name, site_pairs, params );
outputs = shared_utils.pipeline.extract_outputs_from_results( results );

if ( isempty(outputs) )
  outs = struct();
  outs.model_orders = [];
  outs.labels = fcat();
else
  outs = shared_utils.struct.soa( outputs );
end

end

function out = main(files, event_name, site_pairs, params)

lfp_file = shared_utils.general.get( files, event_name );
data = params.get_data_func( lfp_file );
labels = params.get_labels_func( lfp_file );

base_mask = params.mask_func( labels );
regression_method = params.regression_method;
max_model_order = params.max_model_order;

pairs_are = { 'days' };
vars_are = { 'regions', 'channels', 'days' };

[formatted, var_labs] = ...
  dsp3_gr.paired_formatted_data( data, labels', site_pairs, pairs_are, vars_are, base_mask );

[model_orders, order_labs] = ...
  dsp3_gr.estimate_model_order( formatted, var_labs', max_model_order, regression_method );

out = struct();
out.model_orders = model_orders;
out.labels = order_labs;

end

function mask = default_mask_func(labels)

[~, mask] = dsp3.get_subset( labels', 'nondrug_wbd' );
mask = fcat.mask( labels, mask ...
  , @findnone, {'errors', 'cued'} ...
);

end