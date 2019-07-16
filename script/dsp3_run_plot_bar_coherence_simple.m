function dsp3_run_plot_bar_coherence_simple()

rev_types = dsp3.get_rev_types();
bands = dsp3.get_bands( 'map' );

% cued_time_window = [ 50, 150 ];
% choice_time_window = [ -250, -100 ];
% choice_time_window = [ -50, 50 ];
choice_time_window = [ 0, 150 ];
cued_time_window = [ 50, 150 ];

rev_t = 'orig';
base_subdir = 'choice_on0_new_data';

band_names = { 'new_gamma', 'beta' };
pro_minus_antis = [false, true];
% pro_minus_antis = [false, true];
% plot_function_types = { 'box', 'violin', 'bar' };
plot_function_types = { 'box' };

use_custom_limits = true;

is_new_data = true;

C = dsp3.numel_combvec( band_names, pro_minus_antis, plot_function_types );

for i = 1:size(C, 2)
  shared_utils.general.progress( i, size(C, 2) );
  
  comb = C(:, i);
  
  freq_roi_name = band_names{comb(1)};
  is_pro_minus_anti = pro_minus_antis(comb(2));
  plot_function_type = plot_function_types{comb(3)};
  
  freq_roi = bands(freq_roi_name);

  use_subdir = sprintf( '%s_%s_%s', base_subdir, plot_function_type, rev_t );
  base_prefix = sprintf( 'bar__%s', freq_roi_name );

  mask_inputs = { @findnot, {'targacq', 'cued'}, @findnot, {'targon', 'choice'} };
  
  epochs = { 'targacq' };
  
  if ( is_pro_minus_anti )
    epochs{end+1} = 'targon';
    bar_ylims = [-0.018, 7e-3];
    line_ylims = [-0.03, 0.015];
  else
    bar_ylims = [-6.5e-3, 6.5e-3];
    line_ylims = [-12e-3, 10e-3];
  end
  
  if ( ~use_custom_limits )
    bar_ylims = [];
    line_ylims = [];
  end
  
  if ( is_new_data )
    load_func_inputs = { 'load_func', @(params) load_new_data(params, epochs) };
  else
    load_func_inputs = {};
  end

  dsp3_plot_bar_coherence_simple( ...
      'epochs', epochs ...
    , 'is_cached', true ...
    , 'is_pro_minus_anti', is_pro_minus_anti ...
    , 'mask_inputs', mask_inputs ...
    , 'base_prefix', base_prefix ...
    , 'base_subdir', use_subdir ...
    , 'freq_window', freq_roi ...
    , 'remove', rev_types(rev_t) ...
    , 'bar_ylims', bar_ylims ...
    , 'line_ylims', line_ylims ...
    , 'drug_type', 'nondrug_nanmedian' ...
    , 'freq_roi_name', freq_roi_name ...
    , 'cued_time_window', cued_time_window ...
    , 'choice_time_window', choice_time_window ...
    , 'add_bar_points', true ...
    , 'bar_plot_type', plot_function_type ...
    , load_func_inputs{:} ...
  );
end

end

function [data, labels, freqs, t] = load_new_data(params, epochs)

import shared_utils.io.fullfiles;

file_ps = dsp3.get_intermediate_dir( fullfiles('original_summarized_coherence', epochs), params.config );
mats = shared_utils.io.findmat( file_ps );

[data, labels, freqs, t] = bfw.load_time_frequency_measure( mats ...
  , 'get_labels_func', @(file) file.labels ...
);

no_527 = findnone( labels, 'day__05272017');
keep( labels, no_527 );
data = data(no_527, :, :);

t = t * 1e3;

addcat( labels, 'measure' );

end