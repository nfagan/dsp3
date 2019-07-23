function dsp3_save_pre_choice_linearized_sf_coh(save_p, dat, labs, freqs, t)

assert_ispair( dat, labs );

mask = fcat.mask( labs ...
  , @find, {'choice', 'pre'} ...
);

assert( numel(freqs) == size(dat, 2) );
assert( numel(t) == size(dat, 3) );

f_ind = mask_gele( freqs, 0, 100 );

[coh_I, coh_C] = findall( labs, 'days', mask );

for i = 1:numel(coh_I)
  shared_utils.general.progress( i, numel(coh_I) );
  
  coh_dat = dat(coh_I{i}, f_ind, :);
  coh_labs = prune( keep(copy(labs), coh_I{i}) );
  
  to_save = struct();
  to_save.src_filename = coh_C{i};
  to_save.data = coh_dat;
  to_save.labels = coh_labs;
  to_save.f = freqs(f_ind);
  to_save.t = t;
  
  save( fullfile(save_p, sprintf('%s.mat', coh_C{i})), 'to_save' );
end

end