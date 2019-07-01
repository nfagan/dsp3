sta_lfp_file = load( fullfile(dsp3.dataroot, 'analyses', 'sta_lfp', 'sta_lfp.mat') );

%%

sta_lfp = sta_lfp_file.sta_lfp;
sta_labs = fcat.from( sta_lfp_file.save_labs );

%%

filtered_lfp = dsp3.zpfilter( sta_lfp, 3, 90, 1e3, 3 );

%%

base_subdir = '3_90_collapsed';

plot_p = fullfile( dsp3.dataroot, 'plots', 'sta', 'traces', dsp3.datedir, base_subdir );

pl = plotlabeled.make_common();
pl.x = -500:500;
pl.panel_order = { 'self', 'both', 'other' };
pl.add_errors = false;

fcats = {};
gcats = { 'region', 'trialtypes' };
pcats = { 'outcomes' };

pcats = csunion( pcats, fcats );

fig_I = findall_or_one( sta_labs, fcats );

for i = 1:numel(fig_I)
  pltdat = filtered_lfp(fig_I{i}, :);
  pltlabs = prune( sta_labs(fig_I{i}) );

  axs = pl.lines( pltdat, pltlabs, gcats, pcats );
  
  shared_utils.plot.hold( axs, 'on' );
  shared_utils.plot.add_vertical_lines( axs, 0 );
  shared_utils.plot.set_xlims( axs, [-100, 100] );
  
  dsp3.req_savefig( gcf, plot_p, pltlabs, pcats );
end