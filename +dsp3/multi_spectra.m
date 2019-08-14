function [figs, all_axs, all_labs, fig_I] = multi_spectra(data, labels, f, t, fcats, pcats, varargin)

%   MULTI_SPECTRA -- Plot multiple figures' worth of spectrograms.
%
%     figs = dsp3.multi_spectra( data, labels, f, t, fcats, pcats );
%     generates multiple figures of spectrograms for each combination of 
%     labels in `fcats` categories. Each figure has panels drawn from 
%     combinations of labels in `pcats` categories. Combinations are 
%     generated from the fcat object `labels`, which must have the same 
%     number of rows as `data`. `f` is a vector with the same number of
%     elements as `data` has columns, identifying frequencies of `data`;
%     `t` is a vector with the same number of elements as `data` has 3-d
%     slices, identifying time-points of `data`. `figs` is an array of 
%     handles to the generated figures.
%
%     [..., axs] = dsp3.multi_spectra(...) also returns a vector of axes
%     handles to all axes in all `figs`.
%
%     [..., labs] = dsp3.multi_spectra(...) also returns a cell array of
%     label subsets, one for each element in `figs`.
%
%     [..., fig_I] = dsp3.multi_spectra(...) also returns a cell array of
%     index vectors, one for each element in `figs`, identifyig the subset
%     of rows of `data` and `labels` present in each figure.
%
%     dsp3.multi_spectra( ..., 'name', value ) specifies additional 
%     name-value paired inputs. Valid inputs are:
%
%       - 'mask' (double, uint64) -- Applies a mask to the data and labels
%         so that combinations are restricted to the rows identified by the
%         mask.
%       - 'pl' (plotlabeled) -- Handle to a plotlabeled object to use to
%         generate spectra. By default, a new plotlabeled object will be
%         created for each figure.
%       - 'f_mask' (double, logical) -- Mask vector used to select
%       	elements of `data` in the frequency (2nd) dimension. Defaults to
%       	all slices of `data`.
%       - 't_mask' (double, logical) -- Mask vector used to select elements
%         of `data` in the time (3rd) dimension. Defaults to all slices of
%         `data`.
%       - 'match_limits' (logical) -- True if color limits should be
%         matched across all figures and axes. Default is false.
%       - 'configure_pl_func' (function_handle) -- Handle to a function
%         that accepts a plotlabeled object as an input and returns no
%         outputs. You can pass in a custom function handle to
%         pre-configure the object before generating spectra.
%       - 'c_lims' (double) -- 2-element vector specifying axes color
%         limits.
%
%     See also plotlabeled, plotlabeled.imagesc,
%     plotlabeled.make_spectrogram, fcat

assert_ispair( data, labels );

defaults = struct();
defaults.mask = rowmask( labels );
defaults.pl = [];
defaults.f_mask = true( size(f) );
defaults.t_mask = true( size(t) );
defaults.match_limits = false;
defaults.configure_pl_func = @(pl) 1;
defaults.c_lims = [];

params = dsp3.parsestruct( defaults, varargin );

fig_I = findall( labels, fcats, params.mask );
figs = gobjects( size(fig_I) );
all_axs = cell( size(fig_I) );
all_labs = cell( size(fig_I) );

plt_f = f(params.f_mask);
plt_t = t(params.t_mask);

for i = 1:numel(fig_I)
  fig_dat = data(fig_I{i}, params.f_mask, params.t_mask);
  fig_labs = prune( labels(fig_I{i}) );
  
  if ( isempty(params.pl) )
    pl = plotlabeled.make_spectrogram( plt_f, plt_t );
    pl.sort_combinations = true;
  else
    pl = params.pl;
  end
  
  pl.fig = figure(i);
  pl.c_lims = params.c_lims;
  
  params.configure_pl_func( pl );
  
  all_axs{i} = pl.imagesc( fig_dat, fig_labs, pcats );
  figs(i) = pl.fig;
  all_labs{i} = fig_labs;
  
  shared_utils.plot.fseries_yticks( all_axs{i}, round(flip(plt_f)), 5 );
  shared_utils.plot.tseries_xticks( all_axs{i}, plt_t, 5 );
end

all_axs = vertcat( all_axs{:} );

if ( params.match_limits )
  shared_utils.plot.match_clims( all_axs );
end

end