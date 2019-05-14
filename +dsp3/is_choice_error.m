function tf = is_choice_error(events, event_labels, event_key)

assert_ispair( events, event_labels );

is_choice = trueat( event_labels, find(event_labels, 'choice') );

is_missing_choice = events(:, event_key('targAcq')) == 0;

tf = is_choice & is_missing_choice;

end
