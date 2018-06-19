dsp3.save_zscored_measure( ...
    'overwrite',      true ...
  , 'meas_type',      'coherence' ...
  , 'epoch',          'targacq' ...
  , 'manipulation',   'pro_v_anti' ...
  , 'drug_type',      'nondrug' ...
);

%%

dsp3.save_at_measure( ...
    'meas_type',  'coherence' ...
  , 'epoch',      'targacq' ...
  , 'drug_type',  'nondrug' ...
);
    