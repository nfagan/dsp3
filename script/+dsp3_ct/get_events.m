function [event_ts, event_labels] = get_events(consolidated, event_name)

event_ind = consolidated.event_key(event_name);
event_ts = consolidated.events.data(:, event_ind);
event_ts(event_ts == 0) = nan;

if ( nargout > 1 )
  event_labels = fcat.from( consolidated.events.labels );
end

end