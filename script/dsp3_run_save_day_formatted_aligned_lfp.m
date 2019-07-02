function dsp3_run_save_day_formatted_aligned_lfp(varargin)

events = { 'targAcq', 'targOn' };

defaults = dsp3.get_common_make_defaults();

common_inputs = dsp3.parsestruct( defaults, varargin );
common_inputs.is_parallel = true;
common_inputs.overwrite = true;

label_filepath = fullfile( dsp3.dataroot(common_inputs.config), 'constants', 'cc_targacq_trial_labels.mat' );
cc_orig_targacq_labels = fcat.from( shared_utils.io.fload(label_filepath) );

for i = 1:numel(events)

% dsp3.save_aligned_lfp( ...
%   'event_name', events{i} ...
%   , 'min_t', -0.5 ...
%   , 'max_t', 0.5 ...
%   , 'window_size', 0.2 ...
%   , common_inputs ...
% );

loaded = dsp3_load_day_formatted_aligned_lfp( events{i} );

new_labels = loaded.labels';
renamecat( new_labels, 'region', 'regions' );
renamecat( new_labels, 'channel', 'channels' );

dsp3_match_cc_targacq_trial_labels( cc_orig_targacq_labels, new_labels );
loaded.labels = new_labels;

dsp3_save_day_formatted_aligned_lfp( loaded, events{i}, common_inputs.config );

end