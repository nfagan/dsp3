function targ = make_psth(targ_ts, event_labels, spikes, targ_min_t, targ_max_t)

assert_ispair( targ_ts, event_labels );
targ_events = mkpair( targ_ts, event_labels' );

[targ_psth, targ_labels] = dsp3_ct.psth( spikes, targ_events, targ_min_t, targ_max_t );

s_per_bin = targ_max_t - targ_min_t;

targ_rate = targ_psth ./ (1 / s_per_bin);
targ = mkpair( targ_rate, targ_labels );

end