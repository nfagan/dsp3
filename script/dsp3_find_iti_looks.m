function outs = dsp3_find_iti_looks(varargin)

defaults = dsp3.get_common_make_defaults();
defaults.consolidated = [];
defaults.fix_params = bfw.make.defaults.raw_fixations;
defaults.rois = dsp3.picto_gaze_rois();
defaults.look_back = -2.5;
defaults.look_ahead = 0;
defaults.require_fixation = true;

inputs = { 'gaze/x', 'gaze/y', 'gaze/t' };

[params, runner] = dsp3.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

consolidated = params.consolidated;

if ( isempty(consolidated) )
  consolidated = dsp3.get_consolidated_data( params.config );
end

event_ts = consolidated.events.data;
event_labels = fcat.from( consolidated.events.labels );
event_key = consolidated.event_key;

results = runner.run( @main, event_ts, event_labels, event_key, params );
outputs = shared_utils.pipeline.extract_outputs_from_results( results );

if ( isempty(outputs) )
  outs = struct();
  outs.labels = fcat();
  outs.bottle_starts = {};
  outs.bottle_durations = {};
  outs.monkey_starts = {};
  outs.monkey_durations = {};
else
  outs = shared_utils.struct.soa( outputs );
end

end

function outs = main(files, event_ts, event_labels, event_key, params)

files = shared_utils.general.map2struct( files );
num_trials = rows( files.x.data );

gaze_labels = files.t.labels;
match_evt_ind = find( event_labels, combs(gaze_labels, 'days') );

assert( numel(match_evt_ind) == num_trials, 'Trial mismatch b/w events + gaze.' );

fix_params = params.fix_params;

fix_on_ts = event_ts(match_evt_ind, event_key('fixOn'));
fix_on_ts(fix_on_ts == 0) = nan;

roi_names = fieldnames( params.rois );

in_range_starts = struct();
in_range_durs = struct();

for i = 1:numel(roi_names)
  in_range_starts.(roi_names{i}) = cell( num_trials, 1 );
  in_range_durs.(roi_names{i}) = cell( num_trials, 1 );
end

for i = 1:num_trials-1
  t_trial = files.t.data(i, :);
  max_t = find( t_trial == 0, 1 );
  
  if ( ~isempty(max_t) && max_t ~= 1 )
    assert( t_trial(1) == -1, 'Expected first time point to be -1; was %0.3f', t_trial(1) );

    t_trial = t_trial(2:max_t-1);
    x_trial = files.x.data(i, 2:max_t-1);
    y_trial = files.y.data(i, 2:max_t-1);

    isi = nanmedian( diff(t_trial) );

    if ( params.require_fixation )
      is_fix = bfw.fixation.eye_mmv_is_fixation( x_trial, y_trial, t_trial, fix_params );
    else
      is_fix = true( size(x_trial) );
    end

    t_trial = t_trial + fix_on_ts(i);
    % looking back from fix on of next trial
    min_t = fix_on_ts(i+1) + params.look_back;
    max_t = fix_on_ts(i+1) + params.look_ahead;

    for j = 1:numel(roi_names)
      rect = params.rois.(roi_names{j});    

      is_ib = bfw.bounds.rect( x_trial, y_trial, rect ) & is_fix;

      [starts, num_samples] = fixations_in_time_range( t_trial, is_ib, min_t, max_t );

      in_range_starts.(roi_names{j}){i} = starts;
      in_range_durs.(roi_names{j}){i} = num_samples * isi;
    end
  end
end

outs = struct();
outs.labels = gaze_labels;
outs.bottle_starts = in_range_starts.bottle;
outs.bottle_durations = in_range_durs.bottle;
outs.event_ind = match_evt_ind;

outs.monkey_starts = in_range_starts.monkey;
outs.monkey_durations = in_range_starts.monkey;

end

function [ts, durs] = fixations_in_time_range(t_trial, ib, min_t, max_t)

[starts, durs] = shared_utils.logical.find_all_starts( ib );
ts = t_trial(starts);

in_range_starts = ts >= min_t & ts <= max_t;

ts = ts(in_range_starts);
durs = durs(in_range_starts);

end