function labels = add_spike_lfp_region_labels(labels)

addcat( labels, {'lfp_regions', 'spike_regions'} );
[reg_I, regs] = findall( labels, 'regions' );

for i = 1:numel(reg_I)
  reg_labels = strsplit( regs{i}, '_' );
  
  if ( numel(reg_labels) == 2 )
    spk_region = reg_labels{1};
    lfp_region = reg_labels{2};
    
    setcat( labels, 'spike_regions', sprintf('spike_%s', spk_region), reg_I{i} );
    setcat( labels, 'lfp_regions', sprintf('lfp_%s', lfp_region), reg_I{i} );
  end
end

prune( labels );

end