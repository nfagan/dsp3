function dsp3_save_summarized_psd(varargin)

summary_spec = { 'days', 'regions', 'channels', 'administration', 'outcomes', 'trialtypes' };

psd_defaults = dsp3.make.defaults.summarized_psd();
psd_defaults.summary_spec = summary_spec;

params = dsp3.parsestruct( psd_defaults, varargin );

dsp3.save_summarized_psd( 'targAcq-150-bipolar-derivation-reference' ...
  , params ...
  , 'input_subdir', 'per_trial_psd' ...
  , 'output_subdir', 'summarized_psd' ...
);

end