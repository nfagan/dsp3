function file = dsp3_keep_aligned_lfp_file(file, mask)

fs = { 'data', 'labels', 'has_partial_data', 'event_ind' };
for i = 1:numel(fs)
  if ( isa(file.(fs{i}), 'fcat') )
    file.(fs{i}) = file.(fs{i})(mask);
  else  
    file.(fs{i}) = file.(fs{i})(mask, :);
  end
end

end