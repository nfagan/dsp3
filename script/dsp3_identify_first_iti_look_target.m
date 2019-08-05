function outs = dsp3_identify_first_iti_look_target(varargin)

defaults = dsp3.get_common_make_defaults();
defaults.consolidated = [];
defaults.fix_params = bfw.make.defaults.raw_fixations;
defaults.rois = dsp3.picto_gaze_rois();
defaults.min_fixation_length_secs = 0.15;
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
monk_roi = params.rois.monkey;
bottle_roi = params.rois.bottle;

fix_on_ts = event_ts(:, event_key('fixOn'));
fix_on_ts(fix_on_ts == 0) = nan;

long_enough_label = 'long_enough__true';
too_short_label = 'long_enough__false';
no_look_label = 'no_look';

fix_labels = addcat( files.t.labels', {'looks_to', 'duration'} );
setcat( fix_labels, 'looks_to', no_look_label );
setcat( fix_labels, 'duration', too_short_label );

for i = 1:num_trials-1
  t_trial = files.t.data(i, :);
  max_t = find( t_trial == 0, 1 );
  
  if ( isempty(max_t) || max_t == 1 )
    continue;
  end
  
  assert( t_trial(1) == -1, 'Expected first time point to be -1; was %0.3f', t_trial(1) );
  
  t_trial = t_trial(2:max_t-1);
  x_trial = files.x.data(i, 2:max_t-1);
  y_trial = files.y.data(i, 2:max_t-1);
  
  interval_t = nanmedian( diff(t_trial) );
  min_num_samples = round( params.min_fixation_length_secs / interval_t );
  
  if ( params.require_fixation )
    is_fix = bfw.fixation.eye_mmv_is_fixation( x_trial, y_trial, t_trial, fix_params );
  else
    is_fix = true( size(x_trial) );
  end
  
  is_ib_bottle = bfw.bounds.rect( x_trial, y_trial, bottle_roi ) & is_fix;
  is_ib_monkey = bfw.bounds.rect( x_trial, y_trial, monk_roi ) & is_fix;
  
  t_trial = t_trial + fix_on_ts(i);
  
  % fix on 
  min_t = fix_on_ts(i+1) + params.look_back;
  max_t = fix_on_ts(i+1) + params.look_ahead;
  
  [fix_bottle, bottle_durs] = fixations_in_time_range( t_trial, is_ib_bottle, min_t, max_t );
  [fix_monkey, monkey_durs] = fixations_in_time_range( t_trial, is_ib_monkey, min_t, max_t );
  
  [first_bottle, bottle_ind] = min( fix_bottle );
  [first_monkey, monkey_ind] = min( fix_monkey );
  
  first_dur_bottle = bottle_durs(bottle_ind);
  first_dur_monkey = monkey_durs(monkey_ind);
  
  empty_bottle = isempty( first_bottle );
  empty_monkey = isempty( first_monkey );
  
  if ( empty_bottle && empty_monkey )
    roi_label = no_look_label;
    
  elseif ( empty_monkey )
    roi_label = 'bottle';
    
  elseif ( empty_bottle )
    roi_label = 'monkey';
    
  elseif ( first_bottle < first_monkey )
    roi_label = 'bottle';
    
  else
    roi_label = 'monkey';    
  end
  
  if ( strcmp(roi_label, 'bottle') )
    duration_label = ternary( first_dur_bottle >= min_num_samples, long_enough_label, too_short_label );
    
  elseif ( strcmp(roi_label, 'monkey') )
    duration_label = ternary( first_dur_monkey >= min_num_samples, long_enough_label, too_short_label );
    
  else
    duration_label = too_short_label;
  end
  
  setcat( fix_labels, {'looks_to', 'duration'}, {roi_label, duration_label}, i );
end

outs = struct();
outs.labels = fix_labels;

end

function [ts, durs] = fixations_in_time_range(t_trial, ib, min_t, max_t)

[starts, durs] = shared_utils.logical.find_all_starts( ib );
ts = t_trial(starts);
ts = ts(ts >= min_t & ts <= max_t);

end