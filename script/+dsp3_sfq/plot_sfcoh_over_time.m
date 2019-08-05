conf = dsp3.set_dataroot( '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/' );

[coh, coh_labs, freqs, t] = dsp3_sfq.load_per_day_sfcoh( conf );

coh_t_min = 0;
coh_t_max = 150;
coh_t_mask = mask_gele( t, coh_t_min, coh_t_max );

[coh, coh_labs] = dsp3.get_band_means( coh, coh_labs', freqs, dsp3.get_bands('map') );
coh = nanmean( coh(:, coh_t_mask), 2 );

dsp3_sfq.add_spike_lfp_region_labels( coh_labs );

%%  coh over time

over_time_each = {'days', 'blocks', 'sessions', 'trialtypes' ...
  , 'administration', 'bands', 'regions', 'channels'};

mask = find( coh_labs, {'beta', 'new_gamma'} );

[pref_dat, pref_labs, I] = dsp3.get_pref( coh_labs', over_time_each, mask );

[mean_labs, mean_I] = keepeach( coh_labs', [over_time_each, 'outcomes'] );
mean_coh = bfw.row_nanmean( coh, mean_I );

%%  coh over time

is_pro_anti = true;
reg_I = findall( mean_labs, 'regions' );

for i = 1
  pltdat = mean_coh;
  pltlabs = mean_labs';
  pltmask = fcat.mask( pltlabs, reg_I{i} ...
    , @find, {'beta', 'new_gamma'} ...
  );

  if ( is_pro_anti )
    [pltdat, pltlabs] = dsp3.pro_v_anti( pltdat, pltlabs, setdiff(over_time_each, 'outcomes'), pltmask );
  end
  
  dsp3_sfq.add_block_order( pltlabs );

  [block_I, block_C] = findall( pltlabs, 'block_order' );
  [~, sorted_ind] = sort( fcat.parse(block_C, 'block_order__') );
  block_I = block_I(sorted_ind);
  block_C = block_C(:, sorted_ind);

  pl = plotlabeled.make_common();
  pl.x_order = block_C;
  
  xcats = 'block_order';
  gcats = 'outcomes';
  pcats = { 'regions', 'bands' };

  axs = pl.errorbar( pltdat, pltlabs, xcats, gcats, pcats );
end

%%  pref over time

dsp3_sfq.add_block_order( pref_labs );

[block_I, block_C] = findall( pref_labs, 'block_order' );
[~, sorted_ind] = sort( fcat.parse(block_C, 'block_order__') );
block_I = block_I(sorted_ind);

pltdat = pref_dat;
pltlabs = pref_labs';

keep_I = findall( pref_labs, {'block_order', 'trialtypes', 'outcomes'} );
to_keep = cellfun( @(x) x(1), keep_I );
pltdat = pltdat(to_keep);
keep( pltlabs, to_keep );

pl = plotlabeled.make_common();
pl.x_order = block_C(sorted_ind);

axs = pl.errorbar( pltdat, pltlabs, 'block_order', 'outcomes', {} );
