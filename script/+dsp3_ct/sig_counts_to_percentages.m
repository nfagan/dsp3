function counts = sig_counts_to_percentages(counts, count_labels, each_I)

assert_ispair( counts, count_labels );

received_kinds = { 'self', 'both', 'self_and_both' };
forgone_kinds = { 'other', 'none', 'other_and_none' };

for i = 1:numel(each_I)
  received_ind = find( count_labels, 'received', each_I{i} );
  forgone_ind = find( count_labels, 'forgone', each_I{i} );
  ns_ind = find( count_labels, 'not_significant', each_I{i} );
  tot_ind = find( count_labels, 'total', each_I{i} );
  
  received_sum = counts(received_ind);
  forgone_sum = counts(forgone_ind);
  ns_sum = counts(ns_ind);
  tot_sum = counts(tot_ind);
  
  received_inds = findor( count_labels, received_kinds, each_I{i} );
  forgone_inds = findor( count_labels, forgone_kinds, each_I{i} );
  
  counts(received_inds) = counts(received_inds) / received_sum;
  counts(forgone_inds) = counts(forgone_inds) / forgone_sum;
  
  counts(received_ind) = received_sum / tot_sum;
  counts(forgone_ind) = forgone_sum / tot_sum;
  counts(ns_ind) = ns_sum / tot_sum;
end

end