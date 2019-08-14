function [figs, all_axs, all_labs, fig_I] = multi_spectra(data, labels, f, t, fcats, pcats, varargin)

%   MULTI_SPECTRA -- Plot multiple figures' worth of spectrograms.
%
%     figs = dsp3.multi_spectra( data, labels, f, t, fcats, pcats );
%     generates multiple figures for each combination of labels in `fcats`
%     categories. Each figure has panels drawn from combinations of labels
%     in `pcats` categories. Combinations are generated from the fcat
%     object `labels`, which must have the same number of rows as `data`.
%
%     figs is an array of handles to the generated figures.
%
%     [..., axs] = dsp3.multi_spectra(...) also returns a vector of axes
%     handles to all axes in all `figs`.
%
%     [..., labs] = dsp3.multi_spectra(...) also returns a cell array of
%     label subsets, one for each element in `figs`.
%
%     [..., fig_I] = dsp3.multi_spectra(...) also returns a cell array of
%     index vectors, one for each element in `figs`, identifyig 
%
%     See also plotlabeled, fcat

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