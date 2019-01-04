function stats__lda(varargin)

import shared_utils.cell.percell;

defaults = dsp3.get_behav_stats_defaults();
defaults.specificity = 'sites';
defaults.is_cued = false;
defaults.underlying_measure = 'coherence';
defaults.analysis_type = 'lda';
defaults.smooth_func = @(x) smooth( x, 5 );
defaults.plot_spec = { 'days', 'channels', 'regions' };
defaults.plot_per_site = true;
defaults.time_window = [-250, 0];
defaults.freq_window = [ 15, 25 ];
defaults.xlims = [];
defaults.over_frequency = true;
defaults.keep_one_per_site = false;

params = dsp3.parsestruct( defaults, varargin );

drug_type = params.drug_type;
bsd = params.base_subdir;
plot_spec = params.plot_spec;
is_cued = params.is_cued;

underlying_measure = validatestring( params.underlying_measure ...
  , {'coherence', 'sfcoherence'}, mfilename, 'underlying_measure' );
analysis_type = validatestring( params.analysis_type ...
  , {'lda', 'rf'}, mfilename, 'analysis_type' );

conf = dsp3.config.load();

switch ( underlying_measure )
  case 'coherence'
    % date_dir = '061118';  % per day
    % date_dir = '061218';  % across days
    % date_dir = '072418';  % per site
    date_dir = get_data_dir( params.specificity );
  case 'sfcoherence'
    date_dir = get_sf_data_dir( params.specificity, analysis_type, is_cued );
end

lda_dir = fullfile( conf.PATHS.dsp2_analyses, analysis_type, date_dir );

lda = get_messy_lda_data( lda_dir );

if ( strcmp(drug_type, 'nondrug') ), lda('drugs') = '<drugs>'; end
if ( ~strcmp(params.specificity, 'sites') && contains_fields(lda, 'channels') )
  lda('channels') = '<channels>'; 
end

path_components = { analysis_type, dsp3.datedir, bsd, underlying_measure, drug_type };

params.plotp = char( dsp3.plotp(path_components) );
params.analysisp = char( dsp3.analysisp(path_components) );

%
%
%

ldalabs = fcat.from( lda.labels );
ldadat = lda.data * 100;  % convert to percent
freqs = lda.frequencies;
time = -500:50:500;

if ( strcmp(params.underlying_measure, 'sfcoherence') )
  renamecat( ldalabs, 'sites', 'channels' );
end

%  reshape such that each permutation, currently the 3-dimension, is concatenated
%   along the first dimension, reducing the 3d-array to a matrix

if ( params.over_frequency )
  ts = params.time_window;

  t_ind = time >= ts(1) & time <= ts(2);

  t_meaned = squeeze( nanmean(ldadat(:, :, t_ind, :), 3) );
  
  x_values = freqs;
else  
  fs = params.freq_window;
  
  f_ind = freqs >= fs(1) & freqs <= fs(2);
  
  t_meaned = squeeze( nanmean(ldadat(:, f_ind, :, :), 2) );
  
  x_values = time;
end

nrows = size( t_meaned, 1 );
ncols = size( t_meaned, 2 );
niters = size( t_meaned, 3 );

newdat = zeros( niters*nrows, ncols );
newlabs = repmat( ldalabs', niters );

stp = 1;

for i = 1:niters
  newdat(stp:stp+nrows-1, :) = squeeze( t_meaned(:, :, i) );
  stp = stp + nrows;
end

if ( params.keep_one_per_site )
  newdat = keep_one_per_site( newdat, newlabs );
  newdat = keep_valid_rows( newdat, newlabs );
end

if ( ~params.plot_per_site )
  collapsecat( newlabs, {'channels', 'days'} );
end

I = findall( newlabs, plot_spec );

for i = 1:numel(I)
  shared_utils.general.progress( i, numel(I), mfilename );
  
  compare_lines( newdat, newlabs, x_values, I{i}, params );
end

end

function [dat, labs] = keep_valid_rows(dat, labs)

is_missing = all( dat == 0, 2 );

dat(is_missing, :) = [];
keep( labs, find(~is_missing) );

end

function [dat, labs] = keep_one_per_site(dat, labs)

I = findall( labs, {'measure', 'drugs', 'days', 'channels', 'regions' ...
  , 'trialtypes', 'contexts'} );

unqs = unique( cellfun(@numel, I) );

assert( numel(unqs) == 1 );

to_keep = cellfun( @(x) x(1), I );

dat = dat(to_keep, :);
keep( labs, to_keep );

end

function compare_lines( tdata, labels, x_values, basemask, params )

F = figure(1);
clf( F );
set( F, 'defaultLegendAutoUpdate', 'off' );

mask = findnot( labels, {'targAcq', 'cued'}, basemask );

[threshs, sort_ind] = sort( [0.05, 0.001, 0.0001], 'descend' );
colors = { 'y', 'g', 'r' };
colors = colors( sort_ind );

assert( numel(colors) == numel(threshs) );

gcats = { 'measure' };
pcats = { 'trialtypes', 'drugs' ...
  , 'administration', 'contexts', 'days', 'channels', 'regions' };

pcats = dsp3.nonun_or_all( labels, pcats );

[newlabs, p_i, p_c] = keepeach( labels', pcats, mask );
plabs = fcat.strjoin( p_c, [], ' | ' );

shp = plotlabeled.get_subplot_shape( numel(p_i) );

all_ps = cell( size(p_i) );
axs = gobjects( size(all_ps) );

sfunc = dsp3.field_or_default( params, 'smooth_func', @(x) x );
do_save = dsp3.field_or_default( params, 'do_save', false );

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
  
  h1 = plot( ax, x_values, sfunc(mean1) );
  h2 = plot( ax, x_values, sfunc(mean2) );
  
  ops = { @plus, @minus };
  
  for j = 1:numel(ops)
    h3 = plot( ax, x_values, ops{j}(sfunc(mean1), sfunc(errs1)) );
    h4 = plot( ax, x_values, ops{j}(sfunc(mean2), sfunc(errs2)) );

    set( h3, 'color', get(h1, 'color') );
    set( h4, 'color', get(h2, 'color') );
    set( h3, 'linewidth', get(h1, 'linewidth')/2 );
    set( h4, 'linewidth', get(h1, 'linewidth')/2 );
  end

  lines = [ h1; h2 ];
  
  legend( lines, strrep(glabs, '_', ' ') );
  title( ax, strrep(plabs{i}, '_', ' ') );
  
  axs(i) = ax;
end

shared_utils.plot.hold( axs );
shared_utils.plot.match_xlims( axs );
shared_utils.plot.match_ylims( axs );

if ( ~isempty(params.xlims) )
  shared_utils.plot.set_xlims( axs, params.xlims );
end

% arrayfun( @(x) set(x, 'ylim', [-0.15, 0.15]), axs );

markersize = 8;

% add stars
for i = 1:numel(axs)
  ax = axs(i);
  lims = get( ax, 'ylim' );
  
  for j = 1:numel(threshs)
    inds = find( all_ps{i} < threshs(j) );
    colorspec = sprintf( '%s*', colors{j} );
    
    for k = 1:numel(inds)
      plot( ax, x_values(inds(k)), lims(2), colorspec, 'markersize', markersize );
    end
  end
end

shared_utils.plot.add_horizontal_lines( axs, 50 );

if ( do_save )
  prefix = 'pro_anti_coh';
  shared_utils.io.require_dir( params.plotp );
  
  fname = dsp3.fname( newlabs, csunion(pcats, 'channels') );
  fname = dsp3.prefix( prefix, fname );

  dsp3.savefig( gcf, fullfile(params.plotp, fname) );
end

end

function date_dir = get_sf_data_dir(spec, analysis_type, is_cued)

switch ( spec )
  case 'contexts'
    if ( strcmp(analysis_type, 'lda') )
      if ( is_cued )
        date_dir = '121918';
      else
        date_dir = '121018';
      end
    else
      assert( strcmp(analysis_type, 'rf') );
      date_dir = '121718';
    end
  case 'sites'
    assert( strcmp(analysis_type, 'lda') );
    date_dir = '121318';
  otherwise
    error( 'Unrecognized specificty "%s".', spec );
end

% date_dir = '120618';

end

function date_dir = get_data_dir(spec)

switch ( spec )
  case 'contexts'
    date_dir = '061218';
  case 'days'
    date_dir = '061118';
  case 'sites'
    date_dir = '072618';
%     date_dir = '072418';
  otherwise
    error( 'Unrecognized specificty "%s".', spec );
end
end


