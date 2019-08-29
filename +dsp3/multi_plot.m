function [figs, all_axs, all_labs, fig_I, outs] = multi_plot(plot_func, data, labels, fcats, varargin)

%   MULTI_PLOT -- Plot multiple figures' worth of data.
%
%     dsp3.multi_plot( func, data, labels, fcats, ... ) generates multiple
%     figures' worth of plots using the plotlabeled method `func`. Figures
%     are generated separately for each combination of labels in `fcats`
%     categories. Additional specifiers for x-, group-, and panel-
%     categories should be provided, in accordance with the number and 
%     format expected by the plotting method.
%
%     figs = dsp3.multi_plot(...) returns an array of handles to the
%     generated figure(s).
%
%     [..., axs] = dsp3.multi_plot(...) also returns a vector of axes
%     handles to all axes in all `figs`.
%
%     [..., labs] = dsp3.multi_lines(...) also returns a cell array of
%     label subsets, one for each element in `figs`.
%
%     [..., fig_I] = dsp3.multi_lines(...) also returns a cell array of
%     index vectors, one for each element in `figs`, identifyig the subset
%     of rows of `data` and `labels` present in each figure.
%
%     dsp3.multi_plot( ..., 'name', value ) specifies additional 
%     name-value paired inputs. Valid inputs are:
%
%       - 'mask' (double, uint64) -- Applies a mask to the data and labels
%         so that combinations are restricted to the rows identified by the
%         mask.
%       - 'pl' (plotlabeled) -- Handle to a plotlabeled object to use to
%         generate plots. By default, a new plotlabeled object will be
%         created for each figure.
%       - 'match_limits' (logical) -- True if x-, y- and color-limits 
%         should be matched across all figures and axes. Default is false.
%       - 'configure_pl_func' (function_handle) -- Handle to a function
%         that accepts a plotlabeled object as an input and returns no
%         outputs. You can pass in a custom function handle to
%         pre-configure the object before generating each figure.
%       - 'x_lims' (double) -- 2-element vector specifying axes x
%         limits. Default is [];
%       - 'y_lims' (double) -- 2-element vector specifying axes y
%         limits. Default is [].
%       - 'clims' (double) -- 2-element vector specifying axes color
%         limits. Default is []. 
%       - 'plot_func_inputs' (cell array) -- Additional inputs to be passed
%         to the call to `plot_func`. Default is an empty cell array ({}).
%       - 'num_outputs_from_plot_func' (double) -- Number of outputs to
%         request from 'plot_func'. Default is 1. Alternatively, can be the
%         char vector 'all' to request all possible outputs of `plot_func`.
%       - 'post_plot_func' (function_handle) -- Handle to a function to be
%         called each time a figure is generated. It accepts at least 5 
%         inputs: a handle to the generated figure, the subset of `data` 
%         present in the figure, the subset of `labels` associated with 
%         that data, the "specificity" of the plot -- a cell array of 
%         strings containing the unique category specifiers for figures, 
%         groups, etc -- and a vector of indices into `data` identifying
%         the plotted subset. This function will additionally receive the 
%         outputs of `plot_func`, as many as were requested with 
%         'num_outputs_from_plot_func'.
%       - 'multiple_figures' (logical) -- True if every combination of
%         lables in `fcats` categories should be plotted in a separate
%         figure. Otherwise, only the current figure is used. In that case,
%         you can use `post_plot_func` to do something with (e.g., save) 
%         the figure before the next one is plotted. Default is true.
%
%     EX //
%
%     f = fcat.example();
%     d = fcat.example( 'smalldata' );
%
%     % Generate separate figures for each 'roi'. Plot each 'monkey' on the
%     % x-axis, and group by 'dose', with separate panels for each 'roi'.
%     figs = dsp3.multi_plot( @bar, d, f, 'roi', 'monkey', 'dose', 'roi' );
%
%     See also plotlabeled, fcat, dsp3.multi_spectra, dsp3.anova1,
%       dsp3.compare_series

narginchk( 5, inf );

try
  [cat_spec, varargin] = validate( plot_func, data, labels, varargin );
catch err
  throw( err );
end

defaults = struct();
defaults.mask = rowmask( labels );
defaults.pl = [];
defaults.match_limits = false;
defaults.configure_pl_func = @(pl) 1;
defaults.x_lims = [];
defaults.y_lims = [];
defaults.c_lims = [];
defaults.r_lims = [];
defaults.num_outputs_from_plot_func = 1;
defaults.plot_func_inputs = {};
defaults.post_plot_func = @(varargin) 1;
defaults.multiple_figures = true;

params = dsp3.parsestruct( defaults, varargin );

num_outputs_from_plot_func = get_num_outputs_from_plot_func( plot_func, params );
plot_func_inputs = params.plot_func_inputs;

fig_I = findall_or_one( labels, fcats, params.mask );
figs = gobjects( size(fig_I) );
all_axs = cell( size(fig_I) );
all_labs = cell( size(fig_I) );

partial_specificity = cshorzcat( cat_spec{:} );
full_specificity = csunion( fcats, partial_specificity );

for i = 1:numel(fig_I)
  fig_ind = fig_I{i};
  fig_dat = rowref( data, fig_ind );
  fig_labs = prune( labels(fig_ind) );
  
  if ( isempty(params.pl) )
    pl = plotlabeled.make_common();
  else
    pl = params.pl;
  end
  
  if ( params.multiple_figures )
    fig = figure(i);
  else
    fig = gcf();
  end
  
  pl.fig = fig;
  assign_limits( pl, params );
  params.configure_pl_func( pl );
  
  plot_func_outputs = {};
  [plot_func_outputs{1:num_outputs_from_plot_func}] = ....
    plot_func( pl, fig_dat, fig_labs, cat_spec{:}, plot_func_inputs{:} );
  
  if ( num_outputs_from_plot_func >= 1 )
    axs = plot_func_outputs{1};
  else
    axs = gobjects( 0 );
  end
  
  all_axs{i} = axs(:);
  figs(i) = pl.fig;
  all_labs{i} = fig_labs;
  
  try
    params.post_plot_func( pl.fig, fig_dat, fig_labs, full_specificity, fig_ind, plot_func_outputs{:} );
  catch err
    warning( err.message );
  end
end

all_axs = vertcat( all_axs{:} );

if ( params.match_limits )
  attempt( @() shared_utils.plot.match_xlims(all_axs) );
  attempt( @() shared_utils.plot.match_ylims(all_axs) );
  attempt( @() shared_utils.plot.match_clims(all_axs) );
  attempt( @() shared_utils.plot.match_rlims(all_axs) );
end

if ( nargout > 4 )  
  outs = struct();
  outs.full_specificity = full_specificity;
  outs.partial_specificity = partial_specificity;
end

end

function num_out = get_num_outputs_from_plot_func(plot_func, params)

num_out = params.num_outputs_from_plot_func;

if ( ischar(num_out) && strcmp(num_out, 'all') )
  mc = ?plotlabeled;
  func_name = func2str( plot_func );
  method_names = {mc.MethodList.Name};
  method_ind = strcmp( method_names, func_name );
  
  if ( nnz(method_ind) ~= 1 )
    error( 'Expected 1 method to match "%s"; instead there were %d matches.' ...
      , func_name, nnz(method_ind) );
  end
  
  num_out = numel( mc.MethodList(method_ind).OutputNames );
end

end

function assign_limits(pl, params)

pl.x_lims = params.x_lims;
pl.y_lims = params.y_lims;
pl.c_lims = params.c_lims;
pl.r_lims = params.r_lims;

end

function [cat_spec, inputs] = validate(plot_func, data, labels, inputs)

validateattributes( plot_func, {'function_handle'}, {'scalar'}, mfilename, 'plot function' );
assert_ispair( data, labels );

plot_func_name = func2str( plot_func );
[cat_spec, inputs] = parse_category_specifiers( plot_func_name, inputs );

end

function [cat_spec, inputs] = parse_category_specifiers(plot_func_name, inputs)

num_required_specifiers = plotlabeled.num_category_specifiers( plot_func_name );
num_inputs = numel( inputs );

if ( num_inputs < num_required_specifiers )
  was_str = ternary( num_inputs == 1, 'was', 'were' );
  error( ['Plot function "%s" requires %d category specifiers, but only %d' ...
    , ' %s provided.'], plot_func_name, num_required_specifiers, num_inputs, was_str );
end

cat_spec = inputs(1:num_required_specifiers);
inputs = inputs(num_required_specifiers+1:end);

end