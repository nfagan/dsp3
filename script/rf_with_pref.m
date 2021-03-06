conf = dsp3.config.load();

%%

[rf, rflabs, freqs] = dsp3.get_matrix_rf( fullfile('nondrug', '053018') );
t = -500:50:500;

%%

date_dir = '053018';
lda_p = fullfile( conf.PATHS.dsp2_analyses, 'lda', date_dir );
lda = shared_utils.io.fload( char(shared_utils.io.find(lda_p, '.mat')) );
transformed = dsp3.get_transformed_lda( lda );
%%

[rf, rflabs, freqs, t] = dsp3.get_matrix_lda( transformed({'choice', 'targAcq'}) );
[~, I] = only( rflabs, 'real_mean' );
rf = rf(I, :, :);

%%

replace( rflabs, 'selfBoth', 'selfboth' );
replace( rflabs, 'otherNone', 'othernone' );
replace( rflabs, 'all__administration', 'pre' );
replace( rflabs, 'real_percent', 'real_mean' );

prune( rflabs );

%%

drug_type = 'nondrug';

if ( strcmp(drug_type, 'nondrug') )
  setcat( rflabs, 'drugs', '<drugs>' );
end

combined = dsp3.get_consolidated_data();

behav = require_fields( combined.trial_data, {'channels', 'regions', 'sites'} );

behav = dsp3.get_subset( behav, drug_type );

pref = dsp3.get_processed_pref_index( behav );

pref.data = full( pref.data );

pref = only( pref, rflabs('days') );

med_split = dsp3.get_median_split_preference( pref );

%%  add median split labels

med_data = med_split.data;

addcat( rflabs, 'median' );

for i = 1:size(med_data, 1)
  
  below_days = med_data{i, 1};
  above_days = med_data{i, 2};
  selectors = med_data{i, 4};
  
  I = find( rflabs, selectors );
  
  below_ind = intersect( I, find(rflabs, below_days) );
  above_ind = intersect( I, find(rflabs, above_days) );
  
  setcat( rflabs, 'median', 'below', below_ind );
  setcat( rflabs, 'median', 'above', above_ind );
  
end

prune( rflabs );

%%  median split

min_t = -250;
max_t = 0;

t_ind = t >= min_t & t <= max_t;
t_data = squeeze( nanmean(rf(:, :, t_ind), 3) );

colons = repmat( {':'}, 1, ndims(t_data)-1 );

pl = plotlabeled();
pl.x = freqs;
pl.one_legend = true;

pltlabs = rflabs';

% [~, I] = only( pltlabs, {'pre'} );
% t_data = t_data(I, colons{:});

plt = labeled( t_data, pltlabs );

lines_are = { 'median' };
panels_are = { 'contexts', 'drugs', 'administration' };

pl.lines( plt, lines_are, panels_are );

%%  median split bars

ts = [ -250, 0 ];
bands = { [15, 25], [45, 60] };
bandnames = { 'beta', 'gamma' };

rois = [];
roilabs = fcat();

baselabs = addcat( rflabs', 'band' );

for i = 1:numel(bandnames)
  f_ind = freqs >= bands{i}(1) & freqs <= bands{i}(2);
  t_ind = t >= ts(1) & t <= ts(2);
  
  meaned = squeeze( nanmean(nanmean(rf(:, f_ind, t_ind), 3), 2) );
  
  rois = [ rois; meaned ];
  
  append( roilabs, setcat(baselabs, 'band', bandnames{i}) );
end

pl = plotlabeled();
pl.error_func = @plotlabeled.nansem;
pl.one_legend = true;
pl.y_lims = [ 50, 53 ];

plt = labeled( rois, roilabs );

x_is = { 'band' };
groups_are = { 'median' };
panels_are = { 'contexts' };

pl.bar( plt, x_is, groups_are, panels_are );

%%

pltcont = SignalContainer( rf, SparseLabels.from_fcat(rflabs) );
pltcont.start = -500;
pltcont.stop = 500;
pltcont.step_size = 50;
pltcont.frequencies = freqs;

pltcont = collapse( pltcont, 'median' );

spec = {'contexts', 'drugs', 'administration'};

pltcont = each1d( pltcont, spec, @rowops.nanmean );

spectrogram( pltcont, spec );

%%  correlate 2

add_ratio = true;

ts = [ -250, 0 ];
bands = { [15, 25], [45, 60] };
bandnames = { 'beta', 'gamma' };

pref = only( pref, {'choice'} );

prefdat = pref.data;
preflabs = fcat.from( pref.labels );

correlate_each = { 'contexts', 'trialtypes', 'days', 'administration' };
[newlabs, I, C] = keepeach( preflabs', correlate_each );

mcat = 'model';
setcat( addcat(newlabs, mcat), mcat, incat(rflabs, mcat) );

t_ind = t >= ts(1) & t <= ts(2);

X = zeros( numel(I) * (numel(bandnames) + add_ratio), 1 );
Y = zeros( size(X) );

corrlabs = fcat.like( newlabs );

for i = 1:numel(bandnames)
  f_ind = freqs >= bands{i}(1) & freqs <= bands{i}(2);
  
  t_data = squeeze( nanmean(nanmean(rf(:, f_ind, t_ind), 3), 2) );
  
  for j = 1:numel(I)
    pref_ind = I{j};
    matching_ind = find( rflabs, C(:, j) );

    assert( numel(matching_ind) == 1 && numel(pref_ind) == 1 );
    
    stp = (i-1) * numel(I) + j;

    X(stp) = prefdat(pref_ind);
    Y(stp) = t_data(matching_ind);
  end
  
  setcat( addcat(newlabs, 'band'), 'band', bandnames{i} );
  append( corrlabs, newlabs );
end

%   add gamma beta ratio
if ( add_ratio )
  gamma_ind = strcmp( bandnames, 'gamma' );
  beta_ind = strcmp( bandnames, 'beta' );

  assert( ~isempty(gamma_ind) && ~isempty(beta_ind) );

  g_ind = freqs >= bands{gamma_ind}(1) & freqs <= bands{gamma_ind}(2);
  b_ind = freqs >= bands{beta_ind}(1) & freqs <= bands{beta_ind}(2);

  g_data = squeeze( nanmean(nanmean(rf(:, g_ind, t_ind), 3), 2) );
  b_data = squeeze( nanmean(nanmean(rf(:, b_ind, t_ind), 3), 2) );

  ratio_data = g_data ./ b_data;

  for j = 1:numel(I)
    pref_ind = I{j};
    matching_ind = find( rflabs, C(:, j) );

    assert( numel(matching_ind) == 1 && numel(pref_ind) == 1 );

    stp = i * numel(I) + j;

    X(stp) = prefdat(pref_ind);
    Y(stp) = ratio_data(matching_ind);
  end

  setcat( newlabs, 'band', 'gamma_beta_ratio' );
  append( corrlabs, newlabs );
end

%%

pltlabs = corrlabs';
pltx = X;
plty = Y;

pltbands = { 'beta', 'gamma' };
% pltbands = combs( corrlabs, 'band' );

[~, I] = only( pltlabs, pltbands );

pltx = pltx(I);
plty = plty(I);

pl = plotlabeled();
pl.color_func = @hsv;
pl.marker_size = 10;
pl.plot_empties = false;
pl.fig = figure(1);

panels_are = { 'outcomes', 'drugs', 'band', 'model' };
groups_are = { 'outcomes', 'administration' };

[axs, ids] = scatter( pl, pltx, plty, pltlabs, groups_are, panels_are );

shared_utils.plot.match_xlims( axs );

for i = 1:numel(ids)
  ind = ids(i).index;
  
  ax = ids(i).axes;
  
  x = pltx(ind);
  y = plty(ind);
  
  if ( isempty(x) || isempty(y) ), continue; end
  
  [r, p] = corr( x, y, 'rows', 'complete' );
  ps = polyfit( x, y, 1 );
  xs = get( ax, 'xtick' );
  ys = polyval( ps, xs );
  plot( ax, xs, ys );
  
  txt = sprintf( 'R=%0.3f, P=%0.3f', r, p );
  
  if ( p < 0.05 ), txt = sprintf( '%s <- *', txt ); end
  
  text( ax, xs(end-1), ys(end), txt );   
  
end

arrayfun( @(x) xlabel(x, 'Preference'), axs );
arrayfun( @(x) ylabel(x, '% Correct'), axs );

%%  correlate

min_t = -250;
max_t = 0;
min_f = 15;
max_f = 25;

t_ind = t >= min_t & t <= max_t;
f_ind = freqs >= min_f & freqs <= max_f;

t_data = squeeze( nanmean(nanmean(rf(:, f_ind, t_ind), 3), 2) );

pref = only( pref, {'choice'} );

prefdat = pref.data;
preflabs = fcat.from( pref.labels );

correlate_each = { 'contexts', 'trialtypes', 'days', 'administration' };

[newlabs, I, C] = keepeach( preflabs', correlate_each );

X = zeros( numel(I), 1 );
Y = zeros( size(X) );

for i = 1:numel(I)
  
  pref_ind = I{i};
  matching_ind = find( rflabs, C(:, i) );
  matching_ind = intersect( matching_ind, find(rflabs, 'real_mean') );
  
  assert( numel(matching_ind) == 1 && numel(pref_ind) == 1 );
  
  X(i) = t_data(matching_ind);
  Y(i) = prefdat(pref_ind);
    
end

%%

figure(1);
clf();

panels_are = { 'contexts', 'drugs', 'administration' };
groups_are = { 'drugs' };

spec = [ panels_are, groups_are ];

[I, gc] = findall( newlabs, spec );

pc = combs( newlabs, panels_are );

keys = fcat.join( pc );

[~, p_inds] = ismember( panels_are, spec );

subp_shape = shared_utils.plot.get_subplot_shape( size(pc, 2) );

panel_map = containers.Map( keys, 1:size(pc, 2) );
axes_map = containers.Map( 'keytype', 'char', 'valuetype', 'any' );

for i = 1:numel(I)
  
  key = char( fcat.join(gc(p_inds, i)) );
  
  panel_ind = panel_map(key);
  
  if ( ~isKey(axes_map, key) )
    ax = subplot( subp_shape(1), subp_shape(2), panel_ind );
    set( ax, 'nextplot', 'add' );
    axes_map(key) = ax;
  else
    ax = axes_map(key);
  end

  ind = I{i};
  
  x = X(ind);
  y = Y(ind);
  
  [r, p] = corr( x, y, 'rows', 'complete' );
  ps = polyfit( x, y, 1 );  
  
  gscatter( X(ind), Y(ind), fcat.join(newlabs(ind, groups_are), 1) );
  
  xstp = get( ax, 'xtick' );
  ystp = get( ax, 'ytick' );
  
  ys = polyval( ps, xstp );
  
  plot( ax, xstp, ys );
  text( ax, xstp(end-1), ys(end), sprintf('r=%0.3f, p=%0.3f', r, p) );
  
  title( strrep(key, '_', ' ') );
  xlabel( ax, 'Percent Correct' );
  ylabel( ax, 'Preference Index' );
end

vals = values( axes_map );
vals = cellfun( @(x) x, vals );

shared_utils.plot.match_xlims( vals );
shared_utils.plot.match_ylims( vals );



%%

figure(1);
clf();

grp_names = { 'contexts', 'trialtypes', 'administration', 'drugs' };
grps = cellfun( @(x) categorical(newlabs(:, x)), grp_names, 'un', false );

gscatter( X, Y, grps ); 
hold on;

[corrlabs, I] = keepeach( newlabs', grp_names );

rs = zeros( numel(I), 2 );

xstp = get( gca, 'xtick' );
ystp = get( gca, 'ytick' );

for i = 1:numel(I)
  
  x = X(I{i});
  y = Y(I{i});
  
  [r, p] = corr( x, y, 'rows', 'complete' );
  
  rs(i, :) = [ r, p ];
  
  ps = polyfit( x, y, 1 );
  
  ys = polyval( ps, xstp );
  
  plot( xstp, ys );
    
  text( xstp(end-1), ys(end), sprintf('r=%0.3f, p=%0.3f', r, p) );
  
end

%%






