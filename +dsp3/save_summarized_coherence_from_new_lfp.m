function results = save_summarized_coherence_from_new_lfp(event_name, varargin)

inputs = 'per_trial_coherence';
output = 'summarized_coherence';

results = dsp3.save_summarized_coherence( event_name, inputs, output, varargin );

end