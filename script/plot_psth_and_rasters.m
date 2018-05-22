%%  plot two panels

conf = dsp3.config.load();

kind = 'side_by_side_psth_raster';
date_dir = datestr( now, 'mmddyy' );
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'psth', date_dir, kind );
shared_utils.io.require_dir( save_plot_p );

psth_p = dsp3.get_intermediate_dir( 'per_trial_psth' );
psth_mats = dsp3.require_intermediate_mats( [], psth_p, [] );

%%

do_normalize = false;

for jdx = 1:numel(psth_mats)

psth_file = shared_utils.io.fload( psth_mats{jdx} );

epochs = setdiff( psth_file.psths.keys(), 'cueOn' );

rasters = Container();
psths = Container();

got_psth_t = false;

if ( psth_file.psths.isKey('cueOn') )
  c_baseline = psth_file.psths('cueOn');
  c_baseline_data = mean( c_baseline.psth.data, 2 );
else
  assert( ~do_normalize );
end
  
for idx = 1:numel(epochs)
  c_psth_subset = psth_file.psths(epochs{idx});
  rasters = append( rasters, c_psth_subset.raster );
  
  if ( do_normalize )
  
    c_psth_data = c_psth_subset.psth.data;

    for j = 1:size(c_psth_data, 2)
      c_psth_data(:, j) = c_psth_data(:, j) ./ c_baseline_data;
    end

    c_psth_data(isinf(c_psth_data)) = NaN;

    c_psth_subset.psth.data = c_psth_data;
    
  end
  
  psths = append( psths, c_psth_subset.psth );

  psth_t = c_psth_subset.psth_t;
  raster_t = c_psth_subset.raster_t;
end

% get rid of cued trials for targacq
ind_raster = rasters.where('cued') & rasters.where('targAcq');
ind_psth = psths.where('cued') & psths.where('targAcq');

rasters = rasters(~ind_raster);
psths = psths(~ind_psth);

pl = ContainerPlotter();

sub_psth = psths;

sub_psth = sub_psth.rm( 'unit_uuid__NaN' );

[all_i, all_c] = sub_psth.get_indices( {'unit_uuid', 'channel', 'epochs', 'trialtypes'} );

fig = figure(1);

summary_func = @nanmean;

for idx = 1:numel(all_i)
  fprintf( '\n %d of %d', idx, numel(all_i) );

  plt = sub_psth(all_i{idx});
  plt = plt.rm( 'errors' );
  
  c_epoch = all_c{idx, 3};
  c_region = strjoin( flat_uniques(plt, 'region'), '_' );

  figs_are = { 'unit_uuid', 'outcomes', 'trialtypes', 'epochs', 'region' };
  title_is = union( figs_are, {'unit_uuid', 'unit_rating'} );
  title_is = setdiff( title_is, 'epochs' );

  [I, C] = plt.get_indices( figs_are );

  clf( fig );

  subplot(1, 2, 1);

  cstp = 1;

  colors = containers.Map();

  colors('self') = [1, 0, 0];
  colors('both') = [0.75, 0, 0];
  colors('other') = [0, 0.75, 0];
  colors('none') = [0, 0.3, 0];

  current_max = 1;

  color_strs = cell( 1, numel(I) );

  h = gobjects( 1, numel(I) );
  
  should_save = true;
  
  t1 = tic();
  for i = 1:numel(I)
    if ( ~should_save ), continue; end

    color_str = strjoin( C(i, strcmp(figs_are, 'outcomes')), ', ' );
    color_strs{i} = color_str;

    subset = plt(I{i});

    smooth_amt = 7;
    meaned_data = smooth( summary_func(subset.data, 1), smooth_amt );
    meaned_data = meaned_data(:)';

    smoothed_err = smooth( rowops.sem(subset.data), smooth_amt );
    smoothed_err = smoothed_err(:)';

    ind = true( size(psth_t) );

    subplot( 1, 2, 1 ); hold on;
    h(i) = plot( psth_t(ind), meaned_data(:, ind), 'k', 'linewidth', 2 );
    set( h(i), 'color', colors(color_str) );
    
    ylims = get( gca, 'ylim' );
    xlim( gca, [-0.5, 0.5] );
    
    hold on;
    plot( [0, 0], ylims, 'k--' );
    
    if ( do_normalize )
      ylabel( 'Normalized Firing Rate' );
    else
      ylabel( 'sp / s' );
    end
    xlabel( sprintf('time (s) from %s', char(plt('epochs'))) );

    title( strjoin(flat_uniques(subset, title_is), ' | ') );

    matching_raster = rasters(C(i, :));
    raster_data = matching_raster.data;
    c_raster_t = raster_t;
    
    inds = cell( 1, size(raster_data, 1) );
    ts = cell( 1, size(raster_data, 1) );
    cstp = 1;
    for j = 1:size(raster_data, 1)
      inds{j} = find( raster_data(j, :) );
      ts{j} = repmat( cstp, 1, numel(inds{j}) );
      if ( ~isempty(inds{j}) )
        cstp = cstp + 1;
      end
    end

    empties = cellfun( @isempty, inds );
    inds(empties) = [];
    ts(empties) = [];
    
    inds = [inds{:}];
    ts = [ts{:}];
    subplot( 1, 2, 2 ); hold on;
    
    current_n = sum( ~empties );
    scatter( c_raster_t(inds), current_max + ts - 1, 0.2, colors(color_str) );
    current_max = current_max + current_n;

    current_max = current_max + 20;

    ylim( [0, 1350] );
%     xlim( [-0.3, 0.5] );

    ylims = get( gca, 'ylim' );
    xlim( gca, [-0.5, 0.5] );
    
    hold on;
    plot( [0, 0], ylims, 'k--' );
    xlabel( 'time (s) from event onset' );
    
  end
  toc(t1);

  legend( h, color_strs );
  
  full_save_p = fullfile( save_plot_p, c_epoch, c_region );
  
  shared_utils.io.require_dir( full_save_p );
  
  if ( should_save )
    fname = strjoin( flat_uniques(plt, union(figs_are, 'channel')), '_' );
    full_fname = fullfile( full_save_p, fname );
    t2 = tic();
    shared_utils.plot.save_fig( fig, full_fname, {'epsc', 'fig', 'png'}, true );      
    toc( t2 );
  end
end

end