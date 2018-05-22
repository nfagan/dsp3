%%  plot two panels

conf = dsp3.config.load();

kind = 'side_by_side_psth_raster_drug';
date_dir = datestr( now, 'mmddyy' );
save_plot_p = fullfile( conf.PATHS.data_root, 'plots', 'psth', date_dir, kind );
shared_utils.io.require_dir( save_plot_p );

psth_p = dsp3.get_intermediate_dir( 'per_trial_psth' );
psth_mats = dsp3.require_intermediate_mats( [], psth_p, [] );

%%

fig = figure(1);

for jdx = 1:numel(psth_mats)

psth_file = shared_utils.io.fload( psth_mats{jdx} );

epochs = setdiff( psth_file.psths.keys(), 'cueOn' );

rasters = Container();
psths = Container();

for idx = 1:numel(epochs)
  c_psth_subset = psth_file.psths(epochs{idx});
  rasters = append( rasters, c_psth_subset.raster );
  
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
sub_raster = rasters;

to_rm = { 'unit_uuid__NaN', 'errors' };

sub_psth = sub_psth.rm( to_rm );
sub_raster = sub_raster.rm( to_rm );

assert( sub_psth.labels == sub_raster.labels );

figs_are = {'unit_uuid', 'channel', 'epochs', 'trialtypes'};

[all_i, all_c] = sub_psth.get_indices( figs_are );

summary_func = @nanmean;

for idx = 1:numel(all_i)
  fprintf( '\n %d of %d', idx, numel(all_i) );
  
  plt_psth = sub_psth(all_i{idx});
  plt_raster = sub_raster(all_i{idx});  
  
  c_unit_selectors = all_c(idx, :);
  c_epoch = c_unit_selectors{strcmp(figs_are, 'epochs')};
  c_region = char( plt_psth('region') );
  c_drug = char( plt_psth('drugs') );
  
  panels_are = { 'outcomes' };
  lines_are = { 'administration' };
  titles_are = { 'outcomes' };
  
  clf( fig );
  
  [panel_inds, panel_c] = plt_psth.get_indices( panels_are );
  [line_inds, line_c] = plt_psth.get_indices( lines_are );
  
  all_indices = dsp3.allcombn( {1:numel(panel_inds), 1:numel(line_inds)} );
  
  subplot_dims = [ 2, 4 ];
  
  line_colors = containers.Map();
  line_colors('pre') = [0, 0, 1];
  line_colors('post') = [1, 0, 0];
  
  current_maxes = containers.Map();
  lines = containers.Map();
  
  raster_axs = gobjects( 1, subplot_dims(2) );
  psth_axs = gobjects( size(raster_axs) );
  
  ax_stp = 1;
  raster_ylim = [0, 250];
  raster_xlim = [-0.5, 0.5];
  psth_xlim = raster_xlim;
  first_plot = true;
  
  for i = 1:size(all_indices, 1)
    
    c_indices = all_indices(i, :);
    psth_subplot_ind = c_indices{1};
    raster_subplot_ind = psth_subplot_ind + numel(panel_inds);
    ind_into_plt = panel_inds{psth_subplot_ind} & line_inds{c_indices{2}};
    
    condition_str = panel_c{c_indices{1}, 1};
    pre_post_str = line_c{c_indices{2}, 1};
    
    c_color = line_colors(pre_post_str);
    
    c_psth = plt_psth(ind_into_plt);
    
    if ( ~any(ind_into_plt) )
      ax_stp = ax_stp + 1;
      continue; 
    end
    
    subset_data = plt_psth.data(ind_into_plt, :);
    subset_raster = plt_raster.data(ind_into_plt, :);
    
    smooth_amt = 7;
    meaned_data = smooth( summary_func(subset_data, 1), smooth_amt );
    meaned_data = meaned_data(:)';
    
    psth_axs(ax_stp) = subplot( subplot_dims(1), subplot_dims(2), psth_subplot_ind ); 
    
    xlim(psth_axs(ax_stp), psth_xlim );
    
    hold on;
    
    h = plot( psth_t, meaned_data );
    set( h, 'color', c_color );
    
    title_str = strjoin( flat_uniques(c_psth, titles_are), ' | ' );
    
    title( title_str );
    
    if ( first_plot )
      xlabel( sprintf('Time (s) from %s', c_epoch) );
      first_plot = false;
    end
    
    if ( ~isKey(lines, pre_post_str) )
      lines(pre_post_str) = h;
    end
    
    %   now raster data
    
    inds = cell( 1, size(subset_raster, 1) );
    ts = cell( 1, size(subset_raster, 1) );
    cstp = 1;
    for j = 1:size(subset_raster, 1)
      inds{j} = find( subset_raster(j, :) );
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
    
    raster_axs(ax_stp) = subplot( subplot_dims(1), subplot_dims(2), raster_subplot_ind );
    hold on;
    
    if ( ~current_maxes.isKey(condition_str) )
      current_max = 1;
    else
      current_max = current_maxes(condition_str);
    end
    
    current_n = sum( ~empties );
    scatter( raster_t(inds), current_max + ts - 1, 0.2, c_color );
    current_max = current_max + current_n;

    current_maxes(condition_str) = current_max + 20;
    
    ylim( raster_axs(ax_stp), raster_ylim );
    xlim( raster_axs(ax_stp), raster_xlim );
    
    title( title_str );
    
    ax_stp = ax_stp + 1;
  end
  
  lims = arrayfun( @(x) get(x, 'ylim'), psth_axs, 'un', false );
  lims = cell2mat( lims(:) );
  psth_y_lims = [ min(lims(:, 1)), max(lims(:, 2)) ];
  arrayfun( @(x) set(x, 'ylim', psth_y_lims), psth_axs );
  
  arrayfun( @(x) plot(x, [0; 0], psth_y_lims(:), 'k--'), psth_axs );
  arrayfun( @(x) plot(x, [0; 0], raster_ylim(:), 'k--'), raster_axs );
  
  line_keys = lines.keys();
  line_handles = cellfun( @(x) lines(x), line_keys, 'un', false );
  line_handles = [ line_handles{:} ];

  legend( line_handles, line_keys );
  
  full_save_p = fullfile( save_plot_p, c_drug, c_epoch, c_region );
  
  shared_utils.io.require_dir( full_save_p );
  
  fname = strjoin( flat_uniques(plt_psth, union(figs_are, 'channel')), '_' );
  full_fname = fullfile( full_save_p, fname );
  shared_utils.plot.save_fig( fig, full_fname, {'epsc', 'fig', 'png'}, true );      
end

end