function labels = dsp3_add_iti_first_look_labels(labels, iti_outs, min_dur)

assert_ispair( labels, iti_outs.labels );

long_enough_label = 'long_enough__true';
too_short_label = 'long_enough__false';
no_look_label = 'no_look';

addcat( labels, {'looks_to', 'duration'} );
setcat( labels, 'looks_to', no_look_label );
setcat( labels, 'duration', too_short_label );

num_trials = rows( labels );

for i = 1:num_trials  
  fix_bottle = iti_outs.bottle_starts{i};
  fix_monkey = iti_outs.monkey_starts{i};
  
  bottle_durs = iti_outs.bottle_durations{i};
  monkey_durs = iti_outs.monkey_durations{i};
  
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
    duration_label = ternary( ~isempty(first_dur_bottle) && first_dur_bottle >= min_dur, long_enough_label, too_short_label );
    
  elseif ( strcmp(roi_label, 'monkey') )
    duration_label = ternary( ~isempty(first_dur_monkey) && first_dur_monkey >= min_dur, long_enough_label, too_short_label );
    
  else
    duration_label = too_short_label;
  end
  
  setcat( labels, {'looks_to', 'duration'}, {roi_label, duration_label}, i );
end

prune( labels );

end