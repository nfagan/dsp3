function stats__lda()

import shared_utils.cell.percell;

drug_type = 'nondrug';

conf = dsp3.config.load();

date_dir = '061118';  % per day
% date_dir = '061218';  % across days
lda_dir = fullfile( conf.PATHS.dsp2_analyses, 'lda', date_dir );

lda = get_messy_lda_data( lda_dir );

if ( strcmp(drug_type, 'nondrug') ), lda('drugs') = '<drugs>'; end

path_components = { 'lda', dsp3.datedir };

plotp = dsp3.plotp( path_components );
analysisp = dsp3.analysisp( path_components );

%
%
%

ldalabs = fcat.from( lda.labels );
ldadat = lda.data * 100;  % convert to percent
freqs = lda.frequencies;
time = -500:50:500;

%  reshape such that each permutation, currently the 3-dimension, is concatenated
%   along the first dimension, reducing the 3d-array to a matrix

ts = [ -250, 0 ];

t_ind = time >= ts(1) & time <= ts(2);

t_meaned = squeeze( nanmean(ldadat(:, :, t_ind, :), 3) );

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

params = struct();

compare_lines( newdat, newlabs', freqs, params );

end

function compare_lines( tdata, labels, freqs, params )

F = figure(1);
clf( F );
set( F, 'defaultLegendAutoUpdate', 'off' );

mask = find( labels, 'choice' );

[threshs, sort_ind] = sort( [0.05, 0.001, 0.0001], 'descend' );
colors = { 'y', 'g', 'r' };
colors = colors( sort_ind );

assert( numel(colors) == numel(threshs) );

gcats = { 'measure' };
pcats = { 'trialtypes', 'drugs', 'administration', 'contexts' };

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
  
  legend( lines, strrep(glabs, '_', ' ') );
  title( ax, plabs{i} );
  
  axs(i) = ax;
end

shared_utils.plot.hold( axs );
shared_utils.plot.match_xlims( axs );
shared_utils.plot.match_ylims( axs );

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
      plot( ax, freqs(inds(k)), lims(2), colorspec, 'markersize', markersize );
    end
  end
  
end

if ( do_save )
  prefix = 'pro_anti_coh';
  shared_utils.io.require_dir( params.plot_p );
  
  fname = dsp3.fname( newlabs, dsp3.nonun_or_other(newlabs, pcats) );
  fname = dsp3.prefix( prefix, fname );

  dsp3.savefig( gcf, fullfile(params.plot_p, fname) );
end

end


