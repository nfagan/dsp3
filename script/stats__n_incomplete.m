function stats__n_incomplete(varargin)

defaults = dsp3.get_behav_stats_defaults();
params = dsp3.parsestruct( defaults, varargin );

conf = params.config;
drug_type = params.drug_type;
bs = params.base_subdir;

if ( isempty(params.consolidated) )
  consolidated = dsp3.get_consolidated_data( conf );
else
  consolidated = params.consolidated;
end

path_components = { 'behavior', dsp3.datedir, bs, drug_type, 'p_incompleted_trials' };

params.plot_p = char( dsp3.plotp(path_components, conf) );

%%

labs = fcat.from( consolidated.trial_data.labels );

%%

subsetlabs = dsp3.get_subset( labs', drug_type );
keep( subsetlabs, findnone(subsetlabs, params.remove) );

prune( subsetlabs );

%%

error_inds = find( subsetlabs, 'errors' );

addsetcat( subsetlabs, 'completed_trial', 'complete' );
setcat( subsetlabs, 'completed_trial', 'incomplete', error_inds );

prune( subsetlabs );

%%

proportion_spec = { 'days', 'contexts', 'administration' };
props_of = 'completed_trial';

[n_complete_props, proportion_labels, prop_I] = ...
  proportions_of( subsetlabs, proportion_spec, props_of );

%%

plot_choice( n_complete_props, proportion_labels' );

% plot_cue_and_choice_together( n_complete_props, proportion_labels', params );

end

function plot_choice(n_complete_props, proportion_labels)
%%

xcats = { 'contexts' };
gcats = { 'completed_trial' };
pcats = { 'trialtypes' };

mask = fcat.mask( proportion_labels ...
  , @find, 'complete' ...
  , @findnot, 'errors' ...
  , @find, 'choice' ...
);

pl = plotlabeled.make_common();

axs = pl.bar( n_complete_props(mask), proportion_labels(mask) ...
  , xcats, gcats, pcats );

end

function plot_cue_and_choice_together(n_complete, proportion_labels, params)

%%

pltlabels = proportion_labels';

cue_outs = { 'self', 'both', 'other', 'none' };
ctx_outs = cellfun( @(x) ['context__', x], cue_outs, 'un', 0 );
replace_outs = cellfun( @(x) [x, '-cue'], cue_outs, 'un', 0 );

cellfun( @(x, y) replace(pltlabels, x, y), ctx_outs, replace_outs, 'un', 0 );
replace( pltlabels, 'othernone', 'other/bottle' );
replace( pltlabels, 'selfboth', 'self/both' );
replace( pltlabels, 'none-cue', 'bottle-cue' );

mask = fcat.mask( pltlabels ...
  , @find, 'incomplete' ...
);

pl = plotlabeled.make_common();
pl.y_lims = [ 0, 1 ];
pl.x_tick_rotation = 0;
pl.x_order = { 'other/bottle', 'self/both', 'self-cue', 'other-cue', 'both-cue' };

fcats = {};
xcats = { 'contexts' };
gcats = { 'completed_trial' };
pcats = {};

f_I = findall_or_one( pltlabels, fcats, mask );

figs = gobjects( numel(f_I), 1 );
axs = gobjects;
for i = 1:numel(f_I)
  figs(i) = figure(i);
  clf( figs(i) );
  pl.fig = figs(i);
  
  ax = pl.bar( n_complete_props(f_I{i}), pltlabels(f_I{i}), xcats, gcats, pcats );
  axs = [ axs, ax(:)' ];
  
  shared_utils.plot.ylabel( ax, '% Incompleted trials' );
end

if ( params.do_save )
  pltcats = unique( cshorzcat(fcats, xcats, gcats, pcats) );
  
  for i = 1:numel(f_I)
    dsp3.req_savefig( figs(i), params.plot_p, prune(pltlabels(f_I{i})), pltcats );
  end
end

end