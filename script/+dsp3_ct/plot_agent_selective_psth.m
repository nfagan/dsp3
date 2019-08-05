function plot_agent_selective_psth(targ_psth, targ_rasters, targ_labels, t, varargin)

defaults = dsp3.get_common_plot_defaults( dsp3.get_common_make_defaults() );
params = dsp3.parsestruct( defaults, varargin );

make_plot( targ_psth, targ_rasters, targ_labels', t, params );

end

function make_plot(psth, rasters, labels, t, params)

assert_ispair( psth, labels );
assert_ispair( rasters, labels );

mask = fcat.mask( labels ...
  , @findnone, 'errors' ...
  , @find, {'choice'} ...
  , @find, 'unit_uuid__213' ...
);

[unit_I, unit_C] = findall( labels, {'unit_uuid', 'region'}, mask );

for i = 1:numel(unit_I)
  reg = unit_C{2, i};
  
  smooths = [7, 10];
  
  for j = 1:numel(smooths)
    pl = plotlabeled.make_common();
    pl.fig = figure(j);
    pl.x = t(1, :);
    pl.group_order = { 'self', 'both', 'other', 'none' };
    pl.add_smoothing = true;
    pl.smooth_func = @(x) smooth( x, smooths(j) );
    pl.add_errors = false;

    gcats = { 'outcomes' };
    pcats = { 'agent_selectivity', 'unit_uuid', 'region' };

    pltdat = psth(unit_I{i}, :);
    pltlabs = labels(unit_I{i});
    plt_rasters = rasters(unit_I{i});

    [axs, hs, inds] = pl.lines( pltdat, pltlabs, gcats, pcats );
    
    add_rasters( axs, hs, inds, plt_rasters );
    prefix = sprintf( 'smooth_%d', smooths(j) );
    
    if ( params.do_save )
      plot_p = get_plot_p( params, reg );
      shared_utils.plot.fullscreen( gcf );
      dsp3.req_savefig( gcf, plot_p, prune(pltlabs), pcats, prefix );
    end
  end
end

end

function add_rasters(axs, hs, inds, rasters)

%%
frac = 0.1;
marker_size = 3;
shared_utils.plot.prevent_legend_autoupdate( gcf );

for i = 1:numel(axs)
  h = hs{i};
  ind = inds{i};
  
  shared_utils.plot.hold( axs(i), 'on' );
  
  lims = get( axs(i), 'ylim' );
  
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
    
%     xs = get( axs(i), 'xlim' );
%     unique_ys = unique( ys );
%     for k = 1:numel(unique_ys)
%       h_test = plot( xs, [unique_ys(k), unique_ys(k)], 'k' );
%       set( h_test, 'linewidth', 0.001 );
%       set( h_test, 'color', get(h(j), 'color') );
%     end
    
    h_scatter = scatter( axs(i), ts, ys, marker_size );
    set( h_scatter, 'markerfacecolor', get(h(j), 'color') );
    set( h_scatter, 'markeredgecolor', get(h(j), 'color') );
    
    stp = stp + numel( subset_raster );
  end
end

end

function plot_p = get_plot_p(params, varargin)

plot_p = fullfile( dsp3.dataroot(params.config), 'plots' ...
  , 'cell_type_agent_specificity', dsp3.datedir, 'psth', params.base_subdir, varargin{:} );

end

