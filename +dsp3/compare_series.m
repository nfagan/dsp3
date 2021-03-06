function compare_series(axs, inds, data, p_func, varargin)

%   COMPARE_SERIES -- Plot points of significant difference between 
%     line series.
%
%     dsp3.compare_series( axs, inds, data, p_func ); tests, for each
%     column of two-dimensional `data`, whether subsets of that column of 
%     `data` are significantly different, and plots a star (*) if so.
%
%     `axs` is an array of axes handles. `inds` is a cell array the same
%     size as `axs`. Each element of `inds` is itself a cell array, whose
%     elements are index vectors identifying subsets of rows of `data` to 
%     compare. `p_func` is a handle to a function that accepts a set of
%     these subsets and returns a p value. By default, 3 p-value thresholds
%     are tested: [0.05, 0.01, and 0.001], and a different color is 
%     assigned to each one.
%
%     dsp3.compare_series( ..., 'name', value ) specifies additional
%     'name', value paired arguments. These include:
%
%       - 'p_levels' (double) -- Vector of p-value thresholds. Each
%         threshold will be associated with a different color. Default is
%         [0.05, 0.01, 0.001].
%       - 'x' (double) -- Vector of values with the same number of elements
%         as `data` against which significant points will be plotted.
%         Default is  1:size(data, 2);
%       - 'color_func' (function_handle) -- Handle to a function that
%         generates a matrix of colors to associate with each p-value
%         threshold. Should return an Mx3 matrix where M is the number of p
%         value thresholds. Default is @hsv.
%       - 'post_hoc_func' (function_handle) -- Handle to a function that
%         receives a vector of calculated p-values and returns a vector the
%         same size, whose values may be modified by e.g. an fdr correction. 
%         Defaults to a function that simply returns its input unmodified, 
%         meaning that p-values are uncorrected by default.
%       - 'fig' (matlab.ui.Figure) -- Handle to the figure in which `axs`
%         reside. If specified, additional legend entries that would
%         normally be added for each plotted point will be removed cleanly.
%
%     See also plotlabeled, plotlabeled.lines

defaults = struct();
defaults.p_levels = [0.05, 0.01, 0.001];
defaults.x = 1:size(data, 2);
defaults.color_func = @hsv;
defaults.post_hoc_func = @(x) x;
defaults.fig = [];

params = dsp3.parsestruct( defaults, varargin );

validateattributes( axs, {'matlab.graphics.axis.Axes'}, {}, mfilename, 'axes' );
validateattributes( inds, {'cell'}, {'numel', numel(axs)}, mfilename, 'indices' );

p_levels = sort( params.p_levels, 'ascend' );
p_colors = params.color_func( numel(p_levels) );

x = params.x;
fig = params.fig;

if ( ~isempty(fig) )
  legs = findobj( fig, 'type', 'legend' );
  num_initial_leg_entries = arrayfun( @(x) numel(x.String), legs );
else
  legs = [];
end

cols = size( data, 2 );
ps = nan( 1, cols );

for i = 1:numel(inds)
  subset_inds = inds{i};
  vars = cellfun( @(x) rowref(data, x), subset_inds, 'un', 0 );
  ax = axs(i);
  
  for j = 1:cols
    ref_vars = cellfun( @(x) dimref(x, j, 2), vars, 'un', 0 );
    ps(j) = p_func( ref_vars{:} );
  end
  
  ps = params.post_hoc_func( ps );
  
  for j = 1:cols
    p_ind = find( ps(j) < p_levels, 1, 'first' );
    
    if ( ~isempty(p_ind) )
      set( ax, 'nextplot', 'add' );
      h = plot( ax, x(j), max(get(ax, 'ylim')), 'k*' );
      set( h, 'color', p_colors(p_ind, :) );
    end
  end
  
  ps(:) = nan;
end

% Remove additional legend entries if fig was provided and entries 
% were auto-added.
for i = 1:numel(legs)
  legs(i).String = legs(i).String(1:num_initial_leg_entries(i));
end

end