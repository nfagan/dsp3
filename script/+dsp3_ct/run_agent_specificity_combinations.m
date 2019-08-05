function run_agent_specificity_combinations(consolidated, spikes, new_to_orig, event_ts, event_labels, conf)

analysis_p = get_analysis_p( conf );
plot_p = get_plot_p( conf );

% use_norms = [ true, false ];
% remove_zeros = [ true, false ];
% use_or_rewards = [ true, false ];
% target_epochs = { 'targAcq', 'rwdOn' };

use_norms = [ false ];
remove_zeros = [ false ];
use_or_rewards = [ true ];
target_epochs = { 'targAcq', 'rwdOn' };

cmbtns = dsp3.numel_combvec( use_norms, remove_zeros, use_or_rewards, target_epochs );

for idx = 1:size(cmbtns, 2)
  
shared_utils.general.progress( idx, size(cmbtns, 2) );
  
c = cmbtns(:, idx);

use_norm = use_norms(c(1));
remove_all_zero = remove_zeros(c(2));
use_or_reward = use_or_rewards(c(3));
targ_epoch = target_epochs{c(4)};

if ( use_or_reward && strcmp(targ_epoch, 'rwdOn') )
  continue;
end

base_epoch = 'cueOn';
base_min_t = -0.15;
base_max_t = 0;

targ_min_t = 0;
targ_max_t = 0.15;

rwd_epoch = 'rwdOn';
rwd_min_t = 0.05;
rwd_max_t = 0.45;

targ_ts = event_ts(:, consolidated.event_key(targ_epoch));
base_ts = event_ts(:, consolidated.event_key(base_epoch));
rwd_ts = event_ts(:, consolidated.event_key(rwd_epoch));

targ = dsp3_ct.make_psth( targ_ts, event_labels', spikes, targ_min_t, targ_max_t );
base = dsp3_ct.make_psth( base_ts, event_labels', spikes, base_min_t, base_max_t );

if ( use_or_reward )
  rwd = dsp3_ct.make_psth( rwd_ts, event_labels', spikes, rwd_min_t, rwd_max_t );
end

%

use_data = dsp3_ct.conditional_normalize( use_norm, targ.data, base.data );
use_labels = targ.labels';

if ( use_or_reward )
  rwd_labels = rwd.labels';
  rwd_data = dsp3_ct.conditional_normalize( use_norm, rwd.data, base.data );
end

if ( remove_all_zero )
  [~, all_zero] = dsp3_ct.remove_all_zero( use_data );
  
  if ( use_or_reward )
    [~, rwd_all_zero] = dsp3_ct.remove_all_zero( rwd_data );
    all_zero = all_zero | rwd_all_zero;
  end
  
  use_data = use_data(~all_zero, :);
  
  if ( use_or_reward )
    rwd_data = rwd_data(~all_zero, :);
    keep( rwd_labels, find(~all_zero) );
  end
  
  keep( use_labels, find(~all_zero) );
end

anova_outs = dsp3_ct.agent_specificity_anova( use_data, use_labels' );

if ( use_or_reward )
  rwd_anova_outs = dsp3_ct.agent_specificity_anova( rwd_data, rwd_labels' );
end

%

is_sig_anova = cellfun( @(x) x.Prob_F{1} < 0.05, anova_outs.anova_tables );

if ( use_or_reward )
  rwd_is_sig_anova = cellfun( @(x) x.Prob_F{1} < 0.05, rwd_anova_outs.anova_tables );
  is_sig_anova = is_sig_anova | rwd_is_sig_anova;
end

[t, rc] = tabular( anova_outs.anova_labels, 'trialtypes', 'region' );

sig_counts = cellfun( @(x) nnz(is_sig_anova(x)), t );
sig_props = cellfun( @(x) pnz(is_sig_anova(x)), t );

counts_tbl = fcat.table( sig_counts, rc{:} );
percs_tbl = fcat.table( sig_props, rc{:} );

tbl_labels = anova_outs.anova_labels';
tbl_spec = { 'trialtypes', 'outcomes' };

tbl_prefix = targ_epoch;

if ( use_or_reward ), tbl_prefix = sprintf( '%s_%s', tbl_prefix, 'or_reward' ); end
if ( remove_all_zero ), tbl_prefix = sprintf( '%s_zeros_removed', tbl_prefix ); end
if ( use_norm ), tbl_prefix = sprintf( '%s_normalized', tbl_prefix ); end

dsp3.req_writetable( counts_tbl, analysis_p, tbl_labels, tbl_spec, tbl_prefix );

%% Pie chart

plot_pie( is_sig_anova, anova_outs.anova_labels', fullfile(plot_p, 'pie'), tbl_prefix );

%%

cell_type_labels = make_cell_type_labels( is_sig_anova, anova_outs.anova_labels' );
save( fullfile(analysis_p, sprintf('cell_type_%s', tbl_prefix)), 'cell_type_labels' );

cc_cell_type_labels = make_cc_cell_type_labels( cell_type_labels, spikes.labels', new_to_orig );
save( fullfile(analysis_p, sprintf('cc_cell_type_%s', tbl_prefix)), 'cc_cell_type_labels' );

%%

comp_labs = fcat();

for i = 1:numel(anova_outs.comparison_tables)
  ps = anova_outs.comparison_tables{i}.p_value;
  comparisons = anova_outs.comparison_tables{i}.comparison;
  
  [ps, comparisons] = prune_models( ps, comparisons, anova_outs.anova_tables{i}.Prob_F{1} );
  
  if ( use_or_reward )
    rwd_ps = rwd_anova_outs.comparison_tables{i}.p_value;
    rwd_comparisons = rwd_anova_outs.comparison_tables{i}.comparison;
    
    [rwd_ps, rwd_comparisons] = prune_models( rwd_ps, rwd_comparisons, rwd_anova_outs.anova_tables{i}.Prob_F{1} );
    
    [ps, comparisons] = join_reward_targ_comparisons( ps, comparisons, rwd_ps, rwd_comparisons );
  end
  
  if ( isempty(ps) && ~is_sig_anova(i) )
    append1( comp_labs, anova_outs.anova_labels, i );
    setcat( comp_labs, 'outcomes', 'none-significant', rows(comp_labs) );
  else
    for j = 1:numel(ps)
      append1( comp_labs, anova_outs.anova_labels, i );
      setcat( comp_labs, 'outcomes', comparisons{j}, rows(comp_labs) );
    end
  end
end

prune( comp_labs );

[t, rc] = tabular( comp_labs, 'outcomes', 'region' );
comp_counts_tbl = fcat.table( cellfun(@numel, t), rc{:} );
counts_tbl_prefix = sprintf( 'comparisons_%s', tbl_prefix );

[~, sorted_I] = sort( comp_counts_tbl.Properties.RowNames );
comp_counts_tbl = comp_counts_tbl(sorted_I, :);

dsp3.req_writetable( comp_counts_tbl, analysis_p, comp_labs ...
  , {'region'}, counts_tbl_prefix );

%%

plot_bar_post_hoc_comparisons( is_sig_anova, anova_outs.anova_labels, comp_labs, cell_type_labels ...
  , fullfile(plot_p, 'bar_comparisons'), counts_tbl_prefix );

end

end

function plot_bar_post_hoc_comparisons(is_sig_anova, anova_labels, labs, cell_type_labels, save_p, prefix)

%%
mask = findnone( labs, 'none-significant' );

[pltlabs, I, C] = keepeach( labs', {'outcomes', 'region'}, mask );
props = zeros( numel(I), 1 );

for i = 1:numel(I)
  reg = C{2, i};
  num_this_reg = sum( is_sig_anova(find(anova_labels, reg)) );
  
%   num_this_reg = numel( find(cell_type_labels, reg) );
  props(i) = numel( I{i} ) / num_this_reg * 100;
end

pl = plotlabeled.make_common();
pcats = { 'region' };

axs = pl.bar( props, pltlabs, 'outcomes', {}, pcats );

shared_utils.plot.fullscreen( gcf );
dsp3.req_savefig( gcf, save_p, pltlabs, pcats, prefix );

end

function axs = plot_pie(is_sig, labs, save_p, prefix)

%%

pl = plotlabeled.make_common();
pl.pie_include_percentages = true;

pcats = 'region';
gcats = 'agent_selectivity';

[tmp_labs, I] = keepeach( labs', {'trialtypes', 'region'} );
addcat( tmp_labs, 'agent_selectivity' );

prop_dat = zeros( numel(I)*2, 1 );
prop_labs = fcat();

stp = 1;

for i = 1:numel(I)
  p_sig = pnz( is_sig(I{i}) );
  p_non_sig = 1 - p_sig;
  
  append1( prop_labs, tmp_labs, i );
  setcat( prop_labs, 'agent_selectivity', 'agent-selective', rows(prop_labs) );
  append1( prop_labs, tmp_labs, i );
  setcat( prop_labs, 'agent_selectivity', 'non-agent-selective', rows(prop_labs) );
  
  prop_dat(stp) = p_sig;
  prop_dat(stp+1) = p_non_sig;
  stp = stp + 2;
end

axs = pl.pie( prop_dat*100, prop_labs, gcats, pcats );
dsp3.req_savefig( gcf, save_p, prop_labs, pcats, prefix );

end

function [ps, comps] = prune_models(ps, comps, anova_p)

if ( anova_p >= 0.05 )
  ps = ps(false, :);
  comps = comps(false, :);
end

end

function out = make_cc_cell_type_labels(ct_labels, spike_labels, new_to_orig)

%%
assert_ispair( new_to_orig, spike_labels );

ct_unit_ids = ct_labels(:, 'unit_uuid');
ct_cell_types = ct_labels(:, 'outcomes');

new_to_original = zeros( numel(ct_unit_ids), 2 );

for i = 1:numel(ct_unit_ids)
  spk_ind = find( spike_labels, ct_unit_ids{i} );
  assert( numel(spk_ind) == 1 );
  new_to_original(i, :) = new_to_orig(spk_ind, :);
end

remaining_ids = setdiff( spike_labels('unit_uuid'), ct_unit_ids );

for i = 1:numel(remaining_ids)
  spk_ind = find( spike_labels, remaining_ids{i} );
  ct_cell_types{end+1} = 'non-agent-selective';
  new_to_original(end+1, :) = new_to_orig(spk_ind, :);
end

out = struct();
out.labels = gather( ct_labels );
out.cell_types = ct_cell_types;
out.new_to_original = new_to_original;

end

function labs = make_cell_type_labels(is_sig, labs)

setcat( labs, 'outcomes', 'agent-selective', find(is_sig) );
setcat( labs, 'outcomes', 'non-agent-selective', find(~is_sig) );

end

function [ps, comps] = join_reward_targ_comparisons(ps, comps, rwd_ps, rwd_comps)

if ( isempty(ps) )
  ps = rwd_ps;
  comps = rwd_comps;
  return;
elseif ( isempty(rwd_ps) )
  return;
end

all_comps = unique( [comps; rwd_comps] );
use_ps = zeros( numel(all_comps), 1 );

for i = 1:numel(all_comps)
  is_targ = strcmp( comps, all_comps{i} );
  is_rwd = strcmp( rwd_comps, all_comps{i} );
  
  any_targ = any( is_targ );
  any_rwd = any( is_rwd );
  
  if ( any_targ && any_rwd )
    use_ps(i) = min( ps(is_targ), rwd_ps(is_rwd) );
  elseif ( any_targ )
    use_ps(i) = ps(is_targ);
  else
    use_ps(i) = rwd_ps(is_rwd);
  end
end

end

function components = path_components()

components = { 'cell_type_agent_specificity', dsp3.datedir };

end

function p = get_plot_p(conf)

p = char( dsp3.plotp(path_components(), conf) );

end

function p = get_analysis_p(conf)

p = char( dsp3.analysisp(path_components(), conf) );

end

