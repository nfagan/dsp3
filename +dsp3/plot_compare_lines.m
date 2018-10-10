function axs = plot_compare_lines(data, labels, gcats, pcats, varargin)

%   PLOT_COMPARE_LINES -- Plot data for combinations of labels, comparing 
%     groups for significance.
%
%     axs = ... plot_compare_lines( data, labels, gcats, pcats ); plots
%     grouped subsets of `data` as lines, drawing groups from combinations 
%     of labels in `gcats` groups, separately for each combination of 
%     labels in `pcats` categories, and testing groups for significant 
%     differences between them. `axs` is an array of axes handles to 
%     subplots in the current figure.
%
%     axs = ... plot_compare_lines( ..., 'name', value ); specifies various
%     optional 'name', value paired arguments. These include:
%
%       - 'alpha', (double) |SCALAR|: Significance threshold.
%       - 'mask', (uint64): Mask to select rows of `data` and `labels`.
%       - 'smooth_func', (function_handle): Handle to a function that takes
%       a column vector `x` and returns a vector the same size as `x`. The
%       output of this function will be plotted, but statistics are always
%       based on the non-smoothed input.
%       - 'correction_func', (function_handle): Handle to a function that
%       takes a vector of p-values `p` and returns a vector the same size
%       as `p`. By default, an fdr correction is applied.
%       - 'compare_func', (function_handle): Handle to a function that
%       receives N data vectors `v1`, `v2`, ... `vn` of potentially 
%       different lengths, where `N` is equal to the number of groups
%       (lines), and returns a scalar p-value of their difference. Defaults
%       to a modified `ttest2` function that returns only the p-value of
%       the test between two groups.
%       - 'summary_func', (function_handle): Handle to a function that
%       receives a data matrix `x` and returns a column vector of length
%       `size(x, 2)`, representing (e.g.) the average or median of each
%       column of `x`. Defaults to `(x) nanmean(x, 1)`.
%       - 'error_func', (function_handle): Handle to a function that
%       receives a data matrix `x` and returns a column vector of length
%       `size(x, 2)` representing the error of each column of `x`. Defaults
%       to `@plotlabeled.nansem`.
%       - 'x', (double): Vector of length `size(data, 2)`, against which
%       y-data are to be plotted. Defaults to `1:size(data, 2)`.
%
%     See also fcat, plotlabeled, ttest2
%
%     IN:
%       - `data` (double)
%       - `labels` (fcat)
%       - `gcats` (cell array of strings, char)
%       - `pcats` (cell array of strings, char)
%       - `varargin` ('name', value)
%     OUT:
%       - `axs` (axes)

assert_ispair( data, labels );
validateattributes( data, {'double'}, {'2d'}, 'plot_compare_lines', 'data' );

defaults = struct();
defaults.alpha = 0.05;
defaults.mask = rowmask( labels );
defaults.smooth_func = @(x) x;
defaults.correction_func = @(p) dsp3.fdr(p);
defaults.compare_func = @default_ttest2;
defaults.summary_func = @(x) nanmean(x, 1);
defaults.error_func = @plotlabeled.nansem;
defaults.x = 1:size( data, 2 );

params = shared_utils.general.parsestruct( defaults, varargin );

[I, p_c] = findall( labels, pcats, params.mask );
[I, p_c] = sort_ic( I, p_c );

shp = plotlabeled.get_subplot_shape( numel(I) );
axs = gobjects( 1, numel(I) );

for i = 1:numel(I)
  ax = subplot( shp(1), shp(2), i );
  
  [g_i, g_c] = findall( labels, gcats, I{i} );
  
  [g_i, g_c] = sort_ic( g_i, g_c );
  
  hs = gobjects( 1, numel(g_i) );
  grp_dat = cell( size(hs) );
  
  for j = 1:numel(g_i)
    dat = rowref( data, g_i{j});
    
    means = params.summary_func( dat );
    errs = params.error_func( dat );
    
    h_mean = plot( ax, params.x, params.smooth_func(means) );
    
    shared_utils.plot.hold( ax, 'on' );
    
    h_err1 = plot( ax, params.x, params.smooth_func(means + errs) );
    h_err2 = plot( ax, params.x, params.smooth_func(means - errs) );
    
    set( h_err1, 'color', get(h_mean, 'color') );
    set( h_err2, 'color', get(h_mean, 'color') );
    
    grp_dat{j} = dat;
    hs(j) = h_mean;
  end
  
  axs(i) = ax;
  
  set( gcf, 'defaultLegendAutoUpdate', 'off' );
  legend( hs, fcat.strjoin(g_c, ' | ') );
  title( fcat.strjoin(p_c(:, i), ' | ') );
  
  n_cols = size( grp_dat{1}, 2 );
  ps = zeros( 1, n_cols );
  compare_dat = cell( 1, numel(grp_dat) );

  for j = 1:n_cols
    for k = 1:numel(grp_dat)
      compare_dat{k} = grp_dat{k}(:, j);
    end
    
    ps(j) = params.compare_func( compare_dat{:} );
  end

  corrected_p = params.correction_func( ps );

  sig_p = find( corrected_p < params.alpha );
  lim = get( ax, 'ylim' );

  for j = 1:numel(sig_p)
    plot( ax, params.x(sig_p(j)), lim(2), 'k*' );
  end  
end

end

function p = default_ttest2(a, b)

[~, p, ~] = ttest2( a, b );

end

function [I, C] = sort_ic(I, C)

[~, sorted_ind] = sortrows( categorical(C') );
I = I(sorted_ind);
C = C(:, sorted_ind);

end