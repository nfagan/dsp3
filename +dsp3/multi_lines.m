function [figs, all_axs, all_labs, fig_I] = multi_lines(data, labels, fcats, gcats, pcats, varargin)

%   MULTI_LINES -- Plot multiple figures' worth of line plots.
%
%     figs = dsp3.multi_lines( data, labels, fcats, gcats, pcats );
%     generates multiple figures of line plots for each combination of 
%     labels in `fcats` categories. Each figure has panels drawn from 
%     combinations of labels in `pcats` categories, with groups drawn from
%     combinations in `gcats` categories. Combinations are generated from 
%     the fcat object `labels`, which must have the same number of rows as 
%     `data`. `figs` is an array of handles to the generated figures.
%
%     [..., axs] = dsp3.multi_lines(...) also returns a vector of axes
%     handles to all axes in all `figs`.
%
%     [..., labs] = dsp3.multi_lines(...) also returns a cell array of
%     label subsets, one for each element in `figs`.
%
%     [..., fig_I] = dsp3.multi_lines(...) also returns a cell array of
%     index vectors, one for each element in `figs`, identifyig the subset
%     of rows of `data` and `labels` present in each figure.
%
%     dsp3.multi_lines( ..., 'name', value ) specifies additional 
%     name-value paired inputs. Valid inputs are:
%
%       - 'mask' (double, uint64) -- Applies a mask to the data and labels
%         so that combinations are restricted to the rows identified by the
%         mask.
%       - 'pl' (plotlabeled) -- Handle to a plotlabeled object to use to
%         generate plots. By default, a new plotlabeled object will be
%         created for each figure.
%       - 'match_limits' (logical) -- True if y-limits should be
%         matched across all figures and axes. Default is false.
%       - 'configure_pl_func' (function_handle) -- Handle to a function
%         that accepts a plotlabeled object as an input and returns no
%         outputs. You can pass in a custom function handle to
%         pre-configure the object before generating spectra.
%       - 'y_lims' (double) -- 2-element vector specifying axes y
%         limits.
%       - 'post_plot_func' (function_handle) -- Handle to a function to be
%         called after generating one figure's worth of plots. It accepts
%         6 inputs: the current figure handle, an array of handles to axes
%         in that figure, a cell array of handles to the plotted lines, a
%         cell array of cell arrays of index vectors, the data in the
%         figure, and the labels used to generate the figure.
%
%     See also plotlabeled, plotlabeled.lines, plotlabeled.make_common, 
%     dsp3.multi_spectra, dsp3.compare_series, fcat

assert_ispair( data, labels );

defaults = struct();
defaults.mask = rowmask( labels );
defaults.pl = [];
defaults.match_limits = false;
defaults.configure_pl_func = @(pl) 1;
defaults.y_lims = [];
defaults.post_plot_func = @(f, axs, hs, inds, data, labels) 1;

params = dsp3.parsestruct( defaults, varargin );

fig_I = findall_or_one( labels, fcats, params.mask );
figs = gobjects( size(fig_I) );
all_axs = cell( size(fig_I) );
all_labs = cell( size(fig_I) );

for i = 1:numel(fig_I)
  fig_dat = data(fig_I{i}, :);
  fig_labs = prune( labels(fig_I{i}) );
  
  if ( isempty(params.pl) )
    pl = plotlabeled.make_common();
  else
    pl = params.pl;
  end
  
  pl.fig = figure(i);
  pl.y_lims = params.y_lims;
  
  params.configure_pl_func( pl );
  
  [all_axs{i}, hs, inds] = pl.lines( fig_dat, fig_labs, gcats, pcats ); 
  figs(i) = pl.fig;
  all_labs{i} = fig_labs;
  
  try
    params.post_plot_func( pl.fig, all_axs{i}, hs, inds, fig_dat, fig_labs );
  catch err
    warning( err.message );
  end
end

all_axs = vertcat( all_axs{:} );

if ( params.match_limits )
  shared_utils.plot.match_ylims( all_axs );
end

end