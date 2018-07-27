function stats__proanti_coh(varargin)

import shared_utils.io.fullfiles;

defaults = dsp3.get_behav_stats_defaults();
defaults.do_save = true;
defaults.smooth_func = @(x) smooth(x, 4);
defaults.drug_type = 'nondrug';
defaults.epochs = 'targacq';
defaults.config = dsp3.config.load();

params = dsp3.parsestruct( defaults, varargin );

conf = params.config;

epochs =      params.epochs;
drug_type =   params.drug_type;
manips =      'pro_v_anti';
meas_types =  'z_scored_coherence';

p = fullfiles( conf.PATHS.dsp2_analyses, meas_types, epochs, drug_type, manips );
p = p( cellfun(@shared_utils.io.dexists, p) );

components = { 'spectra', dsp3.datedir(), drug_type };

plot_p = char( dsp3.plotp(components) );
analysis_p = char( dsp3.analysisp(components) );

params.plot_p = plot_p;
params.analysis_p = analysis_p;

mats = shared_utils.io.find( p, '.mat' );

%
%
%

[data, labels, freqs, t] = dsp3.load_signal_measure( mats );

replace( labels, 'selfMinusBoth', 'anti' );
replace( labels, 'otherMinusNone', 'pro' );

if ( strcmp(drug_type, 'nondrug') ), collapsecat( labels, 'drugs' ); end

%
%
%

twindow = t >= -250 & t <= 0;
tdim = 3;

tdata = squeeze( nanmean(dimref(data, twindow, tdim), tdim) );

%
%
%

compare_lines( tdata, labels, freqs, params );

%
%
%

[bands, bandnames] = dsp3.get_bands();
ttests( tdata, labels, freqs, bands, bandnames, params );

end

function ttests( tdata, labels, freqs, bands, bandnames, params )

import dsp3.nonun_or_other;

[bandmeans, bandlabs] = dsp3.get_band_means( tdata, labels', freqs, bands, bandnames );

%
%   ts pro v anti
%

spec = { 'bands', 'drugs', 'administration', 'trialtypes', 'measure', 'regions', 'epochs' };
mask = find( bandlabs, 'choice' );

[tlabs, I] = keepeach( bandlabs', spec, mask );
rowlabs = fcat.strjoin( combs(tlabs, dsp3.nonun_or_other(tlabs, spec)), [], ', ' );
t_tbls = table();

for i = 1:numel(I)
  i_pro = find( bandlabs, 'pro', I{i} );
  i_anti = find( bandlabs, 'anti', I{i} );
  
  pro = rowref( bandmeans, i_pro );
  anti = rowref( bandmeans, i_anti );
  
  [~, p, ~, stats] = ttest2( pro, anti );
  stats.p = p;
  
  rowname = [ rowlabs{i} ' pro v. anti' ];  
  tbl = struct2table( stats, 'RowNames', {rowname} );
  t_tbls = [ t_tbls; tbl ];
end

%
%   descriptives
%

funcs = { @plotlabeled.nanmean, @plotlabeled.nanmedian ...
  , @plotlabeled.nansem, @signrank };

mean_spec = union( spec, 'outcomes' );
[m_tbl, tvals, meanlabs] = dsp3.descriptive_table( bandmeans, bandlabs', mean_spec, funcs, mask );

if ( params.do_save )
  prefix = 'proanti_coherence';
  analysis_p = params.analysis_p;
  
  dsp3.savetbl( t_tbls, analysis_p, tlabs, nonun_or_other(tlabs, spec), prefix );
  dsp3.savetbl( m_tbl, analysis_p, meanlabs, nonun_or_other(meanlabs, spec), prefix );  
end

end

function compare_lines( tdata, labels, freqs, params )

F = figure(1);
clf( F );
set( F, 'defaultLegendAutoUpdate', 'off' );

isdrug = dsp3.isdrug( params.drug_type );

mask = find( labels, 'choice' );

[threshs, sort_ind] = sort( [0.05, 0.001], 'descend' );
colors = { 'r', 'y' };
colors = colors( sort_ind );

assert( numel(colors) == numel(threshs) );

if ( isdrug )
  gcats = { 'drugs' };
  pcats = { 'trialtypes', 'outcomes', 'administration', 'measure' };
else
  gcats = { 'outcomes' };
  pcats = { 'trialtypes', 'drugs', 'administration', 'measure' };
end

[newlabs, p_i, p_c] = keepeach( labels', pcats, mask );
plabs = fcat.strjoin( p_c, [], ' | ' );

shp = plotlabeled.get_subplot_shape( numel(p_i) );

all_ps = cell( size(p_i) );
axs = gobjects( size(all_ps) );

sfunc = params.smooth_func;

for i = 1:numel(p_i)
  ax = subplot( shp(1), shp(2), i );
  
  hold( ax, 'on' );
  
  [g_i, g_c] = findall( labels, gcats, p_i{i} );
  glabs = fcat.strjoin( g_c, [], ' | ' );
  
  assert( numel(g_i) == 2, 'Expected 2 outcomes; got %d', numel(g_i) );
  
  first = rowref( tdata, g_i{1} );
  sec = rowref( tdata, g_i{2} );
  
  n_freqs = size( first, 2 );
  ps = zeros( 1, n_freqs );
  
  for j = 1:n_freqs  
    [~, ps(j)] = ttest2( dimref(first, j, 2), dimref(sec, j, 2) );
  end
  
  all_ps{i} = dsp3.fdr( ps );
  
  mean1 = plotlabeled.nanmean( first );
  mean2 = plotlabeled.nanmean( sec );
  errs1 = plotlabeled.nansem( first );
  errs2 = plotlabeled.nansem( sec );
  
  h1 = plot( ax, freqs, sfunc(mean1) );
  h2 = plot( ax, freqs, sfunc(mean2) );
  
  ops = { @plus, @minus };
  
  for j = 1:numel(ops)
    h3 = plot( ax, freqs, ops{j}(sfunc(mean1), sfunc(errs1)) );
    h4 = plot( ax, freqs, ops{j}(sfunc(mean2), sfunc(errs2)) );

    set( h3, 'color', get(h1, 'color') );
    set( h4, 'color', get(h2, 'color') );
    set( h3, 'linewidth', get(h1, 'linewidth')/2 );
    set( h4, 'linewidth', get(h1, 'linewidth')/2 );
  end

  lines = [ h1; h2 ];
  
  legend( lines, glabs );
  title( ax, plabs{i} );
  
  axs(i) = ax;
end

shared_utils.plot.hold( axs );
shared_utils.plot.match_xlims( axs );
shared_utils.plot.match_ylims( axs );

if ( ~isdrug )
  arrayfun( @(x) set(x, 'ylim', [-0.15, 0.15]), axs );
end

markersize = 8;

% add stars
for i = 1:numel(axs)
  
  ax = axs(i);
  lims = get( ax, 'ylim' );
  
  for j = 1:numel(threshs)
    inds = find( all_ps{i} < threshs(j) );
    colorspec = sprintf( '%s*', colors{j} );
    
    for k = 1:numel(inds)
      plot( ax, freqs(inds(k)), lims(2), colorspec, 'markersize', markersize );
    end
  end
  
end

if ( params.do_save )
  prefix = 'pro_anti_coh';
  shared_utils.io.require_dir( params.plot_p );
  
  fname = dsp3.fname( newlabs, dsp3.nonun_or_other(newlabs, pcats) );
  fname = dsp3.prefix( prefix, fname );

  dsp3.savefig( gcf, fullfile(params.plot_p, fname) );
end

end