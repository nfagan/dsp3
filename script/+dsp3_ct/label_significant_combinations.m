function labels = label_significant_combinations(ps, labels, each_I, targets, varargin)

defaults = struct();
defaults.join_pattern = '_';
defaults.alpha = 0.05;

params = dsp3.parsestruct( defaults, varargin );

alpha = params.alpha;
join_pattern = params.join_pattern;

assert_ispair( ps, labels );
addcat( labels, 'significance' );

for i = 1:numel(each_I)
  [target_I, target_C] = findall( labels, targets, each_I{i} );
  
  current_sig = {};
  
  for j = 1:numel(target_I)
    target_ind = target_I{j};    
    
    for k = 1:numel(target_ind)
      if ( ps(target_ind(k)) < alpha )
        current_sig{end+1} = strjoin( target_C(:, j), join_pattern );
        break;
      end
    end
  end
  
  if ( isempty(current_sig) )
    sig_label = 'not_significant';
  else
    sig_label = sprintf( 'significant%s%s', join_pattern, strjoin(sort(current_sig), join_pattern) );
  end
  
  setcat( labels, 'significance', sig_label, each_I{i} );
end

prune( labels );

end