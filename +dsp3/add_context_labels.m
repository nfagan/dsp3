function labs = add_context_labels(labs)

addcat( labs, 'contexts' );

cued = find( labs, 'cued' );
choice = find( labs, 'choice' );

[I, C] = findall( labs, 'outcomes' );

for i = 1:numel(I)
  ind = I{i};
  
  out = C{i};
  
  if ( strcmp(out, 'errors') ), continue; end
  
  if ( strcmp(out, 'other') || strcmp(out, 'none') )
    choice_lab = 'othernone';
  elseif ( strcmp(out, 'self') || strcmp(out, 'both') )
    choice_lab = 'selfboth';
  else
    continue;
  end
  
  setcat( labs, 'contexts', choice_lab, intersect(ind, choice) );
  setcat( labs, 'contexts', sprintf('context__%s', out), intersect(ind, cued) );
end

end