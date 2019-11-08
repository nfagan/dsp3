function [figs, axs, f_inds] = grouped_hist(data, labels, fcats, gcats, pcats, varargin)

assert_ispair( data, labels );
validateattributes( data, {'double'}, {'column'}, mfilename, 'data' );

defaults = struct();
defaults.mask = rowmask( labels );
defaults.plot_inputs = {};
defaults.add_summary_line = true;
defaults.add_summary_text = true;
defaults.summary_func = @nanmedian;
defaults.summary_print_func = @(x) sprintf('M = %0.3f', x);
defaults.y_lims = [];

params = dsp3.parsestruct( defaults, varargin );

f_inds = findall_or_one( labels, fcats, params.mask );
all_axs = cell( numel(f_inds), 1 );
figs = gobjects( numel(f_inds), 1 );

for idx = 1:numel(f_inds)  
  fig = figure(idx);
  clf( fig );
  
  [p_inds, p_c] = findall( labels, pcats, f_inds{idx} );
  p_labs = strrep( fcat.strjoin(p_c, ' | '), '_', ' ' );

  shape = plotlabeled.get_subplot_shape( numel(p_inds) );
  axs = cell( numel(p_inds), 1 );

  for i = 1:numel(p_inds)
    ax = subplot( shape(1), shape(2), i );
    hold( ax, 'off' );
    [g_inds, g_c] = findall( labels, gcats, p_inds{i} );
    g_labs = strrep( fcat.strjoin(g_c, ' | '), '_', ' ' );

    hist_hs = gobjects( numel(g_inds), 1 );
    line_hs = gobjects( numel(g_inds), 1 );

    for j = 1:numel(g_inds)
      subset = data(g_inds{j});
      hist_hs(j) = histogram( ax, subset, params.plot_inputs{:} );
      hold( ax, 'on' );

      if ( ~isempty(params.y_lims) )
        ylim( ax, params.y_lims );
      end

      if ( params.add_summary_line )
        summary = params.summary_func( subset );
        line_hs(j) = shared_utils.plot.add_vertical_lines( ax, summary );

        if ( params.add_summary_text )
          text( ax, summary, max(get(ax, 'ylim')), params.summary_print_func(summary) );
        end
      end
    end

    axs{i} = ax;
    leg_h = legend( hist_hs, g_labs );
    colors = get( ax, 'colororder' );

    if ( params.add_summary_line )
      for j = 1:numel(g_inds)
        set( line_hs(j), 'color', colors(j, :) );
      end
    end

    title( ax, p_labs(:, i) );
  end
  
  all_axs{idx} = vertcat( axs{:} );
  figs(idx) = fig;
end

axs = vertcat( all_axs{:} );

end