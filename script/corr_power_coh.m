conf = dsp3.config.load();
plot_p = fullfile( conf.PATHS.data_root, 'plots', 'corr_coh_power', datestr(now, 'mmddyy') );

%%

% meas1 = 'z_raw_power';
% meas2 = 'z_coherence';
% manip = 'pro_v_anti';
% drug_type = 'nondrug';
% epoch = 'targacq';

meas1 = 'at_raw_power';
meas2 = 'at_coherence';
manip = '';
drug_type = 'nondrug';
epoch = 'targacq';

outs = dsp3.get_pow_coh_data( meas1, meas2, manip, drug_type, epoch );

totlabels = outs.labels';
totdata = outs.data;

chc = trueat( totlabels, find(totlabels, 'choice') );
errs = trueat( totlabels, find(totlabels, 'errors') );

I = find( chc & ~errs );

totdata = rowref( totdata, I );
keep( totlabels, I );

assert( rows(totdata) == rows(totlabels) );

%%

ts = [ -250, 0 ];

t_ind = t >= ts(1) & t <= ts(2);

tmeaned = nanmean( dimref(totdata, t_ind, 3), 3 );

[plt_labs, I] = only( totlabels', 'power' );
plt_data = rowref( tmeaned, I );

I = findall( plt_labs ...
  , {'regions', 'sites', 'channels', 'measure', 'subdir', 'days', 'administration', 'trialtypes'} );

outlabs = fcat();
outdata = [];

for i = 1:numel(I)
  self = find( plt_labs, 'self', I{i} );
  both = find( plt_labs, 'both', I{i} );
  other = find( plt_labs, 'other', I{i} );
  none = find( plt_labs, 'none', I{i} );
  
  sb = rowref( plt_data, self ) - rowref( plt_data, both );
  on = rowref( plt_data, other ) - rowref( plt_data, none );
  
  outdata = [ outdata; sb; on ];
  
  append( outlabs, plt_labs, self );
  append( outlabs, plt_labs, other );
end

replace( outlabs, 'self', 'self-both' );
replace( outlabs, 'other', 'other-none' );

pl = plotlabeled();
pl.error_func = @plotlabeled.nansem;
pl.x = freqs;
pl.main_line_width = 4;

axs = pl.lines( labeled(outdata, outlabs), {'outcomes'}, {'regions', 'measure'} );

arrayfun( @(x) xlim(x, [0, 100]), axs );

%%

ts = [ -250, 0 ];

t_ind = t >= ts(1) & t <= ts(2);

tmeaned = nanmean( dimref(totdata, t_ind, 3), 3 );

[plt_labs, I] = only( totlabels', 'power' );
plt_data = rowref( tmeaned, I );

% plt_labs = totlabels';
% plt_data = tmeaned;

pl = plotlabeled();
pl.error_func = @plotlabeled.nansem;
pl.x = freqs;
pl.main_line_width = 4;

axs = pl.lines( labeled(plt_data, plt_labs), {'outcomes'}, {'regions', 'measure'} );

arrayfun( @(x) xlim(x, [0, 100]), axs );

arrayfun( @(x) set(x, 'yscale', 'log'), axs );


%%

ts = [ -250, 0 ];
t_ind = t >= ts(1) & t <= ts(2);

bands = { [4, 8], [15, 25], [45, 60] };
bandnames = { 'theta', 'beta', 'gamma' };

tmeaned = nanmean( dimref(totdata, t_ind, 3), 3 );

bandlabs = repmat( totlabels', numel(bands) );
setcat( addcat(bandlabs, 'bands'), 'bands', bandnames{1} );
banddat = zeros( length(bandlabs), 1 );

stp = 1;

for i = 1:numel(bands)
  f_ind = freqs >= bands{i}(1) & freqs <= bands{i}(2);
  
  bmeaned = nanmean( dimref(tmeaned, f_ind, 2), 2 );
  
  rowi = stp:stp+numel(bmeaned)-1;
  
  banddat(rowi) = bmeaned;
  setcat( bandlabs, 'bands', bandnames{i}, rowi );
  
  stp = stp + numel( bmeaned );
end

%%

mean_spec = { 'days', 'bands' };

[cohlabs, I] = keepeach( bandlabs', mean_spec );

coh_data = [];
pow_data = [];
all_labs = fcat();

for i = 1:numel(I)
  pow_ind = find( bandlabs, 'power', I{i} );
  coh_ind = find( bandlabs, 'coherence', I{i} );
  
  coh_mean = nanmean( banddat(coh_ind), 1 );
  
  reg_i = findall( bandlabs, 'regions', pow_ind );
  
  for j = 1:numel(reg_i)
    ind = reg_i{j};
    
    pow_mean = nanmean( banddat(ind), 1 );
    
    coh_data = [ coh_data; coh_mean ];
    pow_data = [ pow_data; pow_mean ];
    
    append1( all_labs, bandlabs, ind );
  end
end

%%

prefix = 'corr_log';

log_scale = true;
do_save = false;

pl = plotlabeled();
pl.fig = figure(2);
pl.plot_empties = false;
pl.marker_size = 8;
pl.color_func = @hsv;
pl.panel_order = { 'theta', 'beta', 'gamma' };
pl.shape = [3, 2];
pl.add_legend = false;

% [pltlabs, I] = only( all_labs', {'none'} );
% pltx = rowref( coh_data, I );
% plty = rowref( pow_data, I );

pltlabs = all_labs';
pltx = coh_data;
plty = pow_data;

[axs, ids] = pl.scatter( pltx, plty, pltlabs, 'subdir', {'regions', 'bands', 'outcomes'} );

shared_utils.plot.match_xlims( axs );

arrayfun( @(x) xlabel(x, 'coherence'), axs(end) );
arrayfun( @(x) ylabel(x, 'raw power'), axs(end) );

for i = 1:numel(ids)
  ax = ids(i).axes;
  ind = ids(i).index;
  
  X = pltx(ind);
  Y = plty(ind);
  
  [r, p] = corr( X, Y, 'rows', 'complete' );
  
  xlims = get( ax, 'xlim' );
  ylims = get( ax, 'ylim' );
  
  xticks = get( ax, 'xtick' );
  yticks = get( ax, 'ytick' );
  
  ps = polyfit( X, Y, 1 );
  y = polyval( ps, xticks );
  
  set( ax, 'nextplot', 'add' );
  plot( ax, xticks, y );
  
  coord_func = @(x) ((x(2)-x(1)) * 0.75) + x(1);
  
  xc = coord_func( xlims );
  yc = coord_func( ylims );
  
  txt = sprintf( 'R = %0.2f, p = %0.3f', r, p);
  
  thresh = 0.05 / numel( ids );
  
  if ( p < thresh ), txt = sprintf( '%s *', txt ); end
  
  text( ax, xc, yc, txt );
end

% set( gcf, 'units', 'normalized' );
% set( gcf, 'position', [0, 0, 1, 1] );

if ( log_scale )
  arrayfun( @(x) set(x, 'yscale', 'log'), axs );
end

if ( do_save )
  fname = fcat.trim( joincat(prune(all_labs), {'subdir', 'regions', 'bands'}) );
  fname = sprintf( '%s_%s', prefix, fname );
  
  shared_utils.io.require_dir( plot_p );
  shared_utils.plot.save_fig( gcf, fullfile(plot_p, fname), {'epsc', 'png', 'fig'}, true );  
end