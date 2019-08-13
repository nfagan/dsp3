repadd( 'chronux', true );

if ( isempty(gcp('nocreate')) )
  parpool( feature('NumCores') );
end

conf = dsp3.config.load();

[spike_ts, spike_labels] = dsp3_load_cc_spike_data_for_sfcoherence( conf );

dsp3.save_sfcoherence( 'targAcq-150', spike_ts, spike_labels' ...
  , 'reference_func', @dsp3.bipoloar_derivation_reference ...
);