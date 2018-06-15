dsp3.xcorr( ...
    'overwrite',            true ...
  , 'include_traces',       true ...
  , 'use_envelope',         false ...
  , 'filt_func',            @dsp3.zpfilter ...
  , 'xcorr_scale_opt',      'none' ...
  , 'output_subdir',        'across_filtered' ...
  , 'shuffle',              false ...
  , 'per_trial',            false ...
  , 'across_trials_type',   'nondrug' ...
  , 'ts',                   [-250, 0] ...
);

%%