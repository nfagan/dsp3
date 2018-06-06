conf = dsp3.config.load();

% subdirs = { 'xcorr/noscale/targacq', 'xcorr/shuffled/targacq' };
subdirs = { 'xcorr/across/targacq', 'xcorr/noscale/targacq', 'xcorr/shuffled/targacq' };

xcorr_mats = dsp3.require_intermediate_mats( subdirs );

plot_p = fullfile( conf.PATHS.data_root, 'plots', 'xcorr', datestr(now, 'mmddyy') );

%%

values = cell( 1, numel(xcorr_mats) );
lags = cell( size(values) );
labs = arrayfun( @(x) fcat(), 1:numel(values), 'un', false );

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
  
  scaleopt =  dsp3.field_or_default( corr_params, 'xcorr_scale_opt', 'coeff' );
  shuffed =   dsp3.field_or_default( corr_params, 'shuffle', false );
  subdir =    dsp3.field_or_default( corr_params, 'output_subdir', '<output_subdir>' );
  ref_type =  dsp3.field_or_default( corr_params, 'ref_type', '<ref_type>' );
  is_pt =     dsp3.field_or_default( corr_params, 'per_trial', true );
  
  if ( strcmp(scaleopt, 'none') ), scaleopt = 'scaleopt_none'; end
  if ( shuffed ), shuf_str = 'shuffled_true'; else, shuf_str = 'shuffled_false'; end
  
  setcat( addcat(one_labs, 'scaleopt'), 'scaleopt', scaleopt );
  setcat( addcat(one_labs, 'shuffled'), 'shuffled', shuf_str );
  setcat( addcat(one_labs, 'subdir'), 'subdir', subdir );
  
  vals = cell2mat( cellfun(@(x) x.value, xcorr_file.data, 'un', false) );
  
  if ( is_pt )
    cont = Container( vals, SparseLabels.from_fcat(one_labs) );
    cont = dsp3.get_subset( cont, drug_type, subset_spec );
    one_labs = fcat.from( cont.labels );
    vals = cont.data;
  end
  
  [~, I] = only( one_labs, {'bla_acc', 'choice'} );
  
  values{i} = vals(I, :);
  lags{i} = xcorr_file.data{1}.lags;
  labs{i} = append( labs{i}, one_labs );
end

lags = lags{1};

labs = extend( fcat(), labs{:} );
values = vertcat( values{:} );

%%  get subset

corrlabs = labs';
corrdat = values;

[~, I] = remove( corrlabs, {'errors', 'cued'} );
corrdat = corrdat(I, :);

%%

maxs = nan( rows(corrdat), 1 );

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

pltdat = corrlabeled.data;
pltlabs = getlabels( corrlabeled );

[~, I] = remove( pltlabs, 'shuffled_true' );
pltdat = pltdat(I);

figs_are = { 'bands' };
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

commandwindow
