repadd( 'chronux', true );

if ( isempty(gcp('nocreate')) )
  parpool( feature('NumCores') );
end

conf = dsp3.config.load();

[spike_ts, spike_labels] = dsp3_load_cc_spike_data_for_sfcoherence( conf );

input_subdir = 'targAcq-150';
output_subdir = sprintf( '%s-original-reference-method', input_subdir );

dsp3.save_sfcoherence( input_subdir, output_subdir, spike_ts, spike_labels' ...
  , 'reference_func', @dsp3.ref_subtract ...
);