function targ = make_psth(targ_ts, event_labels, spikes, targ_min_t, targ_max_t, make_rate)

if ( nargin < 6 )
  make_rate = true;
end

assert_ispair( targ_ts, event_labels );
targ_events = mkpair( targ_ts, event_labels' );

[targ_psth, targ_labels] = dsp3_ct.psth( spikes, targ_events, targ_min_t, targ_max_t );

s_per_bin = targ_max_t - targ_min_t;

if ( make_rate )
  targ_rate = targ_psth ./ (1 / s_per_bin);
else
  targ_rate = targ_psth;
end

targ = mkpair( targ_rate, targ_labels );

end