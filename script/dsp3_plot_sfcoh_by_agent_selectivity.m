conf = dsp3.config.load();
conf.PATHS.data_root = '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/';

[coh, coh_labs, freqs, t] = dsp3_sfq.load_per_day_sfcoh( conf );

agent_labs = load( '/mnt/dunham/media/chang/T1/data/dsp3/analyses/cell_type_agent_specificity/080219/cc_cell_type_targAcq_or_reward.mat' );
agent_labs = agent_labs.cc_cell_type_labels;
agent_labels = fcat.from( agent_labs.labels );

%%

site_spec = dsp3_ct.site_specificity();
[site_labs, site_I] = keepeach( coh_labs', site_spec );
site_coh = bfw.row_nanmean( coh, site_I );
[site_coh, site_labs] = dsp3_ct.remove_missing_sites( site_coh, site_labs' );

[unit_I, unit_C] = findall( site_labs, 'unit_uuid' );
addcat( site_labs, 'agent_selectivity' );
for i = 1:numel(unit_I)
  id = find( agent_labels, unit_C{1, i} );
  assert( numel(id) == 1 );
  selective_label = agent_labs.cell_types{id};
  setcat( site_labs, 'agent_selectivity', selective_label, unit_I{i} );
end

[site_coh, site_labs] = dsp3.pro_v_anti( site_coh, site_labs, setdiff(site_spec, 'outcomes') );
[site_coh, site_labs] = dsp3.pro_minus_anti( site_coh, site_labs, setdiff(site_spec, 'outcomes') );

%%

f_ind = freqs >= 10 & freqs <= 80;
t_ind = t >= -300 & t <= 300;

plt_freqs = freqs(f_ind);
plt_t = t(t_ind);

plt_mask = fcat.mask( site_labs ...
  , @find, 'selected-site' ...
  , @find, 'agent-selective' ...
);

fcats = {};

fig_I = findall_or_one( site_labs, fcats, plt_mask );

for idx = 1:numel(fig_I)

  plt_dat = site_coh(fig_I{idx}, f_ind, t_ind);
  plt_labs = prune( site_labs(fig_I{idx}) );

  pcats = { 'outcomes', 'regions', 'agent_selectivity' };

  pl = plotlabeled.make_spectrogram( plt_freqs, plt_t );
  pl.sort_combinations = true;
  pl.c_lims = [ -0.016, 0.016 ];
  
  axs = pl.imagesc( plt_dat, plt_labs, pcats );
  shared_utils.plot.fseries_yticks( axs, round(flip(plt_freqs)), 5 )
  shared_utils.plot.tseries_xticks( axs, plt_t, 5 );
end