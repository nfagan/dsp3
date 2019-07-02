function results = save_summarized_coherence_from_original_lfp(event_name, varargin)

inputs = 'original_per_trial_coherence';
output = 'original_summarized_coherence';

results = dsp3.save_summarized_coherence( event_name, inputs, output, varargin );

end