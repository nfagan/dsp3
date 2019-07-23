ct_labels = ...
  dsp3_ct.load_agent_specificity_cell_type_labels( '071919', 'cell_type_targAcq_or_reward.mat' );

%%

[spikes, events, event_key] = dsp3_ct.load_linearized_sua();

%%

is_normalized = true;

targ_ts = events.data(:, event_key('targAcq'));
base_ts = events.data(:, event_key('cueOn'));

targ_min_t = -0.5;
targ_max_t = 0.5;
bin_width = 0.01;

targ_events = mkpair( targ_ts, events.labels' );
[targ_psth, targ_labels, t] = ...
  dsp3_ct.psth( spikes, targ_events, targ_min_t, targ_max_t, bin_width );

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

norm_subdir = ternary( is_normalized, 'norm', 'non-norm' );

dsp3_ct.plot_agent_selective_psth( targ_psth, targ_labels', t ...
  , 'do_save', true ...
  , 'base_subdir', norm_subdir ...
);