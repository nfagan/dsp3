function outs = keep_file_identifiers(outs, index)

outs.outcomes = outs.outcomes(index);
outs.file_parts = outs.file_parts(index);
outs.file_ids = outs.file_ids(index);
outs.regions = outs.regions(index);

end