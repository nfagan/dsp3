function lfp_file = dsp3_reference_subtract_lfp_file(lfp_file)

is_ref = strcmp( lfp_file.labels.region, 'ref' );
assert( sum(is_ref) == 1, 'Could not find reference trace.' );
non_refs = find( ~is_ref );

for i = 1:numel(non_refs)
  non_ref = non_refs(i);
  lfp_file.lfp(non_ref, :) = lfp_file.lfp(non_ref, :) - lfp_file.lfp(is_ref, :);
end
lfp_file.lfp = lfp_file.lfp(non_refs, :);
lfp_file.labels = structfun( @(x) x(non_refs, :), lfp_file.labels, 'un', 0 );
lfp_file.channel_nums = lfp_file.channel_nums(non_refs);

end