defaults = dsp3.make.defaults.summarized_coherence();
defaults.summary_spec = { 'days', 'regions', 'channels', 'administration', 'outcomes', 'trialtypes' };

dsp3.save_summarized_coherence_from_original_lfp( 'targOn', defaults, 'overwrite', true );
dsp3.save_summarized_coherence_from_original_lfp( 'targAcq', defaults, 'overwrite', true );

%%

defaults = dsp3.make.defaults.summarized_psd();
defaults.summary_spec = { 'days', 'regions', 'channels', 'administration', 'outcomes', 'trialtypes' };

% event_name = 'rwdOn-150-cc';
event_name = 'cueOn-150-cc';

dsp3.save_psd_from_original_lfp( event_name );
dsp3.save_summarized_psd( event_name, defaults );

%%

targ_event_name = 'rwdOn-150-cc';
base_event_name = 'cueOn-150-cc';

results = dsp3.save_per_trial_norm_psd( targ_event_name, base_event_name );

%%

defaults = dsp3.make.defaults.summarized_psd();
defaults.summary_spec = { 'days', 'regions', 'channels', 'administration', 'outcomes', 'trialtypes' };

targ_results = dsp3.save_summarized_norm_psd( 'targAcq-150-cc', defaults );
rwd_results = dsp3.save_summarized_norm_psd( 'rwdOn-150-cc', defaults );
%%