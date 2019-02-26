function dsp3_plot_correlated_sf_coh_by_anatomy(varargin)

defaults = struct();
defaults.is_cached = true;

params = dsp3.parsestruct( defaults, varargin );

coh_mats = shared_utils.io.findmat( dsp3.get_intermediate_dir('summarized_cc_sfcoherence/targacq') );

[coh, coh_labels, freqs, t] = dsp3.load_signal_measure( coh_mats ...
  , 'get_time_series_func', @(~, file) file.t ...
  , 'get_frequencies_func', @(~, file) file.f ...
  , 'get_data_func', @(~, file) file.coherence ...
  , 'get_labels_func', @(~, file) fcat.from(file) ...
  , 'is_cached', params.is_cached ...
);

%%

[anatomy, anatomy_labels, anatomy_key] = dsp3_get_unit_anatomy_info();

%%

unique_channel_indices = findall( anatomy_labels, {'channel', 'region', 'days'} );
unique_channel_indices = cellfun( @(x) x(1), unique_channel_indices );

per_channel_anatomy = anatomy(unique_channel_indices, :);
per_channel_labels = prune( anatomy_labels(unique_channel_indices) );

%%  correlate each dimension separately

[pro_coh, pro_labels] = ...
  calculate_difference_in_summarized_sfcoh_per_channel( coh, coh_labels', 'other', 'none' );
setcat( pro_labels, 'outcomes', 'pro' );

[anti_coh, anti_labels] = ...
  calculate_difference_in_summarized_sfcoh_per_channel( coh, coh_labels', 'self', 'both' );
setcat( anti_labels, 'outcomes', 'anti' );

proanti_coh = [ pro_coh; anti_coh ];
proanti_labels = [ pro_labels; anti_labels ];

t_ind = t >= -250 & t <= 0;
t_meaned = squeeze( nanmean(proanti_coh(:, :, t_ind), 3) );
bands = dsp3.get_bands( 'map' );

[proanti_coh, proanti_labels] = ...
  dsp3.get_band_means( t_meaned, proanti_labels', freqs, bands );

matched_anatomy = ...
  match_anatomy_to_coherence( per_channel_anatomy, per_channel_labels, proanti_labels' );

%%  pca on anatomy

[pca_coeff, pca_score] = pca( per_channel_anatomy );

end

function matched = match_anatomy_to_coherence(anatomy, anatomy_labels, coh_labels)

assert_ispair( anatomy, anatomy_labels );

[coh_I, coh_C] = findall( coh_labels, {'channels', 'regions', 'spike_regions', 'days'} );

matched = nan( joinsize(coh_labels, anatomy) );
missing = false( size(coh_I) );

for i = 1:numel(coh_I)
  coh_ind = coh_I{i};
  current_identifiers = coh_C(:, i);
  
  channel = strrep( current_identifiers(1), 'FP', 'SPK' );
  region = current_identifiers(2);
  day = current_identifiers(4);
  
  selectors = cshorzcat( channel, region, day );
  
  anatomy_ind = find( anatomy_labels, selectors );  
  
  if ( isempty(anatomy_ind) )
    missing(i) = true;
    continue;
  end
  
  assert( numel(anatomy_ind) == 1 );
  
  for j = 1:numel(coh_ind)
    matched(coh_ind(j), :) = anatomy(anatomy_ind, :);
  end
end

d = 10;

end

function [data, labels] = ...
  calculate_difference_in_summarized_sfcoh_per_channel(coh, coh_labels, a, b)

spec = { 'channels', 'regions', 'spike_regions' ...
  , 'days', 'sites', 'trialtypes' };

[data, labels] = dsp3.summary_binary_op( coh, coh_labels', spec, a, b ...
, @minus, @(x) nanmean(x, 1) );

end