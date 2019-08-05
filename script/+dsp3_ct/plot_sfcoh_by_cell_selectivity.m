conf = dsp3.set_dataroot( '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/' );
[coh, coh_labs, freqs, t] = dsp3_sfq.load_per_day_sfcoh( conf );

%%
agent_type_labels = dsp3_ct.load_agent_specificity_cell_type_labels( '080219', 'cell_type_targAcq_or_reward.mat' );
outcome_type_labels = dsp3_ct.load_cell_type_labels( 'targAcq.mat' );

dsp3_ct.add_outcome_selectivity_labels_to_sfcoh( outcome_type_labels, coh_labs );
dsp3_ct.add_agent_selectivity_labels_to_sfcoh( agent_type_labels, coh_labs );

%%

selectivity_type = 'outcomes';

switch ( selectivity_type )
  case 'outcome_selectivity'
    base_p = 'cell_type_compare_baseline';
    
  case 'agent_selectivity'
    base_p = 'cell_type_agent_specificity';
    
  case 'outcomes'
    base_p = 'spectra';
    
  otherwise
    error( 'Unrecognized selectivity "%s".', selectivity_type );
end

pro_v_anti = true;
pro_minus_anti = true;

do_save = true;
plot_p = char( dsp3.plotp({base_p, dsp3.datedir, 'spectra'}) );

f_ind = freqs >= 10 & freqs <= 80;
t_ind = t >= -300 & t <= 300;

plt_f = freqs(f_ind);
plt_t = t(t_ind);

site_mask = fcat.mask( coh_labs ...
  , @find, {'choice', 'selected-site'} ...
  , @findnone, 'errors' ...
);

sites_each = { 'outcomes', 'trialtypes', 'regions', 'channels', 'days', 'unit_uuid', selectivity_type };
proanti_each = setdiff( sites_each, 'outcomes' );

[site_labs, site_I] = keepeach( coh_labs', sites_each, site_mask );
site_coh = bfw.row_nanmean( coh, site_I );

% Only keep pairs with complete 4 outcomes.
any_nans = any( any(isnan(site_coh), 2), 3 );

site_coh = site_coh(~any_nans, f_ind, t_ind);
site_labs = prune( site_labs(find(~any_nans)) );

[to_keep, num_missing] = dsp3_ct.find_sites_with_all_outcomes( site_labs, proanti_each );

site_coh = site_coh(to_keep, :, :);
site_labs = prune( site_labs(to_keep) );

if ( pro_v_anti )
  [site_coh, site_labs] = dsp3.pro_v_anti( site_coh, site_labs', proanti_each );
end

if ( pro_minus_anti )
  [site_coh, site_labs] = dsp3.pro_minus_anti( site_coh, site_labs', proanti_each );
end

pl = plotlabeled.make_spectrogram( plt_f, plt_t );

fig_I = findall_or_one( site_labs, {selectivity_type, 'trialtypes'} );

store_labs = cell( size(fig_I) );
store_axs = cell( size(fig_I) );
figs = gobjects( size(fig_I) );

pcats = { 'outcomes', 'regions', selectivity_type, 'trialtypes' };

formats = { 'epsc', 'png', 'fig', 'svg' };

for i = 1:numel(fig_I)
  fig = figure(i);
  pl.fig = fig;
  
  plt_coh = site_coh(fig_I{i}, :, :);
  plt_labs = prune( site_labs(fig_I{i}) );

  axs = pl.imagesc( plt_coh, plt_labs, pcats );
  shared_utils.plot.hold( axs, 'on' );
  
  shared_utils.plot.tseries_xticks( axs, plt_t );
  shared_utils.plot.fseries_yticks( axs, round(flip(plt_f)), 5 );
  shared_utils.plot.add_vertical_lines( axs, find(plt_t == 0) );
  
  shared_utils.plot.set_clims( axs, [-15e-3, 15e-3] );
  
  store_axs{i} = axs(:);
  store_labs{i} = plt_labs;
  figs(i) = fig;
end

axs = vertcat( store_axs{:} );
shared_utils.plot.match_clims( axs );

if ( do_save )
  for i = 1:numel(fig_I)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), plot_p, store_labs{i}, pcats, '', formats ); 
  end
end