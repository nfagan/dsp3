function plot_rf()

conf = dsp3.config.load();
date_dir = '052918';

[totdata, totlabs, freqs] = dsp3.get_matrix_rf( date_dir );


%%

figure(1);
clf();

specificity = { 'administration', 'drugs', 'days', 'contexts', 'measure' };

meanspec = setdiff( specificity, {'days', 'drugs', 'administration'} );

[meanlabs, I] = keepeach( totlabs', meanspec );

meaned = rowop( totdata, I, @(x) mean(x, 1) );

plotcont = SignalContainer( meaned, SparseLabels.from_fcat(meanlabs) );
plotcont.frequencies = freqs;
plotcont.start = -500;
plotcont.stop = 500;
plotcont.step_size = 50;

spectrogram( plotcont, {'administration', 'contexts', 'measure'} ...
  , 'shape', [2, 2] ...
  );

t_series = plotcont.get_time_series();

%%

min_t = -250;
max_t = 0;

lines_are = { 'measure', 'contexts' };
panels_are = { 'administration' };

t_ind = t_series >= min_t & t_series <= max_t;

t_meaned = squeeze( nanmean(totdata(:, :, t_ind), 3) );

plt = labeled( t_meaned, totlabs );

pl = plotlabeled();
pl.add_errors = true;
pl.x = freqs;

pl.lines( plt, lines_are, panels_are );


end