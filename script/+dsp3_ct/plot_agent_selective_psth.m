function plot_agent_selective_psth(targ_psth, targ_rasters, targ_labels, t, varargin)

defaults = dsp3.get_common_plot_defaults( dsp3.get_common_make_defaults() );
defaults.selectivity_subdir = 'cell_type_agent_specificity';
defaults.selectivity_cat = 'agent_selectivity';
defaults.rasters_in_separate_figure = false;

params = dsp3.parsestruct( defaults, varargin );

make_plot( targ_psth, targ_rasters, targ_labels', t, params );

end

function make_plot(psth, rasters, labels, t, params)

assert_ispair( psth, labels );
assert_ispair( rasters, labels );

mask = fcat.mask( labels ...
  , @findnone, 'errors' ...
  , @find, {'choice'} ...
);

[unit_I, unit_C] = findall( labels, {'unit_uuid', 'region'}, mask );

for i = 1:numel(unit_I)
  reg = unit_C{2, i};
  
  smooths = [7, 10];
  
  for j = 1:numel(smooths)
    pl_fig = figure(1);
    clf( pl_fig );
    
    pl = plotlabeled.make_common();
    pl.fig = figure(1);
    pl.x = t(1, :);
    pl.group_order = { 'self', 'both', 'other', 'none' };
    pl.add_smoothing = true;
    pl.smooth_func = @(x) smooth( x, smooths(j) );
    pl.add_errors = false;

    gcats = { 'outcomes' };
    pcats = { params.selectivity_cat, 'unit_uuid', 'region' };

    pltdat = psth(unit_I{i}, :);
    pltlabs = labels(unit_I{i});
    plt_rasters = rasters(unit_I{i});

    [axs, hs, inds] = pl.lines( pltdat, pltlabs, gcats, pcats );
    
    raster_fig = add_rasters( axs, hs, inds, plt_rasters, params.rasters_in_separate_figure );
    
    prefix = sprintf( 'smooth_%d', smooths(j) );
    line_prefix = sprintf( 'line-%s', prefix );
    raster_prefix = sprintf( 'raster-%s', prefix );
    
    if ( params.do_save )
      plot_p = get_plot_p( params, reg );
      shared_utils.plot.fullscreen( pl.fig );
      dsp3.req_savefig( pl.fig, plot_p, prune(pltlabs), pcats, line_prefix );
      
      if ( params.rasters_in_separate_figure )
        shared_utils.plot.fullscreen( raster_fig );
        dsp3.req_savefig( raster_fig, plot_p, pltlabs, pcats, raster_prefix );
      end
    end
  end
end

end

function use_fig = add_rasters(axs, hs, inds, rasters, separate_fig)

if ( separate_fig )
  use_fig = figure(2);
  clf( use_fig );
else
  use_fig = gcf();
end

marker_size = 3;
shared_utils.plot.prevent_legend_autoupdate( use_fig );

for i = 1:numel(axs)
  lims = get( axs(i), 'ylim' );
  
  if ( separate_fig )
    use_ax = subplot( size(axs, 1), size(axs, 2), i );
    ylim( use_ax, lims );
    frac = 1;
  else
    frac = 0.1;
    use_ax = axs(i);
  end
  
  h = hs{i};
  ind = inds{i};
  
  shared_utils.plot.hold( use_ax, 'on' );
  
  full_inds = cellfun( @(x) cellfun(@(y) ~isempty(y), rasters(x)), ind, 'un', 0 );
  tot_trials = sum( cellfun(@sum, full_inds) );
  amt = diff( lims ) / tot_trials * frac;
  stp = 0;
  
  ind = cellfun( @(x, y) x(y), ind, full_inds, 'un', 0 );
  
  for j = 1:numel(ind)
    subset_raster = rasters(ind{j});
    
    ys = lims(2) - reshape( ((0:numel(subset_raster)-1) + stp) .* amt, [], 1 );
    ys = cat_expanded( 1, arrayfun(@(x, y) repmat(x, size(y{1})), ys, subset_raster, 'un', 0) );
    ts = vertcat( subset_raster{:} );
    
    h_scatter = scatter( use_ax, ts, ys, marker_size );
    set( h_scatter, 'markerfacecolor', get(h(j), 'color') );
    set( h_scatter, 'markeredgecolor', get(h(j), 'color') );
    
    stp = stp + numel( subset_raster );
  end
end

end

function plot_p = get_plot_p(params, varargin)

plot_p = fullfile( dsp3.dataroot(params.config), 'plots' ...
  , params.selectivity_subdir, dsp3.datedir, 'psth', params.base_subdir, varargin{:} );

end

