function [figs, all_axs, all_labs] = multi_spectra(data, labels, f, t, fcats, pcats, varargin)

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