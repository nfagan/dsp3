function run_self_vs_other(spikes, events, event_key, varargin)

defaults = dsp3.get_common_plot_defaults( dsp3.get_common_make_defaults() );
defaults.alpha = 0.05;
defaults.target_time_window = [0, 0.15];
defaults.reward_time_window = [0.05, 0.45];
defaults.or_reward = true;

params = dsp3.parsestruct( defaults, varargin );

[targ, rwd, labels] = make_psths( spikes, events, event_key, params );
stat_mask = get_stat_mask( labels );

%%%

targ_rs_outs = get_stats( targ, labels', stat_mask );
rwd_rs_outs = get_stats( rwd, labels', stat_mask );

is_significant = is_significant_cell( targ_rs_outs, rwd_rs_outs, params );
[counts_tbl, percs_tbl] = make_significant_descriptive_tables( targ_rs_outs, is_significant );

%%%

stat_labels = targ_rs_outs.rs_labels';

cc_cell_type_labels = make_cc_cell_type_labels( stat_labels, is_significant );
dsp3_ct.save_self_vs_other_selective_labels( 'targAcq_or_reward.mat', cc_cell_type_labels, params.config );

end

function stat_outs = get_stats(data, labels, mask)

stat_outs = dsp3.ranksum( data, labels, 'unit_uuid', 'self', 'other' ...
  , 'mask', mask ...
);

end

function mask = get_stat_mask(labels)

[~, subset_ind] = dsp3.get_subset( labels', 'nondrug_wbd' );

mask = fcat.mask( labels, subset_ind ...
  , @find, 'choice' ...
);

end

function [counts_tbl, percs_tbl] = make_significant_descriptive_tables(rs_outs, is_significant)

[t, rc] = tabular( rs_outs.rs_labels, 'trialtypes', 'region' );

sig_counts = cellfun( @(x) nnz(is_significant(x)), t );
sig_props = cellfun( @(x) pnz(is_significant(x)), t );

counts_tbl = fcat.table( sig_counts, rc{:} );
percs_tbl = fcat.table( sig_props, rc{:} );

end

function tf = is_significant_cell(targ_rs_outs, rwd_rs_outs, params)

sig_targ = cellfun( @(x) x.p < params.alpha, targ_rs_outs.rs_tables );
sig_rwd = cellfun( @(x) x.p < params.alpha, rwd_rs_outs.rs_tables );

if ( params.or_reward )
  tf = sig_targ | sig_rwd;
else
  tf = sig_targ;
end

end

function [targ, rwd, labels] = make_psths(spikes, events, event_key, params)

event_ts = events.data;
event_labels = events.labels;

targ_epoch = 'targAcq';
targ_min_t = params.target_time_window(1);
targ_max_t = params.target_time_window(2);

rwd_epoch = 'rwdOn';
rwd_min_t = params.reward_time_window(1);
rwd_max_t = params.reward_time_window(2);

targ_ts = event_ts(:, event_key(targ_epoch));
rwd_ts = event_ts(:, event_key(rwd_epoch));

targ = dsp3_ct.make_psth( targ_ts, event_labels', spikes, targ_min_t, targ_max_t );
rwd = dsp3_ct.make_psth( rwd_ts, event_labels', spikes, rwd_min_t, rwd_max_t );

labels = targ.labels';
targ = targ.data;
rwd = rwd.data;

end

function out = make_cc_cell_type_labels(labels, is_signifcant)

assert( all(unique(cellfun(@numel, findall(labels, 'unit_uuid'))) == 1) ...
  , 'Expected 1 row for each cell.' );

data_indices = fcat.parse( cellstr(labels, 'cc_data_index'), 'cc_data_index__' );
unit_indices = fcat.parse( cellstr(labels, 'cc_unit_index'), 'cc_unit_index__' );

assert( ~any(isnan(data_indices)) && ~any(isnan(unit_indices)) ...
  , 'Failed to parse data / unit indices.' );

new_to_original = [ data_indices(:), unit_indices(:) ];
ct_cell_types = arrayfun( @(x) ternary(x, 'self_vs_other_selective', 'non_self_vs_other_selective') ...
  , is_signifcant, 'un', 0 );

out = struct();
out.labels = gather( labels );
out.cell_types = ct_cell_types;
out.new_to_original = new_to_original;

end