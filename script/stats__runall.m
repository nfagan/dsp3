function stats__runall(varargin)

defaults = dsp3.get_behav_stats_defaults();

params = dsp3.parsestruct( defaults, varargin );

%%  p correct

stats__percent_correct( params );

%%  rt

stats__rt( params );

%%  gaze

stats__gaze( params );

%%  preference

stats__pref( params );

%%  pref over time

plot_pref_index_over_time( params );

%%  coh

stats__proanti_coh( params );