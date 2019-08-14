function dsp3_save_summarized_psd(varargin)

summary_spec = { 'days', 'regions', 'channels', 'administration', 'outcomes', 'trialtypes', 'unit_uuid' };

psd_defaults = dsp3.make.defaults.psd();
psd_defaults.summary_spec = summary_spec;

params = dsp3.parsestruct( psd_defaults, varargin );

dsp3.save_summarized_psd( 'targAcq-150-original-reference-method' ...
  , 'input_subdir', 'per_trial_psd' ...
  , params ...
);

end