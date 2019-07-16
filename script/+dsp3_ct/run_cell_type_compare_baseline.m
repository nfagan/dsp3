conf = dsp3.config.load();
consolidated = dsp3.get_consolidated_data( conf );
sua = dsp3_ct.load_sua_data( conf );
[spike_ts, spike_labels, event_ts, event_labels, new_to_orig] = dsp3_ct.linearize_sua( sua );

spikes = mkpair( spike_ts, spike_labels' );

%%

analysis_p = char( dsp3.analysisp({'cell_type_compare_baseline', dsp3.datedir}) );
plot_p = char( dsp3.plotp({'cell_type_compare_baseline', dsp3.datedir}) );

%%

is_reward_only = false;

if ( is_reward_only )
  is_choices = [ true, false ];
  use_or_rewards = false;
else
  is_choices = [ true ];
  use_or_rewards = [ true ];
end

use_combs = dsp3.numel_combvec( is_choices, use_or_rewards );

for i = 1:size(use_combs, 2)
  
shared_utils.general.progress( i, size(use_combs, 2) );

is_choice = is_choices(use_combs(1, i));
use_or_reward = use_or_rewards(use_combs(2, i));

if ( is_reward_only )
  targ_epoch = 'rwdOn';
  targ_min_t = 0;
  targ_max_t = 0.15;
else
  targ_epoch = ternary( is_choice, 'targAcq', 'targOn' );
  targ_min_t = 0;
  targ_max_t = 0.15;
end

base_col = consolidated.event_key('fixOn');
targ_col = consolidated.event_key(targ_epoch);
rwd_col = consolidated.event_key('rwdOn');

base_ts = event_ts(:, base_col);
rwd_base_ts = event_ts(:, base_col);
targ_ts = event_ts(:, targ_col);
rwd_ts = event_ts(:, rwd_col);

is_zero = base_ts == 0 | targ_ts == 0;
is_zero_rwd = base_ts == 0 | rwd_ts == 0;

is_zero = is_zero | is_zero_rwd;
is_zero_rwd = is_zero;

base_ts(is_zero) = nan;
targ_ts(is_zero) = nan;
rwd_base_ts(is_zero_rwd) = nan;
rwd_ts(is_zero_rwd) = nan;

%

base = dsp3_ct.make_psth( base_ts, event_labels', spikes, 0, 0.15 );
targ = dsp3_ct.make_psth( targ_ts, event_labels', spikes, targ_min_t, targ_max_t );

rwd_base = dsp3_ct.make_psth( rwd_base_ts, event_labels', spikes, 0, 0.15 );
rwd = dsp3_ct.make_psth( rwd_ts, event_labels', spikes, 0, 0.15 );

%

trial_type_label = ternary( is_choice, 'choice', 'cued' );

mask_inputs = {
    @findnone, {'errors', 'post'} ...
  , @find, trial_type_label ...
};

rs_each = { 'trialtypes', 'outcomes', 'unit_uuid' };

[sr_ps, sr_labels] = ...
  dsp3_ct.ranksum_baseline_target( targ, base, rs_each, mask_inputs );

if ( use_or_reward ) 
  [rwd_sr_ps, rwd_sr_labels] = ...
    dsp3_ct.ranksum_baseline_target( rwd, rwd_base, rs_each, mask_inputs );
  assert( rwd_sr_labels == sr_labels );
  
  sr_ps = min( sr_ps, rwd_sr_ps );
end

%

plot_prefix = targ_epoch;
count_each = { 'trialtypes', 'region' };

each_I = findall( sr_labels, count_each );
[props, prop_labs, tots, tot_labels] = ...
  dsp3_ct.p_significant_per_outcome_received_forgone( sr_ps, sr_labels', each_I );

cell_type_labels = dsp3_ct.label_cell_type( sr_ps, sr_labels', each_I );
dsp3_ct.save_cell_type_labels( cell_type_labels, targ_epoch );


[counts, count_labs] = dsp3_ct.count_significant( sr_ps, sr_labels', each_I );
percs = dsp3_ct.sig_counts_to_percentages( counts, count_labs, findall(count_labs, count_each) );
[t, rc] = tabular( count_labs, 'outcomes', count_each );
percs_tbl = fcat.table( cellrefs(percs, t), rc{:} );
counts_tbl = fcat.table( cellrefs(counts, t), rc{:} );

dsp3.req_writetable( percs_tbl, analysis_p, count_labs, count_each, 'percs' );
dsp3.req_writetable( counts_tbl, analysis_p, count_labs, count_each, 'counts' );


pl = plotlabeled.make_common();
pl.group_order = { 'received', 'forgone', 'not_significant' };

count_mask = fcat.mask( count_labs ...
  , @find, {'not_significant', 'forgone', 'received'} ...
);

axs = pl.stackedbar( percs(count_mask), count_labs(count_mask), 'region', 'outcomes', {'trialtypes'} );
shared_utils.plot.fullscreen( gcf );
dsp3.req_savefig( gcf, plot_p, count_labs, [pcats, gcats], 'percent_modulated' );


pl = plotlabeled.make_common();
pl.x_order = { 'self', 'both', 'other', 'none' };

pcats = { 'region' };
gcats = { 'trialtypes' };

axs = pl.bar( props, prop_labs, 'outcomes', gcats, pcats );
% shared_utils.plot.set_ylims( axs, [0, 0.4] );

if ( use_or_reward )
  plot_prefix = sprintf( 'targ_or_reward%s', plot_prefix );
end

shared_utils.plot.fullscreen( gcf );
dsp3.req_savefig( gcf, plot_p, prop_labs, [pcats, gcats], plot_prefix );

end

%%

unit_I = findall( sr_labels, {'unit_uuid', 'trialtypes'} );
sig_labels = dsp3_ct.label_significant_combinations( sr_ps, sr_labels', unit_I, 'outcomes' ...
  , 'join_pattern', ' | ' ...
);

props_each = { 'trialtypes', 'region' };
props_of = { 'significance' };

[props, prop_labels] = proportions_of( sig_labels', props_each, props_of );
props = props * 100;

[~, sorted_I] = sortrows( prop_labels );
props = props(sorted_I);

[t, rc] = tabular( prop_labels, {'significance', 'trialtypes'}, 'region' );
tbl = fcat.table( cellrefs(props, t), rc{:} );

% dsp3.req_writetable( tbl, analysis_p, prop_labels, props_each );

%%

sig_labels = addcat( sr_labels', 'significance' );

unit_I = findall( sig_labels, {'unit_uuid', 'trialtypes', 'outcomes'} );
unit_labels = fcat();

for i = 1:numel(unit_I)
  setcat( sig_labels, 'significance', 'not-significant', unit_I{i} );
  
  for j = 1:numel(unit_I{i})
    unit_ind = unit_I{i}(j);
    
    if ( sr_ps(unit_ind) < 0.05 )
      setcat( sig_labels, 'significance', 'significant', unit_I{i} );
      break;
    end
  end
  
  append1( unit_labels, sig_labels, unit_I{i} );
end

prune( unit_labels );



%%

props_each = { 'trialtypes', 'region' };
props_of = { 'significance' };

[props, prop_labels] = proportions_of( unit_labels', props_each, props_of );

pl = plotlabeled.make_common();
xcats = { 'significance' };
gcats = { 'region' };
pcats = { 'trialtypes' };

plot_mask = fcat.mask( prop_labels ...
  , @findnone, 'not-significant' ...
);

axs = pl.bar( props(plot_mask), prop_labels(plot_mask), xcats, gcats, pcats );






