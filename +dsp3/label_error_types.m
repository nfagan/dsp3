function labels = label_error_types(labels, is_choice_error)

if ( islogical(is_choice_error) )
  assert_ispair( is_choice_error, labels );
  
  choice_error_inds = find( is_choice_error );
else
  choice_error_inds = is_choice_error;
end

error_ind = find( labels, 'errors' );

addsetcat( labels, 'error_types', 'no_error' );
setcat( labels, 'error_types', 'init_error', error_ind );
setcat( labels, 'error_types', 'choice_error', choice_error_inds );

end