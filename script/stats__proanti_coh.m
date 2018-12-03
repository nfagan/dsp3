function stats__proanti_coh(varargin)

import shared_utils.io.fullfiles;

defaults = dsp3.get_behav_stats_defaults();
defaults.do_save = true;
defaults.remove = {};
defaults.smooth_func = @(x) smooth(x, 5);
defaults.drug_type = 'nondrug';
defaults.epochs = 'targacq';
defaults.spectra = true;
defaults.is_z = true;
defaults.is_pro_minus_anti = true;
defaults.is_post_minus_pre = false;
defaults.specificity = 'blocks';
defaults.measure = 'coherence';
defaults.time_window = [-250, 0];
defaults.log_scale = false;

params = dsp3.parsestruct( defaults, varargin );

conf = params.config;

epochs =      params.epochs;
drug_type =   params.drug_type;
bs =          params.base_subdir;
manips =      'pro_v_anti';
is_z =        params.is_z;
meas_t =      params.measure;
twindow =     params.time_window;
is_drug =     dsp3.isdrug( drug_type );

if ( is_z )
  meas_types = sprintf( 'z_scored_%s', meas_t );
else
  meas_types = sprintf( 'at_%s', meas_t );
end

z_type = ternary( is_z, 'z', 'nonz' );
load_inputs = {};

if ( is_z )
  p = fullfiles( conf.PATHS.dsp2_analyses, meas_types, epochs, drug_type, manips );
  p = p( cellfun(@shared_utils.io.dexists, p) );
else
  p = dsp3.get_intermediate_dir( fullfiles(meas_types, drug_type, epochs), conf );
  load_inputs = horzcat( load_inputs, {'get_meas_func', @(meas) meas.measure} );
end

dayspec = { 'administration', 'days', 'trialtypes', 'outcomes' };
blockspec = csunion( dayspec, {'blocks', 'sessions'} );

spec_type = params.specificity;

if ( strcmp(params.specificity, 'blocks') )
  sitespec = csunion( blockspec, {'channels', 'regions', 'sites'} );
elseif ( strcmp(params.specificity, 'sites') )
  sitespec = csunion( dayspec, {'channels', 'regions', 'sites'} );
elseif ( strcmp(params.specificity, 'days') )
  sitespec = csunion( dayspec, {'regions'} );
else
  error( 'Unrecognized specificity "%s".', params.specificity );
end

components = { 'spectra', dsp3.datedir(), bs, drug_type, z_type, spec_type };

plot_p = char( dsp3.plotp(components, conf) );
analysis_p = char( dsp3.analysisp(components, conf) );

params.plot_p = plot_p;
params.analysis_p = analysis_p;

mats = shared_utils.io.find( p, '.mat' );

%
%
%

[data, labels, freqs, t] = dsp3.load_signal_measure( mats, load_inputs{:} );

if ( params.log_scale )
  data = log10( data );
end

%   pro v. anti if necessary
if ( haslab(prune(labels), 'self') )
  [data, labels] = dsp3.pro_v_anti( data, labels, cssetdiff(sitespec, 'outcomes') );  
end

replace( labels, 'selfMinusBoth', 'anti' );
replace( labels, 'otherMinusNone', 'pro' );

if ( params.is_pro_minus_anti )
  [data, labels] = dsp3.pro_minus_anti( data, labels, cssetdiff(sitespec, 'outcomes') );
end

if ( ~dsp3.isdrug(drug_type) ), collapsecat( labels, 'drugs' ); end

data = indexpair( data, labels, findnone(labels, params.remove) );

if ( is_drug && params.is_post_minus_pre )
  drug_spec = cssetdiff( sitespec, 'administration' );

  [data, labels] = dsp3.a_summary_minus_b( data, labels', drug_spec, 'post', 'pre' );
  setcat( labels, 'administration', 'post-pre' );
end

%
% spectra
%

if ( params.spectra )
  plot_spectra( data, labels, freqs, t, params );
end

%
%
%

twindow = t >= params.time_window(1) & t <= params.time_window(2);
tdim = 3;

tdata = squeeze( nanmean(dimref(data, twindow, tdim), tdim) );

%
%
%

try 
  compare_lines( tdata, labels, freqs, params );
catch err
  warning( err.message );
  return
end

%
%
%

[bands, bandnames] = dsp3.get_bands();

try
  ttests( tdata, labels, freqs, bands, bandnames, params );
catch err
  warning( err.message );
end

end

function plot_spectra( data, labels, freqs, t, params )

prefix = sprintf( '%sproanti_spectra', params.base_prefix );
pcats = { 'outcomes', 'drugs', 'administration', 'regions' };

f_ind = freqs <= 100;
t_ind = t >= -350 & t <= 300;

pltfreqs = freqs( f_ind );
labfreqs = round( flip(pltfreqs) );

pl = plotlabeled.make_spectrogram( pltfreqs, t(t_ind) );

axs = pl.imagesc( data(:, f_ind, t_ind), labels, pcats );

shared_utils.plot.fseries_yticks( axs, labfreqs, 5 );
shared_utils.plot.tseries_xticks( axs, t(t_ind), 5 );
shared_utils.plot.hold( axs );
shared_utils.plot.add_vertical_lines( axs, find(t(t_ind) == 0) );
shared_utils.plot.fullscreen();

if ( params.do_save )
  dsp3.req_savefig( gcf, params.plot_p, labels, pcats, prefix )
end

if ( dsp3.isdrug(params.drug_type) )
  
  meanspec = 'outcomes';
  a = 'oxytocin';
  b = 'saline';
  
  opfunc = @minus;
  sfunc = @(x) nanmean( x, 1 );
  
  [subdat, sublabs] = dsp3.summary_binary_op( data, labels', meanspec, a, b, opfunc, sfunc );
  setcat( sublabs, 'drugs', sprintf('%s - %s', a, b) );
  
  axs = pl.imagesc( subdat(:, f_ind, t_ind), sublabs, pcats );

  shared_utils.plot.fseries_yticks( axs, labfreqs, 5 );
  shared_utils.plot.tseries_xticks( axs, t(t_ind), 5 );
  shared_utils.plot.hold( axs );
  shared_utils.plot.add_vertical_lines( axs, find(t(t_ind) == 0) );
  shared_utils.plot.fullscreen();

  if ( params.do_save )
    dsp3.req_savefig( gcf, params.plot_p, sublabs, pcats, prefix )
  end
end

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
  prefix = sprintf( 'proanti_%s', params.measure );
  analysis_p = params.analysis_p;
  
  dsp3.savetbl( t_tbls, analysis_p, tlabs, nonun_or_other(tlabs, spec), prefix );
  dsp3.savetbl( m_tbl, analysis_p, meanlabs, nonun_or_other(meanlabs, spec), prefix );  
end

end

function compare_lines( tdata, labels, freqs, params )

F = figure(1);
clf( F );
set( F, 'defaultLegendAutoUpdate', 'off' );

is_drug = dsp3.isdrug( params.drug_type );
per_monk = params.per_monkey;

mask = find( labels, 'choice' );

[threshs, sort_ind] = sort( [0.05, 0.001], 'descend' );
colors = { 'r', 'y' };
colors = colors( sort_ind );

assert( numel(colors) == numel(threshs) );

if ( is_drug )
  gcats = { 'drugs' };
  pcats = { 'trialtypes', 'outcomes', 'administration', 'measure', 'regions' };
else
  gcats = { 'outcomes' };
  pcats = { 'trialtypes', 'drugs', 'administration', 'measure', 'regions' };
end

if ( per_monk ), pcats{end+1} = 'monkeys'; end

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

% if ( ~is_drug )
%   arrayfun( @(x) set(x, 'ylim', [-0.15, 0.15]), axs );
% end

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
  prefix = sprintf( '%spro_anti_%s', params.base_prefix, params.measure );
  shared_utils.io.require_dir( params.plot_p );
  
  fname = dsp3.fname( newlabs, dsp3.nonun_or_other(newlabs, pcats) );
  fname = dsp3.prefix( prefix, fname );

  dsp3.savefig( gcf, fullfile(params.plot_p, fname) );
  shared_utils.plot.fullscreen( gcf );
end

end