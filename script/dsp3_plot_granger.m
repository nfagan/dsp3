% granger = shared_utils.io.fload( '~/Desktop/granger.mat' );
granger = dsp3_gr.load_granger( '081019' );

%%

pro_v_anti = true;

dat = abs( granger.data );
dat(isinf(dat)) = nan;

site_labs = granger.labels';
site_dat = dat;

site_spec = setdiff( dsp3_ct.site_specificity(), 'unit_uuid' );
proanti_spec = setdiff( site_spec, 'outcomes' );

if ( pro_v_anti )
  [site_dat, site_labs] = dsp3.pro_v_anti( site_dat, site_labs', proanti_spec );
end


%%

f = granger.f(1:501);
t = granger.t(1, :);

f_ind = f >= 10 & f <= 80;
t_ind = t >= -300 & t <= 300;

plt_f = f(f_ind);
plt_t = t(t_ind);

pl = plotlabeled.make_spectrogram( plt_f, plt_t );

plt_labs = site_labs';
plt_dat = site_dat(:, f_ind, t_ind);

pcats = { 'regions', 'outcomes' };

axs = pl.imagesc( plt_dat, plt_labs, pcats );
shared_utils.plot.fseries_yticks( axs, round(flip(plt_f)), 5 );
shared_utils.plot.tseries_xticks( axs, plt_t, 5 );

shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_vertical_lines( axs, find(plt_t == 0) );