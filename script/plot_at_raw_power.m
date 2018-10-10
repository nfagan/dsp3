conf = dsp3.config.load();

% power_type = 'z_scored_raw_power';
power_type = 'raw_power';

if ( strcmpi(power_type, 'z_scored_raw_power') )
  raw_power_p = fullfile( conf.PATHS.dsp2_analyses, 'z_scored_raw_power/targacq/nondrug/pro_v_anti' );
  get_meas_func = @(x) x;
  is_z = true;
elseif ( strcmpi(power_type, 'raw_power') )
  raw_power_p = '/Users/Nick/Desktop/test';
  get_meas_func = @(x) x.measure;
  is_z = false;
else
  error( 'Unrecognized power type "%s".', power_type );
end

raw_files = shared_utils.io.find( raw_power_p, '.mat' );

[data, labels, freqs, t] = dsp3.load_signal_measure( raw_files ...
  , 'get_meas_func', get_meas_func ...
  , 'identify_meas_func', @(x, y) 'raw_power' ...
);

plot_components = {dsp3.datedir(), power_type};
spectra_plot_p = dsp3.plotp( {'spectra', plot_components{:}} );
spectra_plot_p = spectra_plot_p{1};
lines_plot_p = dsp3.plotp( {'lines', plot_components{:}} );
lines_plot_p = lines_plot_p{1};

%%

meanspec = { 'outcomes', 'trialtypes', 'days', 'sites', 'blocks', 'channels', 'regions' };

[meanlabs, I] = keepeach( labels', meanspec );

meandat = rowop( data, I, @(x) mean(x, 1) );

addsetcat( meanlabs, 'prosociality', 'prosocial' );

if ( is_z )
  addsetcat( meanlabs, 'prosociality', 'antisocial', find(meanlabs, {'selfBoth'}) );
else
  addsetcat( meanlabs, 'prosociality', 'antisocial', find(meanlabs, {'none', 'self'}) );
end

%%

usedat = meandat;
uselabs = meanlabs';
usespec = setdiff( meanspec, 'outcomes' );

lab_a = { 'prosocial' };
lab_b = { 'antisocial' };

sfunc = @(x) nanmean(x, 1);
opfunc = @minus;

mask = fcat.mask( uselabs, @find, 'choice' );

[pa_dat, pa_labs] = dsp3.summary_binary_op( usedat, uselabs, usespec, lab_a, lab_b, opfunc, sfunc, mask );
setcat( pa_labs, 'prosociality', 'pro - anti' );

%%

do_save = false;
is_pa = true;

t_ind = t >= -350 & t <= 300;

pl = plotlabeled.make_spectrogram( freqs, t(t_ind) );
pl.fig = figure(2);

if ( is_pa )
  pltdat = pa_dat;
  pltlabs = pa_labs';
  
  if ( is_z )
    lims = [ -0.35, 0.2 ];
  else
    pltdat = pltdat ./ (1-pltdat);
%     lims = [ -4.8e-4, 4.3e-4 ];
%     lims = [ -4.8e-4, 3e-4 ];
%     lims = [ -4.75e-4, 4e-4 ];
    lims = [];
  end
else
  pltdat = meandat;
  pltlabs = meanlabs';
  lims = [];
end

mask = fcat.mask( pltlabs, @find, 'choice' );

pcats = { 'prosociality', 'regions' };

axs = pl.imagesc( pltdat(mask, :, t_ind), pltlabs(mask), pcats );

shared_utils.plot.tseries_xticks( axs, t(t_ind), 5 );
shared_utils.plot.fseries_yticks( axs, flipud(round(freqs)), 5 );

if ( ~isempty(lims) )
  shared_utils.plot.set_clims( axs, lims );
end

arrayfun( @(x) xlabel(x, sprintf('Time (ms) from %s', char(pltlabs('epochs')))), axs );

if ( do_save )
  formats = { 'epsc', 'png', 'fig', 'svg' };
  dsp3.req_savefig( figure(2), spectra_plot_p, pltlabs, pcats, power_type, formats );
end

%%  lines -- compare

figure(1);
clf();

pltdat = meandat;
pltlabs = meanlabs';

gcats = { 'prosociality' };
pcats = { 'regions' };

t_ind = t >= -250 & t <= 0;
pltdat = nanmean( pltdat(:, :, t_ind), 3 );

axs = dsp3.plot_compare_lines( pltdat, pltlabs', gcats, pcats ...
  , 'mask',             fcat.mask(pltlabs, @find, 'choice') ...
  , 'x',                freqs ...
  , 'summary_func',     @(x) nanmean(x, 1) ...
  , 'error_func',       @plotlabeled.nansem ...
  , 'smooth_func',      @(x) smooth(x, 4) ...
  , 'correction_func',  @dsp3.fdr ...
);

shared_utils.plot.set_ylims( axs, [-0.25, 0.25] );

%%

do_save = true;

figure(1);
clf();

compare_series = true;
alpha = 0.05;

usedat = meandat;
uselabs = meanlabs';

t_ind = t >= -250 & t <= 0;
t_meaned = nanmean( usedat(:, :, t_ind), 3 );

mask = fcat.mask( uselabs, @find, 'choice' );

gcats = { 'prosociality' };
pcats = { 'regions' };

[I, p_c] = findall( uselabs, pcats, mask );

shp = plotlabeled.get_subplot_shape( numel(I) );
axs = gobjects( 1, numel(I) );

if ( is_z )
  lims = [ -0.25, 0.25 ];
else
  lims = [ 1e-7, 1e-2 ];
end

smooth_func = @(x) smooth(x, 3);

for i = 1:numel(I)
  [g_i, g_c] = findall( uselabs, gcats, I{i} );
  ax = subplot( shp(1), shp(2), i );
  
  compare_series = compare_series && numel( g_i ) == 2;
  
  if ( compare_series )    
    grp_dat = cell( size(g_i) );
  end
  
  hs = gobjects( 1, numel(g_i) );
  
  for j = 1:numel(g_i)
    dat = rowref( t_meaned, g_i{j});
    
    means = nanmean( dat, 1 );
    errs = plotlabeled.nansem( dat );
    
    h_mean = plot( ax, freqs, smooth_func(means) );
    shared_utils.plot.hold( ax, 'on' );
    h_err1 = plot( ax, freqs, smooth_func(means + errs) );
    h_err2 = plot( ax, freqs, smooth_func(means - errs) );
    
    set( h_err1, 'color', get(h_mean, 'color') );
    set( h_err2, 'color', get(h_mean, 'color') );
    
    if ( compare_series )
      grp_dat{j} = dat;
    end
    
    hs(j) = h_mean;
  end
  
  axs(i) = ax;
  
  set( gcf, 'defaultLegendAutoUpdate', 'off' );
  legend( hs, fcat.strjoin(g_c, ' | ') );
  title( fcat.strjoin(p_c(:, i), ' | ') );
  
  if ( compare_series )
    n_freqs = size( grp_dat{1}, 2 );
    ps = zeros( 1, n_freqs );
    
    for j = 1:n_freqs
      a = grp_dat{1}(:, j);
      b = grp_dat{2}(:, j);
      
      [~, p, ~] = ttest2( a, b );
      
      ps(j) = p;
    end
    
    corrected_p = dsp3.fdr( ps );
    
    sig_p = find( corrected_p < alpha );
    
    for j = 1:numel(sig_p)
      plot( ax, freqs(sig_p(j)), lims(2), 'k*' );
    end
  end
  
end

shared_utils.plot.set_ylims( axs, lims );
arrayfun( @(x) xlabel(x, 'Hz'), axs );
arrayfun( @(x) ylabel(x, 'Raw Power'), axs );

if ( ~is_z )
  arrayfun( @(x) set(x, 'yscale', 'log'), axs );
end

if ( do_save )
  formats = { 'epsc', 'png', 'fig', 'svg' };
  dsp3.req_savefig( figure(1), lines_plot_p, uselabs ...
    , cshorzcat(pcats, gcats), power_type, formats );
end

%%  pro - anti

do_save = true;

pltdat = pa_dat;
pltlabs = pa_labs';

t_ind = t >= -250 & t <= 0;
pltdat = nanmean( pltdat(:, :, t_ind), 3 );

mask = fcat.mask( pltlabs, @find, 'choice' );

gcats = { 'prosociality' };
pcats = { 'regions' };

pl = plotlabeled.make_common();
pl.x = freqs;
pl.smooth_func = @(x) smooth(x, 3);
pl.add_smoothing = true;
pl.fig = figure(1);

axs = pl.lines( rowref(pltdat, mask), pltlabs(mask), gcats, pcats );

shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_horizontal_lines( axs, 0 );

arrayfun( @(x) xlabel(x, 'Hz'), axs );
arrayfun( @(x) ylabel(x, 'Raw Power'), axs );

if ( do_save )
  formats = { 'epsc', 'png', 'fig', 'svg' };
  dsp3.req_savefig( pl.fig, lines_plot_p, pltlabs ...
    , cshorzcat(pcats, gcats), power_type, formats );
end


