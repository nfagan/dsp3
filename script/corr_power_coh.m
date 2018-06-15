meas1 = 'z_raw_power';
meas2 = 'z_coherence';
manip = 'pro_v_anti';
drug_type = 'nondrug';
epoch = 'targacq';

mats = dsp3.require_intermediate_mats( fullfile(meas1, drug_type, manip, epoch) );

coh_p = dsp3.get_intermediate_dir( fullfile(meas2, drug_type, manip, epoch) );

totdata = cell( 1, numel(mats) );
totlabels = fcat.empties( size(totdata) );
freqs = cell( size(totdata) );
t = cell( size(freqs) );

parfor i = 1:numel(mats)
  dsp3.progress( i, numel(mats) );
  
  power_file = shared_utils.io.fload( mats{i} );
  coh_file = shared_utils.io.fload( fullfile(coh_p, power_file.unified_filename) );
  
  plabels = fcat.from( power_file.zlabels, power_file.zcats );
  clabels = fcat.from( coh_file.zlabels, coh_file.zcats );
  
  setcat( addcat(plabels, 'measure'), 'measure', 'power' );
  setcat( addcat(clabels, 'measure'), 'measure', 'coherence' );
  
  totlabels{i} = extend( totlabels{i}, plabels, clabels );
  
  f1 = power_file.frequencies;
  f2 = coh_file.frequencies;
  
  nf = min( numel(f1), numel(f2) );
  f1 = f1(1:nf);
  f2 = f2(1:nf);
  
  totdata{i} = [ dimref(power_file.zdata, 1:nf, 2); dimref(coh_file.zdata, 1:nf, 2) ];
  
  t{i} = power_file.time;
  freqs{i} = f1;
end

totdata = vertcat( totdata{:} );
totlabels = vertcat( totlabels{:} );

t = t{1};
freqs = freqs{1};

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

pl = plotlabeled();
pl.plot_empties = false;
pl.marker_size = 8;
pl.color_func = @hsv;
pl.panel_order = { 'theta', 'beta', 'gamma' };
pl.shape = [3, 2];
pl.add_legend = false;

addcat( all_labs, 'dummy' );

[axs, ids] = pl.scatter( coh_data, pow_data, all_labs, 'dummy', {'regions', 'bands'} );

shared_utils.plot.match_xlims( axs );

arrayfun( @(x) xlabel(x, 'z-coherence'), axs(end) );
arrayfun( @(x) ylabel(x, 'z-raw power'), axs(end) );

for i = 1:numel(ids)
  
  ax = ids(i).axes;
  ind = ids(i).index;
  
  X = coh_data(ind);
  Y = pow_data(ind);
  
  [r, p] = corr( X, Y, 'rows', 'complete' );
  
  xlims = get( ax, 'xlim' );
  ylims = get( ax, 'ylim' );
  
  ps = polyfit( X, Y, 1 );
  y = polyval( ps, xlims );
  
  set( ax, 'nextplot', 'add' );
  plot( ax, xlims, y );
  
  coord_func = @(x) ((x(2)-x(1)) * 0.75) + x(1);
  
  xc = coord_func( xlims );
  yc = coord_func( ylims );
  
  txt = sprintf( 'R = %0.2f, p = %0.3f', r, p);
  
  if ( p < 0.05 ), txt = sprintf( '%s *', txt ); end
  
  text( ax, xc, yc, txt );
end
