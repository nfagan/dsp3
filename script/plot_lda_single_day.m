import shared_utils.cell.percell;

drug_type = 'nondrug';

conf = dsp3.config.load();

% date_dir = '061118';  % per day
date_dir = '061218';  % across days
lda_dir = fullfile( conf.PATHS.dsp2_analyses, 'lda', date_dir );

lda = get_messy_lda_data( lda_dir );

if ( strcmp(drug_type, 'nondrug') ), lda('drugs') = '<drugs>'; end

plotp = fullfile( conf.PATHS.data_root, 'plots', 'lda', datestr(now, 'mmddyy') );

%%

ldalabs = fcat.from( lda.labels );
ldadat = lda.data * 100;  % convert to percent
freqs = lda.frequencies;
time = -500:50:500;

%%  reshape such that each permutation, currently the 3-dimension, is concatenated
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

%%  find which day(s) have highest gamma decoding performance, per context

spec = { 'days', 'contexts', 'measure' };
[meanlabs, I] = keepeach( newlabs', spec );

bands = dsp3.get_bands( 'map' );
band = bands('gamma');

f_ind = freqs >= band(1) & freqs <= band(2);

means = zeros( numel(I), 1 );

for i = 1:numel(I)
  means(i) = nanmean( nanmean(newdat(I{i}, f_ind), 2) );
end

real_perc = find( meanlabs, 'real_percent' );

[~, max_on] = max( means(find(meanlabs, 'otherNone', real_perc)) );
[~, max_sb] = max( means(find(meanlabs, 'selfBoth', real_perc)) );

max_day_on = combs( meanlabs, 'days', max_on );
max_day_sb = combs( meanlabs, 'days', max_sb );


%%

pltdat = newdat;
pltlabs = newlabs';

pl = plotlabeled();
pl.one_legend = true;
pl.error_func = @plotlabeled.nansem;
pl.x = freqs;
pl.add_smoothing = true;
pl.smooth_func = @(x) smooth(x, 5);
pl.y_lims = [45, 55];

% collapsecat( pltlabs, 'days' );

% I = findall( pltlabs, 'days', find(pltlabs, max_day_on) );

% mask = find( pltlabs, {'real_percent'}, I{1} );
% mask = I{1};
mask = rowmask( pltlabs );

D = pltdat(mask, :);
L = pltlabs(mask);

lines = 'measure';
panels = { 'contexts', 'days' };

axs = pl.lines( D, L, lines, panels );


