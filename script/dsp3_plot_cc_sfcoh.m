data_p = '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/data/sfcoh';

use_nan = false;

if ( ~use_nan )
  data = shared_utils.io.fload( fullfile(data_p, 'cc_sf_coh_data.mat') );
  labels = shared_utils.io.fload( fullfile(data_p, 'cc_sf_coh_labels.mat') );
else
  data = shared_utils.io.fload( fullfile(data_p, 'cc_sf_coh_data_nan.mat') );
  labels = shared_utils.io.fload( fullfile(data_p, 'cc_sf_coh_labels_nan.mat') );
end

labels = fcat.from( labels );

%%

spec = { 'outcomes', 'sites' };

[meanlabs, I] = keepeach( labels', spec );
meandat = rowop( data, I, @(x) nanmean(x, 1) );

[meandat, meanlabs] = dsp3.pro_v_anti( meandat, meanlabs', 'sites' );

%%
site_I = findall( meanlabs, 'sites' );

to_keep = rowmask( meanlabs );

for i = 1:numel(site_I)
  if ( any(columnize(isnan(meandat(site_I{i}, :, :)))) )
    to_keep = setdiff( to_keep, site_I{i} );    
  end
end

%%

pltdat = meandat;
pltlabs = meanlabs';

t = -500:50:500;
freqs = linspace( 0, 500, size(pltdat, 2) );

f_ind = freqs >= 0 & freqs <= 100;
t_ind = t >= -300 & t <= 300;

pl = plotlabeled.make_spectrogram( freqs(f_ind), t(t_ind) );
% pl.panel_order = { 'pro', 'anti' };

pcats = { 'outcomes', 'regions' };

pl.c_lims = [-0.015, 0.015];
pl.shape = [2, 1];

mask = fcat.mask( pltlabs, to_keep ...
  , @find, 'acc_spike_bla_field' ...
);

axs = pl.imagesc( pltdat(mask, f_ind, t_ind), pltlabs(mask), pcats );

shared_utils.plot.hold( axs, 'on' );

shared_utils.plot.tseries_xticks( axs, t(t_ind), 5 );
shared_utils.plot.fseries_yticks( axs, round(flip(freqs(f_ind))), 5 );
shared_utils.plot.add_vertical_lines( axs, find(t(t_ind) == 0) );