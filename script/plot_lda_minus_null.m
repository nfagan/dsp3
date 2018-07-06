import shared_utils.cell.percell;

drug_type = 'nondrug';

conf = dsp3.config.load();

date_dir = '061118';  % per day
% date_dir = '061218';  % across days
lda_dir = fullfile( conf.PATHS.dsp2_analyses, 'lda', date_dir );

lda = get_messy_lda_data( lda_dir );

if ( strcmp(drug_type, 'nondrug') ), lda('drugs') = '<drugs>'; end

sub_null = false;
mean_across_perms = false;

plotp = fullfile( conf.PATHS.data_root, 'plots', 'lda', datestr(now, 'mmddyy') );

%%

ldalabs = fcat.from( lda.labels );
ldadat = lda.data * 100;  % convert to percent
freqs = lda.frequencies;
time = -500:50:500;

%%  subtract real - null

uselabs = ldalabs';
usedat = ldadat;

if ( sub_null )
  real = find( uselabs, 'real_percent' );
  null = find( uselabs, 'shuffled_percent' );

  assert( numel(real) == numel(null) );

  minus_null = rowref( usedat, real ) - rowref( usedat, null );

  uselabs = setcat( prune(uselabs(real)), 'measure', 'real - null' );
  usedat = minus_null;
end

%%  calculate band-wise averages

ts = [ -250, 0 ];
bands = { [4, 8], [15, 25], [45, 60] };
bandnames = { 'theta', 'beta', 'gamma' };

t_ind = time >= ts(1) & time <= ts(2);

t_meaned = squeeze( nanmean(usedat(:, :, t_ind, :), 3) );

bandlabs = addcat( repmat(uselabs', numel(bands)), 'bands' );

N = size( t_meaned, 1 );

all_meaned = zeros( N*numel(bands), size(t_meaned, 3) );

for i = 1:numel(bands)
  f_ind = freqs >= bands{i}(1) & freqs <= bands{i}(2);
  
  mean_data = squeeze( nanmean(t_meaned(:, f_ind, :), 2) );
  
  rowinds = (1:N) + ((i-1) * N);
  
  all_meaned(rowinds, :) = mean_data;
  setcat( bandlabs, 'bands', bandnames{i}, rowinds );
end

prune( bandlabs );

%%  reshape to column vector
[tmplabs, I] = keepeach( bandlabs', categories(bandlabs) );

N = size( all_meaned, 2 );
newdat = zeros( numel(I) * N, 1 );
newlabs = repmat( tmplabs', N );

for i = 1:numel(I)
  mean_dat = all_meaned(I{i}, :);
  
  rowinds = (1:N) + ((i-1) * N);
  
  newdat(rowinds, :) = mean_dat;  
  assign( newlabs, tmplabs, rowinds, I{i} );
end
%%  mean to within day (across permutations)

pltlabs = newlabs';
pltdat = newdat;

if ( mean_across_perms )
  meanspec = { 'administration', 'contexts', 'bands', 'epochs', 'drugs', 'days', 'measure' };
  [pltlabs, I] = keepeach( pltlabs, meanspec );
  pltdat = rownanmean( pltdat, I );
end

%%

do_save = false;

plot_prefix = 'panels_bands_bar_minus_null';

pl = plotlabeled();
pl.error_func = @plotlabeled.nansem;
pl.panel_order = { 'theta', 'beta', 'gamma' };
pl.one_legend = true;

plt = labeled( pltdat, pltlabs );

axs = pl.bar( plt, 'contexts', 'measure', 'bands' );

arrayfun( @(x) ylabel(x, 'Percent correct (difference from null)'), axs(1) );

if ( do_save )
  shared_utils.io.require_dir( plotp );
  fname = fcat.trim( joincat(prune(pltlabs), {'contexts', 'measure', 'bands'}) );
  fname = sprintf( '%s_%s', plot_prefix, fname );
  shared_utils.plot.save_fig( gcf, fullfile(plotp, fname), {'epsc', 'png', 'fig'}, true );
end



