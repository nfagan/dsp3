conf = dsp3.config.load();

%%

consolidated = dsp3.get_consolidated_data( conf );

%%

sua = dsp3_ct.load_sua_data( conf );

%%

[spike_ts, spike_labels, event_ts, event_labels] = dsp3_ct.linearize_sua( sua );

%%

event_col = consolidated.event_key('targOn');

use_evt_ts = event_ts(:, event_col);
use_evt_ts(use_evt_ts == 0) = nan;

targ_acq = event_ts(:, consolidated.event_key('targAcq'));
targ_acq(targ_acq == 0) = nan;

% min_t = 0.05;
% max_t = 0.45;

min_t = 0;
max_t = targ_acq - use_evt_ts + 0.15;

spikes = mkpair( spike_ts, spike_labels );
events = mkpair( use_evt_ts, event_labels );

[psth, labels] = dsp3_ct.psth( spikes, events, min_t, max_t );
psth = mkpair( psth, labels );

%%

iters = 1e3;

each_cats = { 'trialtypes', 'unit_uuid', 'contexts' };

mask = findnone( psth.labels, {'errors', 'cued'} );
each_I = findall( psth.labels, each_cats, mask );

[lda_perf, lda_labels] = dsp3_ct.lda_cell_type_per_context( copypair(psth), each_I );
[null_perf, null_labels] = dsp3_ct.null_context_lda( copypair(psth), each_I, iters );

lda_perf = mkpair( lda_perf, lda_labels );
null_perf = mkpair( null_perf, null_labels );

%%

real_each_I = findall( lda_perf.labels, each_cats );
[ps, p_labels] = dsp3_ct.lda_p_value_from_null( lda_perf, null_perf, real_each_I );

%%

axs = dsp3_ct.plot_ps( ps, p_labels );
