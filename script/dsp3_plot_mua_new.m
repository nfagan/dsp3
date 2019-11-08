spikes = wideband.filter( 'cutoffs', mua_cutoffs );
spikes = spikes.update_range();

spikes = dsp2.process.spike.get_mua_psth( spikes, mua_devs );

binned_spk = spikes.windowed_data();

%%

spike_mats = shared_utils.io.findmat( 'H:\data\cc_dictator\mua' );
spike_mats = shared_utils.io.filter_files( spike_mats, {'mua_'}, 'days' );
spike_mats = shared_utils.io.filter_files( spike_mats, {'targacq', 'targon'} );

frs = cell( numel(spike_mats), 1 );
fr_labs = cell( size(frs) );

parfor idx = 1:numel(spike_mats)
  
shared_utils.general.progress( idx, numel(spike_mats) );
  
spikes = shared_utils.io.fload( spike_mats{idx} );
binned_spk = spikes.windowed_data();

labs = fcat.from( spikes.labels );
fr = nan( size(labs, 1), size(binned_spk, 2) );

for i = 1:size(binned_spk, 2)
  spike_ct = sum( binned_spk{i}, 2 );
  bin_width = size( binned_spk{i}, 2 );
  
  sr_factor = spikes.fs / 1e3;

  s_per_bin = bin_width / sr_factor / 1e3;
  fr(:, i) = spike_ct * (1 / s_per_bin);
end

mask = findnot( labs, {'targAcq', 'cued'} );
mask = findnot( labs, {'targOn', 'choice'}, mask );

[~, keep_I] = keepeach( labs, {'days', 'channels', 'trialtypes', 'outcomes' ...
  , 'administration', 'regions'}, mask );
fr = bfw.row_nanmean( fr, keep_I );

frs{idx} = fr;
fr_labs{idx} = labs;

end

%%

fr = vertcat( frs{:} );
fr_labs = vertcat( fcat(), fr_labs{:} );

%%

do_save = true;
save_p = char( dsp3.plotp({'mua', 'psth', dsp3.datedir}) );

t_series = -500:50:500;
t_ind = t_series >= -300 & t_series <= 300;

pl = plotlabeled.make_common();
pl.x = t_series(t_ind);
pl.panel_order = { 'self', 'both', 'other', 'none' };

fcats = { 'regions' };
gcats = { 'trialtypes' };
pcats = { 'outcomes', 'regions' };

mask = fcat.mask( fr_labs ...
  , @find, {'pre'} ...
  , @findnone, {'ref', 'errors'} ...
);

plt = fr(mask, t_ind);
plt_labs = prune( fr_labs(mask) );

[figs, ~, I] = pl.figures( @lines, plt, plt_labs, fcats, gcats, pcats );

if ( do_save )
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, prune(plt_labs(I{i})), [pcats, fcats] );
  end
end

%%

t_series = -500:50:500;

figure(1);
clf();
plot( t_series, nanmean(fr) );