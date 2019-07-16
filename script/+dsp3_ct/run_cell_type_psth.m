conf = dsp3.config.load();
consolidated = dsp3.get_consolidated_data( conf );
sua = dsp3_ct.load_sua_data( conf );
[spike_ts, spike_labels, event_ts, event_labels, new_to_orig] = dsp3_ct.linearize_sua( sua );

cell_type_labels = dsp3_ct.load_cell_type_labels( 'targAcq.mat' );

spikes = mkpair( spike_ts, spike_labels' );

%%

is_norm = false;
is_divisive_norm = false;
remove_all_same = true;

% epoch_name = 'targOn';
% min_t = -0.2;
% max_t = 0.5;

epoch_name = 'rwdOn';
min_t = -0.2;
max_t = 0.5;

% epoch_name = 'targAcq';
% min_t = -0.2;
% max_t = 0.5;
% bin_size = 0.01;

baseline_name = 'cueOn';
base_min_t = -0.15;
base_max_t = 0;

use_evt_ts = event_ts(:, consolidated.event_key(epoch_name));
use_evt_ts(use_evt_ts == 0) = nan;

baseline_ts = event_ts(:, consolidated.event_key(baseline_name));
baseline_ts(baseline_ts == 0) = nan;

[psth, psth_labels, t] = ...
  dsp3_ct.psth( spikes, mkpair(use_evt_ts, event_labels), min_t, max_t, bin_size );

[base_psth, base_psth_labels, base_t] = ...
  dsp3_ct.psth( spikes, mkpair(baseline_ts, event_labels), base_min_t, base_max_t, bin_size );
base_psth = nanmean( base_psth, 2 );

same_specifier = ternary( remove_all_same, '_without_all_zero', '' );
epoch_specifier = sprintf( '%s_%0.2f_%0.2f%s', epoch_name, min_t, max_t, same_specifier );
norm_specifier = ternary( is_norm, 'normalized', 'non_normalized' );

%%

if ( is_norm )
  if ( is_divisive_norm )
    base_zeros = base_psth == 0;
    use_psth = psth ./ base_psth;
    use_psth(base_zeros, :) = nan;
  else
    use_psth = psth - base_psth;
  end
else
  use_psth = psth;
end

mask = fcat.mask( psth_labels ...
  , @find, {'pre'} ...
  , @findnone, 'errors' ...
);

mean_each = { 'unit_uuid', 'trialtypes', 'outcomes' };
[mean_labs, mean_I] = keepeach( psth_labels', mean_each, mask );
psth_means = bfw.row_nanmean( use_psth, mean_I );

%%

use_subdir = sprintf( '%s_%s', epoch_specifier, norm_specifier );

dsp3_ct.plot_psth( psth_means, t, mean_labs', cell_type_labels ...
  , 'do_save', true ...
  , 'base_subdir', use_subdir ...
);

%%

has_nans = any( isnan(psth_means), 2 );
is_all_same = false( size(psth_means, 1), 1 );
is_all_zero = false( size(is_all_same) );

for i = 1:size(psth_means, 1)
  is_all_same(i) = numel( unique(psth_means(i, :)) ) == 1;
  is_all_zero(i) = all( unique(psth_means(i, :)) == 0 );
end

[~, latency_ind] = max( psth_means, [], 2 );
latencies = t(1, latency_ind)';
latencies(has_nans) = nan;

if ( remove_all_same )
  latencies(is_all_same) = nan;
end

%%

dsp3_ct.plot_latencies( latencies, mean_labs', cell_type_labels ...
  , 'do_save', true ...
  , 'base_subdir', epoch_specifier ...
);