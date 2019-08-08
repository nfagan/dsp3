function outs = run_granger(event_name, model_order, varargin)

defaults = dsp3.get_common_make_defaults();
defaults.get_data_func = @(x) x.data;
defaults.get_labels_func = @(x) fcat.from(x.labels);
defaults.get_identifier_func = @(varargin) char(varargin{1}('days'));
defaults.mask_func = @default_mask_func;
defaults.site_pairs = [];
defaults.var_mask_inputs = {};
defaults.trial_mask_inputs = {};

inputs = { fullfile('original_aligned_lfp', event_name) };

[params, runner] = dsp3.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();
runner.get_identifier_func = params.get_identifier_func;

if ( isempty(params.site_pairs) )
  site_pairs = dsp3.get_site_pairs( params.config );
else
  site_pairs = params.site_pairs;
end

results = runner.run( @main, event_name, site_pairs, model_order, params );
outputs = shared_utils.pipeline.extract_outputs_from_results( results );

if ( isempty(outputs) )
  outs = struct();
  outs.params = params;
  outs.granger_params = struct();
  outs.data = [];
  outs.labels = fcat();
  outs.t = [];
  outs.f = [];
else
  outs = shared_utils.struct.soa( outputs );
  outs.granger_params = outs.params;
  outs.params = params;
end

end

function mask = default_mask_func(labels)

mask = fcat.mask( labels ...
  , @findnone, {'errors', 'cued'} ...
  , @find, 'pre' ...
);

end

function outs = main(files, event_name, site_pairs, model_order, params)

lfp_file = shared_utils.general.get( files, event_name );

data = params.get_data_func( lfp_file );
labels = params.get_labels_func( lfp_file );

base_mask = params.mask_func( labels );

pairs_are = { 'days' };
vars_are = { 'regions', 'channels', 'days' };

[formatted, var_labs, trial_labs] = ...
  dsp3_gr.paired_formatted_data( data, labels', site_pairs, pairs_are, vars_are, base_mask );

granger_each = { 'outcomes', 'trialtypes' };

outs = ...
  dsp3_gr.time_binned_granger( formatted, var_labs', vars_are, trial_labs, granger_each ...
  , 'var_mask', fcat.mask(var_labs, params.var_mask_inputs{:}) ...
  , 'trial_mask_inputs', params.trial_mask_inputs ...
  , 'verbose', true ...
  , 'min_t', -500 ...
  , 'model_order', model_order ...
);


end