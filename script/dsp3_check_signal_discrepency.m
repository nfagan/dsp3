function [diffs, day_info_labels] = dsp3_check_signal_discrepency()

event_name = 'targAcq';

conf = dsp2.config.load();

conf = dsp2.config.set.inactivate_epochs( 'all', conf );
conf = dsp2.config.set.activate_epochs( event_name, conf );

consolidated = dsp3.get_consolidated_data();
pl2_info = consolidated.pl2_info;
unique_days = unique( pl2_info.days );

aligned_p = 'H:\data\cc_dictator\mua';

diffs = nan( numel(unique_days), 5 );
day_info_labels = fcat();

%%
for i = 1:numel(unique_days)
shared_utils.general.progress( i, numel(unique_days) );

day = unique_days{i};
is_session = strcmp( pl2_info.days, day );
sessions = pl2_info.sessions(is_session);

%%

test_signals = dsp2.io.get_signals( 'config', conf, 'sessions', sessions );
test_signals = test_signals.(event_name);

%%

test_day = char( test_signals('days') );
test_filename = sprintf( 'lfp_%s_%s.mat', test_day, event_name );

orig_signals = shared_utils.io.fload( fullfile(aligned_p, test_filename) );
orig_dat = orig_signals.data;
orig_labels = fcat.from( orig_signals.labels );

%%

defaults = dsp3.get_common_lfp_defaults();

modified_signals = test_signals;
modified_dat = modified_signals.data;
modified_labels = fcat.from( modified_signals.labels );

modified_labels = dsp3_match_cc_targacq_trial_labels( orig_labels, modified_labels );

[modified_dat, modified_labels] = dsp3.ref_subtract( modified_dat, modified_labels );
filtered_dat = dsp3.zpfilter( modified_dat, defaults.f1, defaults.f2, 1e3, defaults.filter_order );

%%

% assert( modified_labels == orig_labels );

max_diff_filtered = max(max(abs(orig_dat - filtered_dat)));
max_diff_reffed = max(max(abs(orig_dat - modified_dat)));

mean_orig = nanmean( nanmean(orig_dat) );
mean_filt = nanmean( nanmean(filtered_dat) );

diff_means = mean_orig - mean_filt;

append1( day_info_labels, modified_labels );
diffs(i, :) = [ max_diff_filtered, max_diff_reffed, mean_orig, mean_filt, diff_means ];

end

end