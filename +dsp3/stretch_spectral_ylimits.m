function stretch_spectral_ylimits(axs, freqs, lim0, lim1, is_flipped)

for i = 1:numel(axs)
  ax = axs(i);
  
  ytick = get( ax, 'ytick' );
  
  xlims = get( ax, 'xlim' );
  xtick = linspace( xlims(1), xlims(2), 5 );
  
  if ( numel(ytick) ~= numel(freqs) )
    warning( 'Frequencies do not match y ticks.' );
    continue;
  end
  
  yvals = freqs(yticks);
  
  interval_val = abs( mean(diff(yvals)) );
  interval_tick = abs( mean(diff(ytick)) );
  
  min_y = min( yvals );
  max_y = max( yvals );
  min_ytick = min( ytick );
  max_ytick = max( ytick );
  
  offset0 = min_y - lim0;  
  offset1 = lim1 - max_y;
  
  frac_offset0 = offset0 / interval_val;
  frac_offset1 = offset1 / interval_val;
  
  if ( is_flipped )
    y0 = max_ytick + frac_offset0 * interval_tick;
    y1 = min_ytick - frac_offset1 * interval_tick;
  else
    y0 = min_ytick - frac_offset0 * interval_tick;
    y1 = max_ytick + frac_offset1 * interval_tick;
  end
  
  hold( ax, 'on' );
  plot( ax, xtick, repmat(y1, size(xtick)), 'r', 'linewidth', 2 );
  plot( ax, xtick, repmat(y0, size(xtick)), 'r', 'linewidth', 2 );
  
  ylim( ax, sort([y0, y1]) );
  
  set( ax, 'yticklabel', '' );
  
  set( ax, 'ytick', [] );
end

end