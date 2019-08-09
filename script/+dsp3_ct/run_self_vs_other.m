function run_self_vs_other(spikes, events, event_key, varargin)

defaults = dsp3.get_common_plot_defaults( dsp3.get_common_make_defaults() );
defaults.alpha = 0.05;
defaults.target_time_window = [0, 0.15];
defaults.reward_time_window = [0.05, 0.45];
defaults.cued_time_window = [0, 0.15];
defaults.or_reward = true;
defaults.use_rate = true;
defaults.include_cued = false;
defaults.include_cued_in_reward = false;
defaults.prefix = '';

params = dsp3.parsestruct( defaults, varargin );

[targ, cued, rwd, labels] = make_psths( spikes, events, event_key, params );
stat_mask = get_stat_mask( labels, params );

%%%

targ_rs_outs = get_stats( targ, labels', stat_mask );
rwd_rs_outs = get_stats( rwd, labels', stat_mask );
cued_rs_outs = get_stats( cued, labels', stat_mask );

is_significant = is_significant_cell( targ_rs_outs, cued_rs_outs, rwd_rs_outs, params );
[counts_tbl, percs_tbl] = make_significant_descriptive_tables( targ_rs_outs, is_significant );

% check( targ_rs_outs.rs_labels', is_significant );

%%%

stat_labels = targ_rs_outs.rs_labels';

plot_pie( is_significant, stat_labels', params );

cc_cell_type_labels = make_cc_cell_type_labels( stat_labels, is_significant );
dsp3_ct.save_self_vs_other_selective_labels( 'targAcq_or_reward.mat', cc_cell_type_labels, params.config );

end

function stat_outs = get_stats(data, labels, mask)

stat_outs = dsp3.anova1( data, labels, 'unit_uuid', 'outcomes' ...
  , 'mask', mask ...
);

stat_outs.rs_labels = stat_outs.anova_labels;
stat_outs.rs_tables = cellfun( @(x) table(x.Prob_F{1}, 'variablenames', {'p'}), stat_outs.anova_tables, 'un', 0 );

% [stat_outs, stat_I] = dsp3.ranksum( data, labels, 'unit_uuid', {'self', 'none'}, {'other', 'both'} ...
%   , 'mask', mask ...
% );

end

function mask = get_stat_mask(labels, params)

% [~, subset_ind] = dsp3.get_subset( labels', 'nondrug_wbd' );
% 
% mask = fcat.mask( labels, subset_ind ...
%   , @find, 'choice' ...
% );

if ( params.include_cued_in_reward || params.include_cued )
  choice_options = { 'choice', 'cued' };
else
  choice_options = { 'choice' };
end

mask = fcat.mask( labels ...
  , @find, {'pre'} ...
  , @find, choice_options ...
);

end

function [counts_tbl, percs_tbl] = make_significant_descriptive_tables(rs_outs, is_significant)

[t, rc] = tabular( rs_outs.rs_labels, 'trialtypes', 'region' );

sig_counts = cellfun( @(x) nnz(is_significant(x)), t );
sig_props = cellfun( @(x) pnz(is_significant(x)), t );

counts_tbl = fcat.table( sig_counts, rc{:} );
percs_tbl = fcat.table( sig_props, rc{:} );

end

function tf = is_significant_cell(targ_rs_outs, cued_rs_outs, rwd_rs_outs, params)

sig_targ = cellfun( @(x) x.p < params.alpha, targ_rs_outs.rs_tables );
sig_rwd = cellfun( @(x) x.p < params.alpha, rwd_rs_outs.rs_tables );
sig_cued = cellfun( @(x) x.p < params.alpha, cued_rs_outs.rs_tables );

if ( params.include_cued )
  sig_targ = sig_targ | sig_cued;
end

if ( params.or_reward )
  tf = sig_targ | sig_rwd;
else
  tf = sig_targ;
end

end

function [targ, cued, rwd, labels] = make_psths(spikes, events, event_key, params)

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

targ = dsp3_ct.make_psth( targ_ts, event_labels', spikes, targ_min_t, targ_max_t, params.use_rate );
rwd = dsp3_ct.make_psth( rwd_ts, event_labels', spikes, rwd_min_t, rwd_max_t, params.use_rate );

cued_ts = event_ts(:, event_key('targOn'));
cued_min_t = params.cued_time_window(1);
cued_max_t = params.cued_time_window(2);
cued = dsp3_ct.make_psth( cued_ts, event_labels', spikes, cued_min_t, cued_max_t, params.use_rate );

labels = targ.labels';
targ = targ.data;
cued = cued.data;
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

function axs = plot_pie(is_sig, labs, params)

%%

pl = plotlabeled.make_common();
pl.pie_include_percentages = true;

selective_cat = 'outcome_selectivity';
selective_kind = 'outcome';
selective_label = sprintf( '%s-selective', selective_kind );
nonselective_label = sprintf( 'non-%s', selective_label );

pcats = 'region';
gcats = selective_cat;

[tmp_labs, I] = keepeach( labs', {'trialtypes', 'region'} );
addcat( tmp_labs, selective_cat );

prop_dat = zeros( numel(I)*2, 1 );
prop_labs = fcat();

stp = 1;

for i = 1:numel(I)
  p_sig = pnz( is_sig(I{i}) );
  p_non_sig = 1 - p_sig;
  
  append1( prop_labs, tmp_labs, i );
  setcat( prop_labs, selective_cat, selective_label, rows(prop_labs) );
  append1( prop_labs, tmp_labs, i );
  setcat( prop_labs, selective_cat, nonselective_label, rows(prop_labs) );
  
  prop_dat(stp) = p_sig;
  prop_dat(stp+1) = p_non_sig;
  stp = stp + 2;
end

axs = pl.pie( prop_dat*100, prop_labs, gcats, pcats );

if ( params.do_save )
  conf = params.config;
  save_p = fullfile( dsp3.dataroot(conf), 'plots', 'cell_type_self_vs_other' ...
    , dsp3.datedir, params.base_subdir, 'pie' );
  dsp3.req_savefig( gcf, save_p, prop_labs, pcats, params.prefix );
end

end

function check_psth(data, labels, mask)

%%

% base_mask = fcat.mask( labels, mask ...
%   , @find, {'cc_data_index__32', 'cc_unit_index__4'} ...
%   , @find, 'other' ...
%   , @find, 'choice' ...
% );
% 
% numel( base_mask );


%%

cc_labels = combs( labels, {'cc_data_index', 'cc_unit_index'} );

x = load( '/Users/Nick/Downloads/spk_dt.mat' );

outcomes = { 'self', 'both', 'other', 'none' };
num_diffs = [];

for i = 1:numel(x.spk_Choice)
  cc_data_index = cc_labels{1, i};
  cc_unit_index = cc_labels{2, i};
  
  for j = 1:numel(outcomes)
    cc_spike_counts = x.spk_Choice{i}{j};
    
    match_ind = find( labels, [cc_labels(:, i)', outcomes{j}], mask );
    
    assert( numel(match_ind) == numel(cc_spike_counts) );
    cc_mean_count = mean( cc_spike_counts );
    my_mean_count = mean( data(match_ind) );
    
    num_diff = sum( cc_spike_counts(:) ~= data(match_ind) );
    
    num_diffs(end+1, 1) = num_diff;
  end
end

end



function check(unit_labels, is_sig)

%%

x = load( '/Users/Nick/Downloads/unit_labels.mat' );
cc_so_index = shared_utils.io.fload( '/Users/Nick/Downloads/so_index.mat' );

x = x.name;
days = cellfun( @(x) x{1}, x, 'un', 0 );
cc_data_indices = cellfun( @(x) sprintf('cc_data_index__%d', x{2}), x, 'un', 0 );
cc_unit_indices = cellfun( @(x) sprintf('cc_unit_index__%d', x{3}), x, 'un', 0 );
cc_unit_labs = fcat.create( 'days', days, 'cc_unit_index', cc_unit_indices, 'cc_data_index', cc_data_indices );

my_cats = {'cc_data_index', 'cc_unit_index', 'days'};
my_labs = cellstr( unit_labels, my_cats );
my_unit_labs = fcat.from( my_labs, my_cats );

assert( prune(my_unit_labs) == prune(cc_unit_labs) );

find( cc_so_index(:) ~= is_sig(:), 1 );

both = [ cc_so_index(:), is_sig(:) ];

end
