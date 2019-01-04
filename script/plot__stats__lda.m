analysis_type = 'lda';

stats__lda( ...
    'underlying_measure', 'sfcoherence' ...
  , 'analysis_type', analysis_type ...
  , 'specificity','contexts' ...
  , 'do_save', true ...
  , 'base_subdir', '-250_0' ...
  , 'time_window', [-250, 0] ...
  , 'base_subdir', '' ...
);

%%  Plot over time

% start_windows = 60;
% stop_windows = 70;

analysis_type = 'lda';

start_windows = 15:10:55;
stop_windows = start_windows + 10;
% 
addtl_starts = [45, 45, 60, 15];
addtl_stops = [65, 70, 70, 25];

start_windows = [ start_windows, addtl_starts ];
stop_windows = [ stop_windows, addtl_stops ];

is_cued = true;
is_smoothed = true;

for i = 1:numel(start_windows)
  
  start = start_windows(i);
  stop = stop_windows(i);
  
  str_window = sprintf( '%d-%d', start, stop );
  base_subdir = sprintf( 'over_time_%s_hz', str_window );
  
  if ( is_cued ), base_subdir = sprintf( 'cued_%s', base_subdir ); end
  if ( is_smoothed ), base_subdir = sprintf( 'smooth_%s', base_subdir); end
  
  if ( is_smoothed )
    smooth_func = @(x) smooth(x, 5);
  else
    smooth_func = @(x) x;
  end
  
  stats__lda( ...
      'underlying_measure', 'sfcoherence' ...
    , 'analysis_type', analysis_type ...
    , 'smooth_func', smooth_func ...
    , 'specificity', 'contexts' ...
    , 'do_save', true ...
    , 'over_frequency', false ...
    , 'freq_window', [start, stop] ...
    , 'base_subdir', base_subdir ...
    , 'xlims', [-350, 350] ...
    , 'is_cued', is_cued ...
  );
  
end

%%  Plot over freq

is_cued = true;
is_smoothed = true;
analysis_type = 'lda';

start_windows = [ -250, -50 ];
stop_windows = [ 0, 50 ];

for i = 1:numel(start_windows)
  
  start = start_windows(i);
  stop = stop_windows(i);
  
  str_window = sprintf( '%d-%d', start, stop );
  base_subdir = sprintf( 'over_freq_%s_ms', str_window );
  
  if ( is_cued ), base_subdir = sprintf( 'cued_%s', base_subdir ); end
  if ( is_smoothed ), base_subdir = sprintf( 'smooth_%s', base_subdir ); end
  
  if ( is_smoothed )
    smooth_func = @(x) smooth(x, 5);
  else
    smooth_func = @(x) x;
  end
  
  stats__lda( ...
      'underlying_measure', 'sfcoherence' ...
    , 'analysis_type', analysis_type ...
    , 'specificity', 'contexts' ...
    , 'do_save', true ...
    , 'over_frequency', true ...
    , 'time_window', [start, stop] ...
    , 'base_subdir', base_subdir ...
    , 'is_cued', is_cued ...
  );
  
end