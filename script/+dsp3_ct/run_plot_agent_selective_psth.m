ct_labels = ...
  dsp3_ct.load_agent_specificity_cell_type_labels( '073119', 'cell_type_targAcq_or_reward.mat' );

%%

[spikes, events, event_key] = dsp3_ct.load_linearized_sua();

%%

is_normalized = false;

targ_epoch = 'targAcq';

targ_ts = events.data(:, event_key(targ_epoch));
base_ts = events.data(:, event_key('cueOn'));

targ_min_t = -0.3;
targ_max_t = 0.3;
bin_width = 0.01;

include_raster = true;

targ_events = mkpair( targ_ts, events.labels' );
[targ_psth, targ_labels, t, targ_rasters] = ...
  dsp3_ct.psth( spikes, targ_events, targ_min_t, targ_max_t, bin_width, include_raster );

targ_psth = targ_psth / bin_width;

dsp3_ct.label_agent_selective_units( targ_labels, ct_labels );

if ( is_normalized )
  base_events = mkpair( base_ts, events.labels' );
  [base_psth, ~] = dsp3_ct.psth( spikes, base_events, -0.15, 0, 0.01 );
  
  base_psth = base_psth / bin_width;
  base_psth = nanmean( base_psth, 2 );
  
  targ_psth = targ_psth - base_psth;
end

%%

has_spike = cellfun( @(x) sum(~isnan(x)) > 0, targ_rasters );
unit_spec = { 'unit_uuid', 'outcomes' };

mask = fcat.mask( targ_labels ...
  , @find, 'choice' ...
  , @findnone, 'errors' ...
  , @find, 'unit_uuid__213' ...
);

[prop_labs, unit_I] = keepeach( targ_labels', unit_spec, mask );
props = rowzeros( numel(unit_I) );
cts = rowzeros( numel(unit_I) );

for i = 1:numel(unit_I)
  props(i) = sum( has_spike(unit_I{i}) ) / numel( unit_I{i} );
  cts(i) = sum( has_spike(unit_I{i}) );
end

pl = plotlabeled.make_common();

axs = pl.bar( cts, prop_labs, 'outcomes', 'trialtypes', {'unit_uuid', 'region'} );

%%

norm_subdir = ternary( is_normalized, 'norm', 'non-norm' );
base_subdir = sprintf( '%s-%s', targ_epoch, norm_subdir );

dsp3_ct.plot_agent_selective_psth( targ_psth, targ_rasters, targ_labels', t ...
  , 'do_save', true ...
  , 'base_subdir', base_subdir ...
);