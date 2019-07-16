function labels = add_choice_cue_decode_category(labels, decode_category, mask)

if ( nargin < 3 )
  mask = rowmask( labels );
end

addcat( labels, decode_category );

outcome_I = findall( labels, 'outcomes', mask );

context_map = containers.Map();

for i = 1:numel(outcome_I)
  cued_lab = sprintf( '%s_%d', decode_category, i );
  
  cued_ind = find( labels, 'cued', outcome_I{i} );
  choice_ind = find( labels, 'choice', outcome_I{i} );
  
  setcat( labels, decode_category, cued_lab, cued_ind );
  
  context_label = combs( labels, 'contexts', choice_ind );
  
  if ( numel(context_label) ~= 1 )
    continue;
  end
  
  context_label = char( context_label );
  
  if ( ~isKey(context_map, context_label) )
    context_map(context_label) = double(context_map.Count) + 1;
  end
  
  choice_lab = sprintf( '%s_choice_%d', decode_category, context_map(context_label) );
  setcat( labels, decode_category, choice_lab, choice_ind );
end

prune( labels );

end