conf = dsp3.config.load();

subdirs = { 'across', 'across_filtered' };
subdirs = cellfun( @(x) fullfile('xcorr', x, 'targacq'), subdirs, 'un', false );

xcorr_mats = dsp3.require_intermediate_mats( subdirs );
% xcorr_mats = shared_utils.cell.containing( xcorr_mats, '01042017' );

plot_p = fullfile( conf.PATHS.data_root, 'plots', 'xcorr', datestr(now, 'mmddyy') );

%%

include_trace = false;

values = cell( 1, numel(xcorr_mats) );

S = size( values );

lags = cell( S );
labs = fcat.empties( S );

meta = cell( S );
metalabs = fcat.empties( S );

tracedat = cell( S );
tracelabs = fcat.empties( S );

drug_type = 'nondrug';
subset_spec = { 'days', 'sites', 'channels', 'regions', 'bands', 'subdir' };

parfor i = 1:numel(xcorr_mats)
  dsp3.progress( i, numel(xcorr_mats) );
  
  xcorr_file = shared_utils.io.fload( xcorr_mats{i} );
  corr_params = xcorr_file.params;
  
  if ( isempty(xcorr_file.data) )
    continue;
  end
  
  one_labs = xcorr_file.labels;
  xcorr_data = xcorr_file.data;
  
  scaleopt =  dsp3.field_or_default( corr_params, 'xcorr_scale_opt', 'coeff' );
  shuffed =   dsp3.field_or_default( corr_params, 'shuffle', false );
  subdir =    dsp3.field_or_default( corr_params, 'output_subdir', '<output_subdir>' );
  ref_type =  dsp3.field_or_default( corr_params, 'ref_type', '<ref_type>' );
  is_pt =     dsp3.field_or_default( corr_params, 'per_trial', true );
  use_env =   dsp3.field_or_default( corr_params, 'use_envelope', true );
  
  if ( strcmp(scaleopt, 'none') ), scaleopt = 'scaleopt_none'; end
  if ( shuffed ), shuf_str = 'shuffled_true'; else, shuf_str = 'shuffled_false'; end
  if ( use_env ), input_type = 'amp-env'; else, input_type = 'voltage'; end
  
  setcat( addcat(one_labs, 'scaleopt'), 'scaleopt', scaleopt );
  setcat( addcat(one_labs, 'shuffled'), 'shuffled', shuf_str );
  setcat( addcat(one_labs, 'subdir'), 'subdir', subdir );
  setcat( addcat(one_labs, 'inputtype'), 'inputtype', input_type );
  
  vals = cell2mat( cellfun(@(x) x.value, xcorr_data, 'un', false) );
  
  if ( is_pt )
    cont = Container( vals, SparseLabels.from_fcat(one_labs) );
    cont = dsp3.get_subset( cont, drug_type, subset_spec );
    one_labs = fcat.from( cont.labels );
    vals = cont.data;
  end
  
  if ( include_trace )
    corr_input = cellfun( @(x) dsp3.field_or_default(x, 'raw_dat', []), xcorr_data, 'un', false );
    input_labs = cellfun( @(x) dsp3.field_or_default(x, 'raw_labs', fcat()), xcorr_data, 'un', false );
    
    padded = shared_utils.cell.padconcat( corr_input );
    input_labs = extend( fcat(), input_labs{:} );
  else
    padded = [];
    input_labs = fcat();
  end
  
  [~, I] = only( one_labs, {'bla_acc', 'choice'} );
  
  values{i} = vals(I, :);
  lags{i} = xcorr_data{1}.lags;
  labs{i} = append( labs{i}, one_labs );
  
  single_labs = one( one_labs' );
  
  tracedat{i} = padded;
  tracelabs{i} = mergenew( input_labs, single_labs );
  meta{i} = xcorr_file.params;
  metalabs{i} = single_labs;
end

tracelabs = extend( fcat(), tracelabs{:} );
tracedat = shared_utils.cell.padconcat( tracedat );

lags = lags{1};

labs = extend( fcat(), labs{:} );
values = vertcat( values{:} );

meta = vertcat( meta{:} );
metalabs = extend( fcat(), metalabs{:} );

%%  get subset

corrlabs = labs';
corrdat = values;

[~, I] = remove( corrlabs, {'errors', 'cued'} );
corrdat = corrdat(I, :);

maxs = nan( length(corrdat), 1 );

for i = 1:size(corrdat, 1)
  [~, ind] = max( abs(corrdat(i, :)) );
  maxs(i) = lags(ind);
end

%%  meaned max or xcorr value

% to_mean = corrdat;
to_mean = maxs;

specificity = { 'bands', 'regions', 'days', 'administration', 'outcomes', 'trialtypes', 'epochs', 'subdir' };
[meanlabs, I] = keepeach( corrlabs', specificity );
meandat = rownanmean( to_mean, I );

corrlabeled = labeled( meandat, meanlabs );

%%  per trial maxs

corrlabeled = labeled( maxs, corrlabs );

%%
do_save = false;

pl = plotlabeled();
pl.add_errors = false;
pl.error_func = @plotlabeled.nansem;
pl.x = lags;
pl.one_legend = true;
pl.fig = figure(1);
pl.group_order = { 'self', 'both', 'other', 'none' };

figure(1);
clf();

lines_are = { 'outcomes' };
panels_are = { 'bands', 'trialtypes', 'regions', 'administration', 'subdir' };

axs = pl.lines( corrlabeled, lines_are, panels_are );

arrayfun( @(x) set(x, 'nextplot', 'add'), axs );
shared_utils.plot.add_vertical_lines( axs, 0 );

if ( do_save )
  fname = joincat( getlabels(corrlabeled), {'outcomes', 'ref_type', 'bands', 'trialtypes', 'regions'} );
  shared_utils.io.require_dir( plot_p );
  shared_utils.plot.save_fig( gcf, fullfile(plot_p, fname), {'epsc', 'png', 'fig'}, true );
end

%%  hist max lags

f = figure( 3 );
clf( f );

pltdat = corrlabeled.data;
pltlabs = getlabels( corrlabeled );

[~, I] = remove( pltlabs, 'shuffled_true' );
pltdat = pltdat(I);

figs_are = { 'bands', 'subdir' };
panels_are = { 'bands', 'subdir', 'outcomes', 'regions' };

[fig_i, fig_c] = findall( pltlabs, figs_are );

n_bins = 50;
summary_func = @(x) nanmean(x, 1);

prefix = 'mean_concatenated_day_level';

for i = 1:numel(fig_i)
  
  clf( f );
  
  sublabs = pltlabs(fig_i{i});
  subdat = pltdat(fig_i{i}, :);
  
  [I, C] = findall( sublabs, panels_are );
  
  n_panels = numel( I );
  
  shp = shared_utils.plot.get_subplot_shape( n_panels );
%   shp = [ 4, 2 ];
  
  axs = gobjects( 1, n_panels );
  
  for j = 1:n_panels
    
    ax = subplot( shp(1), shp(2), j );
    set( ax, 'nextplot', 'add' );
    
    dat = subdat(I{j});
    
    histogram( ax, dat, n_bins );
    
    summarized = summary_func( dat );
    p = signrank( dat );
    
    shared_utils.plot.add_vertical_lines( ax, 0, 'k--' );
    shared_utils.plot.add_vertical_lines( ax, summarized, 'r--' );
    
    lims = get( ax, 'ylim' );
    
    txt = sprintf( 'M = %0.3f, p = %0.3f', summarized, p );
    
    if ( p < 0.05 )
      txt = sprintf( '%s *', txt );
    end
    
    text( 0, mean(lims), txt );
    
    title( strrep(strjoin(C(:, j), ' | '), '_', ' ') );
    
    axs(j) = ax;
  end
  
  shared_utils.plot.match_xlims( axs );
%   shared_utils.plot.match_ylims( axs );

  full_p = fullfile( plot_p, 'lag_distributions' );
  fname = sprintf( '%s_%s', prefix, strjoin(fig_c(:, i), '_') );
  
  shared_utils.io.require_dir( full_p );
  shared_utils.plot.save_fig( gcf, fullfile(full_p, fname), {'epsc', 'png', 'fig'}, true );
      
end

%%  hist max lags
do_save = false;

f = figure(3);
clf( f );
set( f, 'units', 'normalized' );
set( f, 'position', [0, 0, 1, 1] );

pl = ContainerPlotter();
pl.shape = [4, 2];

plt = Container.from( corrlabeled );

figs_are = { 'bands' };
[I, C] = get_indices( plt, figs_are );

for i = 1:numel(I)
  
clf( f );  

subset_plt = plt(I{i});

axs = pl.hist( subset_plt, 50, [], {'subdir', 'outcomes', 'bands'} );

fname = strjoin( flat_uniques(subset_plt, figs_are), '_' );

shared_utils.io.require_dir( plot_p );
shared_utils.plot.save_fig( gcf, fullfile(plot_p, fname), {'png'});

end

%%

do_save = true;

pltlabs = tracelabs';
pltdata = tracedat;

[~, I1] = only( pltlabs, {'choice', 'theta'} );
pltdata = pltdata(I1, :);

addcat( pltlabs, 'rawtype' );
setcat( pltlabs, 'rawtype', 'raw_false' );
setcat( pltlabs, 'rawtype', 'raw_true', find(pltlabs, 'raw') );

prune( pltlabs );

[I, C] = findall( pltlabs, 'uuid' );

f = figure(1);
clf( f );

set( f, 'defaultLegendAutoUpdate', 'off' );
set( f, 'units', 'normalized' );
set( f, 'position', [0, 0, 1, 1] );

% series = 1:numel( I );
% series = 4;
series = 1:4

start_trial = 1;
n_trials = 6;
add_lines = true;

for i = series
  
  clf( f );
  ax = gca();
  
  subset_labs = pltlabs( I{i} );
  subset_dat = pltdata( I{i}, : );
  
  plt = labeled( subset_dat, subset_labs );
  
  param_ind = find( metalabs, combs(subset_labs, 'subdir') );
  c_params = meta(param_ind);
  window_dur = c_params.ts(2) - c_params.ts(1);
  start_x = window_dur * (start_trial-1);
  max_x = window_dur * n_trials + start_x;
  
  pl = plotlabeled();
  pl.shape = [2, 1];
  pl.one_legend = true;
  pl.match_y_lims = false;
  
  axs = pl.lines( plt, {'datatype'}, {'regions', 'outcomes', 'bands' ...
    , 'subdir', 'days', 'rawtype'} );
  set( axs, 'nextplot', 'add' );
  
  shared_utils.plot.match_ylims( axs([1, 2]) );
  shared_utils.plot.match_ylims( axs([3, 4]) );
  
  if ( add_lines )
    shared_utils.plot.add_vertical_lines( axs, start_x+window_dur:window_dur:max_x-window_dur );
  end
  
  xlim( axs, [0, max_x] );
  
  if ( do_save )
    
    fname = strjoin( combs(one(prune(getlabels(plt))), {'outcomes', 'bands', 'subdir', 'days'}), '_' );
    fname = strrep( strrep(fname, '<', ''), '>', '' );   
    
    full_plotp = fullfile( plot_p, 'traces' );
    shared_utils.io.require_dir( full_plotp );
    shared_utils.plot.save_fig( gcf, fullfile(full_plotp, fname), {'epsc', 'png', 'fig'}, true );   
  end
end




