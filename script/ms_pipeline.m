%%

shared_inputs = { 'overwrite', true, 'append', true };

%%

dsp3.save_consolidated_data();

%%

dsp3.save_ms_units( shared_inputs{:} );

%%

dsp3.save_unit_containers( shared_inputs{:} );
dsp3.save_units_to_picto_time( shared_inputs{:} );

%%

dsp3.save_per_trial_psth( shared_inputs{:} ...
  , 'epochs', { 'cueOn' } ...
  , 'look_back', -0.15 ...
  , 'look_ahead', 0 ...
  , 'bin_size', 0.01 ...
);

%%

dsp3.save_summarized_psth( shared_inputs{:} ...
  , 'alias', 'standard' ...
  , 'allow_new_alias', false ...
  , 'within',  { 'unit_uuid', 'outcomes', 'trialtypes', 'days' } ...
  , 'summary_func', @rowops.nanmean ...
);

%%

