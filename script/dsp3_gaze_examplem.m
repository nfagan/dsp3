%%

cats_rm = {'session_ids', 'contexts', 'sites', 'blocks'};
gl = gaze_labels';
el = fcat.from( consolidated.events.labels );

for i = 1:numel(cats_rm)
  if ( hascat(el, cats_rm{i}) )
    rmcat( el, cats_rm{i} );
  end
  if ( hascat(gl, cats_rm{i}) )
    rmcat( gl, cats_rm{i} );
  end
end

[day_I, day_C] = findall( gl, 'days' );
for i = 1:numel(day_I)
  e_ind = find( el, day_C(:, i) );
  sub_el = prune( el(e_ind) );
  sub_gl = prune( gl(day_I{i}) );
  
  try
    assert( sub_el == sub_gl )
  catch err
    if ( all(strcmp(combs(sub_gl, 'drugs'), 'unspecified')) && ...
         all(strcmp(combs(sub_el, 'drugs'), 'unspecified')) )
      disp( 'x' );
    else
      disp( combs(sub_gl, 'drugs') )
    end
  end
end

%%

load( 'C:\Users\nick\Downloads\trial_data.mat' );
t = shared_utils.io.fload( 'D:\data\bla-acc-coupling\gaze\t.mat' );
x = shared_utils.io.fload( 'D:\data\bla-acc-coupling\gaze\x.mat' );
y = shared_utils.io.fload( 'D:\data\bla-acc-coupling\gaze\y.mat' );
gaze_labels = shared_utils.io.fload( 'D:\data\bla-acc-coupling\gaze\labels.mat' );

%%

load( 'trial_data.mat' );
t = shared_utils.io.fload( 't.mat' );
x = shared_utils.io.fload( 'x.mat' );
y = shared_utils.io.fload( 'y.mat' );
gaze_labels = shared_utils.io.fload( 'labels.mat' );

%%

event_ts = consolidated.events.data;
event_labels = fcat.from( consolidated.events.labels );
event_key = consolidated.event_key;

rois = dsp3.picto_gaze_rois();
monk_roi = rois.monkey;
bottle_roi = rois.bottle;

fix_on_ts = event_ts(:, event_key('fixOn'));            % trial start
target_event_ts = event_ts(:, event_key('rwdOn'));      % event to search for
fix_on_ts(fix_on_ts == 0 | target_event_ts == 0) = nan;	% remove error trials

target_event_offsets = target_event_ts - fix_on_ts;     % target event time relative to trial start

[day_I, day_C] = findall( event_labels, 'days' );

for idx = 1:numel(day_I)
  % For each day, find the corresponding set of gaze vectors (x, y, t)
  % for the trial-set on this day.
  event_ind = day_I{idx};
  gaze_ind = find( gaze_labels, day_C(:, idx) );
  assert( numel(event_ind) == numel(gaze_ind) ...
    , 'Mismatch between gaze and event subset.' );
  
  % Event offsets for this day.
  curr_offsets = target_event_offsets(event_ind);

  for i = 1:numel(gaze_ind)    
    % For each trial, find the closet
    curr_offset = curr_offsets(i);
    if ( isnan(curr_offset) )
      % Skip error trials.
      continue;
    end
    
    gi = gaze_ind(i);
    t_trial = t(gi, :);
    max_t = find( t_trial == 0, 1 );
    if ( isempty(max_t) || max_t == 1 )
      continue;
    end

    assert( t_trial(1) == -1 ...
      , 'Expected first time point to be -1; was %0.3f', t_trial(1) );

    t_trial = t_trial(2:max_t-1); % remove first (invalid) time point
    x_trial = x(gi, 2:max_t-1);
    y_trial = y(gi, 2:max_t-1);
    
    % Find the time-stamp of `t_trial` closest to the offset of the 
    % current trial's target event.
    [~, target_ind] = min( abs(t_trial - curr_offset) );    
  end
end