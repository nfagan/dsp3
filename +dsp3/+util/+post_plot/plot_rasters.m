function plot_rasters(rasters, fig, post_plot_inputs)

fig_ind = dsp3.util.post_plot.indices( post_plot_inputs{:} );
line_outs = dsp3.util.post_plot.plot_func_outputs( post_plot_inputs{:} );
axs = line_outs{1};
hs = line_outs{2};
inds = line_outs{3};

fig_rasters = rasters(fig_ind);

add_rasters( fig, axs, hs, inds, fig_rasters );

end

function add_rasters(fig, axs, hs, inds, rasters)

set( 0, 'currentfigure', fig );
visibility = get( fig, 'visible' );
clf( fig );
set( fig, 'visible', visibility );

marker_size = 3;
shared_utils.plot.prevent_legend_autoupdate( fig );

for i = 1:numel(axs)
  lims = get( axs(i), 'ylim' );
  
  use_ax = subplot( size(axs, 1), size(axs, 2), i );
  ylim( use_ax, lims );
  frac = 1;
  
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