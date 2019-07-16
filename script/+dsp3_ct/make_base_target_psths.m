function [base, targ] = make_base_target_psths(base_ts, targ_ts, event_labels, spikes, base_minmax, targ_minmax)

assert_ispair( base_ts, event_labels );
assert_ispair( targ_ts, event_labels );

base_events = mkpair( base_ts, event_labels' );
targ_events = mkpair( targ_ts, event_labels' );

base_min_t = base_minmax(1);
base_max_t = base_minmax(2);
[base_psth, base_labels] = dsp3_ct.psth( spikes, base_events, base_min_t, base_max_t );

targ_min_t = targ_minmax(1);
targ_max_t = targ_minmax(2);
[targ_psth, targ_labels] = dsp3_ct.psth( spikes, targ_events, targ_min_t, targ_max_t );

s_per_bin = targ_max_t - targ_min_t;

targ_rate = targ_psth ./ (1 / s_per_bin);
base_rate = base_psth ./ (1 / s_per_bin);

base = mkpair( base_rate, base_labels );
targ = mkpair( targ_rate, targ_labels );

end