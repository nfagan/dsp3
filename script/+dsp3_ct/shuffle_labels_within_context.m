function labels = shuffle_labels_within_context(labels, each_I)

for i = 1:numel(each_I)
  context_I = findall( labels, 'contexts', each_I{i} );
end

end