%%
 
[coh, coh_labs, coh_f, coh_t] = dsp3_load_sfcoh_by_reference_type();
coh_t = coh_t * 1e3;
 
%%
 
[psd, psd_labs, psd_f, psd_t] = dsp3_load_power_by_reference_type();
 
%%
 
proantis = [ true, false ];
kinds = { 'coh' };
cs = dsp3.numel_combvec( proantis, kinds );
 
for i = 1:size(cs, 2)
  
is_proanti = proantis(cs(1, i));
kind = kinds{cs(2, i)};
 
switch ( kind )
  case 'psd'
    data = abs( psd );
    labels = psd_labs';
    f = psd_f;
    t = psd_t;
  case 'coh'
    data = coh;
    labels = coh_labs';
    f = coh_f;
    t = coh_t;
  otherwise
    error( 'Unrecognized kind "%s".', kind );
end
 
dsp3_plot_data_by_reference_method( data, labels, f, t ...
  , 'pro_v_anti', is_proanti ...
  , 'pro_minus_anti', false ...
  , 'do_save', true ...
  , 'base_subdir', kind ...
);
 
end
