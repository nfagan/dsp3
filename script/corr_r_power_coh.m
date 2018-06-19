%%

% meas1 = 'z_raw_power';
% meas2 = 'z_coherence';
% manip = 'pro_v_anti';
% drug_type = 'nondrug';
% epoch = 'targacq';

meas1 = 'raw_power';
meas2 = 'coherence';
manip = '';
drug_type = '';
epoch = 'targacq';

outs = dsp3.get_pow_coh_data( meas1, meas2, manip, drug_type, epoch );

totlabels = outs.labels';
totdata = outs.data;
t = outs.t;
freqs = outs.frequencies;

conf = dsp3.config.load();
plot_p = fullfile( conf.PATHS.data_root, 'plots', 'corr_coh_power', dsp3.datedir );

%%

[~, I] = dsp3.get_subset( totlabels, 'nondrug' );
totdata = rowref( totdata, I );

chc = trueat( totlabels, find(totlabels, 'choice') );
errs = trueat( totlabels, find(totlabels, 'errors') );

I = find( chc & ~errs );

totdata = rowref( totdata, I );
prune( keep(totlabels, I) );

assert( rows(totdata) == rows(totlabels) );

%%

[matchlabs, matched_inds] = dsp3.match_pow_coh_sites( totlabels' );

matchdat = rowref( totdata, matched_inds );

%%

ts = [ -250, 0 ];
fs = [ 0, 100 ];
t_ind = t >= ts(1) & t <= ts(2);
f_ind = freqs >= fs(1) & freqs <= fs(2);

t_meaned = nanmean( dimref(matchdat, t_ind, 3), 3 );
t_meaned = dimref( t_meaned, f_ind, 2 );

%%

[sitelabs, site_i] = keepeach( matchlabs', 'siteid' );

X = zeros( numel(site_i), size(t_meaned, 2) );
Y = zeros( size(X) );

for i = 1:numel(site_i)
  pow_ind = find( matchlabs, 'power', site_i{i} );
  coh_ind = find( matchlabs, 'coherence', site_i{i} );
  
  bla_ind = find( matchlabs, 'bla', pow_ind );
  acc_ind = find( matchlabs, 'acc', pow_ind );
  coh_ind = find( matchlabs, 'bla_acc', coh_ind );
  
  bla = t_meaned(bla_ind, :);
  acc = t_meaned(acc_ind, :);
  
  assert( isequal(size(bla), size(acc)) );
  
  rs = zeros( 1, size(bla, 2) );
  ps = zeros( size(rs) );
  
  for j = 1:size(bla, 2)
    [rs(j), ps(j)] = corr( bla(:, j), acc(:, j), 'rows', 'complete' );
  end
  
  X(i, :) = rs;
  Y(i, :) = nanmean( t_meaned(coh_ind, :), 1 );
end

%%  scatter all data

prefix = 'all_data';
do_save = true;

pl = plotlabeled();
pl.fig = figure(1);

pltx = X(:);
plty = Y(:);
pltlabs = repmat( sitelabs', size(X, 2) );

[axs, ids] = pl.scatter( pltx, plty, pltlabs, 'subdir', 'trials' );

arrayfun( @(x) ylabel(x, 'Site-level coherence'), axs );
arrayfun( @(x) xlabel(x, 'Site-level power-correlation'), axs );

[h, stats] = plotlabeled.scatter_addcorr( ids, pltx, plty );

if ( do_save )
  fname = fcat.trim( sprintf('%s_%s', prefix, joincat(sitelabs, {'subdir', 'drugs'})) );
  shared_utils.io.require_dir( plot_p );
  shared_utils.plot.save_fig( gcf, fullfile(plot_p, fname), {'epsc', 'png', 'fig'}, true );
end


%%  scatter per band

do_save = true;
prefix = 'per_band';

[bands, bandnames] = dsp3.get_bands();

bands{end+1} = [ 65, 100 ];
bandnames{end+1} = 'high gamma';

bandlabs = addcat( repmat(sitelabs', numel(bands)), 'bands' );
stp = 1;
N = length( sitelabs );
pltx = zeros( N*numel(bands), 1 );
plty = zeros( size(pltx) );

for i = 1:numel(bands)
  f_ind = freqs >= bands{i}(1) & freqs <= bands{i}(2);
  
  x = nanmean( dimref(X, f_ind, 2), 2 );
  y = nanmean( dimref(Y, f_ind, 2), 2 );
  
  rowi = stp:stp+N-1;
  
  setcat( bandlabs, 'bands', bandnames{i}, rowi );
  pltx(rowi) = x;
  plty(rowi) = y;
  
  stp = stp + N;
end

[axs, ids] = pl.scatter( pltx, plty, bandlabs, 'subdir', 'bands' );

arrayfun( @(x) ylabel(x, 'Site-level coherence'), axs );
arrayfun( @(x) xlabel(x, 'Site-level power-correlation'), axs );

h = plotlabeled.scatter_addcorr( ids, pltx, plty );

shared_utils.plot.fullscreen( gcf );

if ( do_save )
  fname = fcat.trim( sprintf('%s_%s', prefix, joincat(bandlabs, {'subdir', 'drugs', 'bands'})) );
  shared_utils.io.require_dir( plot_p );
  shared_utils.plot.save_fig( gcf, fullfile(plot_p, fname), {'epsc', 'png', 'fig'}, true );
end


