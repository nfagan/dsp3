%%  plot two panels

conf = dsp3.config.load();

is_normalized = false;
is_z = false;

if ( is_normalized )
  norm_str = 'normalized';
else
  norm_str = 'non_normalized';
end

if ( is_z )
  z_str = 'z';
else
  z_str = 'non_z';
end

kind = sprintf( '%s_%s', norm_str, z_str );
date_dir = datestr( now, 'mmddyy' );
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'psth_no_rasters', date_dir, kind );
shared_utils.io.require_dir( save_plot_p );

psth_p = dsp3.get_intermediate_dir( 'per_trial_psth' );
psth_mats = dsp3.require_intermediate_mats( [], psth_p, [] );

%%

F = figure(1);

for jdx = 1:numel(psth_mats)

psth_file = shared_utils.io.fload( psth_mats{jdx} );

epochs = setdiff( psth_file.psths.keys(), 'cueOn' );

rasters = Container();
psths = Container();

got_psth_t = false;

c_baseline = psth_file.psths('cueOn');
c_baseline_data = mean( c_baseline.psth.data, 2 );

for idx = 1:numel(epochs)
  c_psth_subset = psth_file.psths(epochs{idx});
  rasters = append( rasters, c_psth_subset.raster );
  
  if ( is_normalized )
    c_psth_data = c_psth_subset.psth.data;

    for j = 1:size(c_psth_data, 2)
      c_psth_data(:, j) = c_psth_data(:, j) - c_baseline_data;
    end

    c_psth_data(isinf(c_psth_data)) = NaN;

    c_psth_subset.psth.data = c_psth_data;
  end

  psths = append( psths, c_psth_subset.psth );

  psth_t = c_psth_subset.psth_t;
  raster_t = c_psth_subset.raster_t;
end

if ( is_z )
  z_each = { 'unit_uuid', 'channel', 'region', 'session_ids', 'administration' };

  session_means = psths.each1d( z_each, @(x) nanmean(nanmean(x, 2)) );
  session_devs = psths.each1d( z_each, @(x) nanstd(nanstd(x, [], 2)) );

  [all_i, all_c] = psths.get_indices( z_each );

  for idx = 1:numel(all_i)
    subset_data = get_data( psths(all_i{idx}) );

    subset_mean = session_means(all_c(idx, :));
    subset_dev = session_devs(all_c(idx, :));

    assert( shapes_match(subset_mean, subset_dev) && shape(subset_dev, 1) == 1 );

    for j = 1:size(subset_data, 2)
      subset_data(:, j) = (subset_data(:, j) - subset_mean.data) ./ subset_dev.data;
    end

    psths.data(all_i{idx}, :) = subset_data;
  end
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

for idx = 1:numel(all_i)
  fprintf( '\n %d of %d', idx, numel(all_i) );

  plt = sub_psth(all_i{idx});
  plt = plt.rm( 'errors' );
  
  c_epoch = all_c{idx, 3};
  c_region = strjoin( flat_uniques(plt, 'region'), '_' );

  lines_are = { 'administration' };
  panels_are = { 'unit_uuid', 'outcomes', 'trialtypes', 'drugs', 'region' };
  title_is = union( panels_are, {'unit_uuid', 'unit_rating'} );
  title_is = setdiff( title_is, 'epochs' );
  
  if ( is_z )
    unit_lab = '(z)';
  else
    unit_lab = '(sp/s)';
  end
  
  if ( is_normalized )
    norm_lab = '(normalized)';
  else
    norm_lab = '(non-normalized)';
  end
  
  pl = ContainerPlotter();
  pl.add_ribbon = false;
  pl.x = psth_t;
  pl.summary_function = @nanmean;
  pl.main_line_width = 1;
  pl.y_label = sprintf( 'firing rate %s %s', unit_lab, norm_lab );
  pl.vertical_lines_at = 0;
  pl.order_panels_by = { 'self', 'both', 'other', 'none' };
  pl.add_smoothing = true;
  pl.x_label = sprintf( 'Time (s) from %s', c_epoch );
  pl.smooth_function = @(x) smooth(x, 7);
  pl.y_lim = [];
  clf( F );
  
  pl.plot( plt, lines_are, panels_are );
  
  full_save_p = fullfile( save_plot_p, c_epoch, c_region );
  
  shared_utils.io.require_dir( full_save_p );
  
  fname = strjoin( flat_uniques(plt, union(panels_are, 'channel')), '_' );
  full_fname = fullfile( full_save_p, fname );
  shared_utils.plot.save_fig( F, full_fname, {'epsc', 'fig', 'png'}, true );      
end

end