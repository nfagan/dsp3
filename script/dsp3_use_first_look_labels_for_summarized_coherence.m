function coh_labels = dsp3_use_first_look_labels_for_summarized_coherence(coh_file, look_labels, look_event_ind)

assert_ispair( look_event_ind, look_labels );

coh_labels = coh_file.labels';

coh_event_inds = coh_file.lfp_params.look_event_ind(coh_file.inds_a);
assert( numel(coh_event_inds) == rows(coh_file.data) );
match_inds = arrayfun( @(x) find(look_event_ind == x), coh_event_inds );
labs = prune( look_labels(match_inds) );

missing_cats = setdiff( getcats(labs), getcats(coh_labels) );
addcat( coh_labels, getcats(labs) );

missing_values = cellstr( labs, missing_cats );
setcat( coh_labels, missing_cats, missing_values );

end