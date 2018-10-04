function stats__lda_hists(varargin)

import shared_utils.cell.percell;

defaults = dsp3.get_behav_stats_defaults();
defaults.specificity = 'sites';
defaults.smooth_func = @(x) smooth( x, 5 );
defaults.lda = [];
params = dsp3.parsestruct( defaults, varargin );

drug_type = params.drug_type;
bsd = params.base_subdir;

conf = dsp3.config.load();

date_dir = get_data_dir( params.specificity );
% date_dir = '061118';  % per day
% date_dir = '061218';  % across days
% date_dir = '072418';  % per site
lda_dir = fullfile( conf.PATHS.dsp2_analyses, 'lda', date_dir );

if ( isempty(params.lda) )
  lda = get_messy_lda_data( lda_dir );
else
  lda = params.lda;
end

path_components = { 'lda', dsp3.datedir, drug_type, bsd, 'summary' };
params.plotp = char( dsp3.plotp(path_components, conf) );

%%

ldalabs = fcat.from( lda.labels );
ldadat = lda.data * 100;  % convert to percent
freqs = lda.frequencies;
time = -500:50:500;

ldadat = indexpair( ldadat, ldalabs, findnone(ldalabs, params.remove) );

if ( ~dsp3.isdrug(drug_type) )
  collapsecat( ldalabs, 'drugs' );
end

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

plot_summary( newdat, newlabs', freqs, params );
plot_hist( newdat, newlabs', freqs, params );


end

function plot_hist(ldadat, ldalabs, freqs, params)

f = figure(1);
clf( f );

bands = dsp3.get_bands( 'map' );
[banddat, bandlabs] = dsp3.get_band_means( ldadat, ldalabs', freqs, bands );

basespec = { 'measure', 'contexts', 'bands', 'trialtypes', 'drugs', 'administration' };
sitespec = csunion( basespec, {'days', 'sites', 'channels', 'regions'} );

[meanlabs, I] = keepeach( bandlabs', sitespec );
meandat = rownanmean( banddat, I );

pcats = basespec;
pcats = dsp3.nonun_or_all( ldalabs, pcats );

mask = fcat.mask( meanlabs, @find, 'real_percent' );

pltdat = rowref( meandat, mask );
pltlabs = meanlabs(mask);

[p_I, C] = findall( pltlabs, pcats );

shp = plotlabeled.try_subplot_shape( [3, 2], numel(p_I) );
axs = gobjects( size(p_I) );

for i = 1:numel(p_I)
  ax = subplot( shp(1), shp(2), i );
  
  paneldat = rowref( pltdat, p_I{i} );
  med = median( paneldat );
  
  hist( ax, paneldat, 30 );
  
  title_labs = strjoin( C(:, i), ' | ' );
  title_labs = strrep( title_labs, '_', ' ' );
  
  title( ax, title_labs );
  
  shared_utils.plot.hold( ax );
  shared_utils.plot.add_vertical_lines( ax, med, 'r-' );
  
  x_coord = med + 1;
  y_coord = get( gca, 'ylim' );
  y_coord = y_coord(2) - (y_coord(2)-y_coord(1)) * 0.1;
  
  med_txt = sprintf( 'M = %0.2f', med );
  text( ax, x_coord, y_coord, med_txt );
  
  axs(i) = ax;
end

shared_utils.plot.match_xlims( axs );
shared_utils.plot.match_ylims( axs );

dsp3.req_savefig( gcf, params.plotp, pltlabs, pcats, 'lda__' );


end

function plot_summary(ldadat, ldalabs, freqs, params)

pl = plotlabeled.make_common( 'x', freqs );

gcats = { 'measure' };
pcats = { 'contexts', 'trialtypes', 'drugs', 'administration' }; 

pcats = dsp3.nonun_or_all( ldalabs, pcats );

pl.lines( ldadat, ldalabs, gcats, pcats );

dsp3.req_savefig( gcf, params.plotp, ldalabs, pcats, 'lines' );

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
