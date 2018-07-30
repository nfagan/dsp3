function stats__runall(varargin)

defaults = dsp3.get_behav_stats_defaults();

defaults.funcs = { ...
    @stats__percent_correct ...
  , @stats__rt ...
  , @stats__gaze ...
  , @stats__pref ...
  , @plot_pref_index_over_time ...
  , @stats__proanti_coh ...
};

params = dsp3.parsestruct( defaults, varargin );

funcs = params.funcs;

for i = 1:numel(funcs)
  try
    funcs{i}( params );
  catch err
    warning( err.message );
  end
end

end