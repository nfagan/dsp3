function check_pro_minus_anti()

conf = dsp3.config.load();

summary_types = { 'nanmedian', 'nanmedian_2' };

rev_types = { 'orig', 'full', 'revA', 'revB' };
sub_specs = { 'blocks' };

io = dsp2.io.get_dsp_h5();

base_save_p = dsp3.plotp( {'check_spectra', dsp3.datedir()}, conf );
base_save_p = char( base_save_p );

for i = 1:numel(summary_types)
fprintf( '\n %d of %d', i, numel(summary_types) );

summary_type = summary_types{i};

P = dsp2.io.get_path( 'Measures', 'coherence', summary_type, 'targacq' );

coh = io.read( P, 'frequencies', [0, 100] );

coh = dsp2.process.format.fix_block_number( coh );
coh = dsp2.process.format.fix_administration( coh );
coh = dsp2.process.manipulations.non_drug_effect( coh );
coh = keep_within_times( coh, [-350, 300] );

freqs = coh.frequencies;
t = coh.get_time_series();
data = coh.data;
labels = fcat.from( coh.labels );

C = dsp3.numel_combvec( rev_types, sub_specs );

for j = 1:size(C, 2)
  fprintf( '\n\t %d of %d', j, size(C, 2) );
  
  rev_type = rev_types{C(1, j)};
  sub_spec = sub_specs{C(2, j)};
  
  switch ( rev_type )
    case 'orig'
      to_remove = dsp2.process.format.get_bad_days();
    case 'revA'
      to_remove = dsp3.bad_days_revA;
    case 'revB'
      to_remove = dsp3.bad_days_revB;
    case 'full'
      to_remove = {};
    otherwise
      error( 'Unrecognized rev type "%s".', rev_type );
  end
  
  site_spec = { 'days', 'administration', 'trialtypes', 'regions', 'channels' };
  
  switch ( sub_spec )
    case 'blocks'
      usespec = csunion( site_spec, {'blocks', 'sessions'} );
    case 'sites'
      usespec = site_spec;
    otherwise
      error( 'Unrecognized sub spec "%s"', sub_spec );      
  end
  
  usedat = data;
  uselabs = labels';
  
  usedat = indexpair( usedat, uselabs, findnone(uselabs, to_remove) );
  
  [usedat, uselabs] = dsp3.pro_v_anti( usedat, uselabs, usespec );
  [usedat, uselabs] = dsp3.pro_minus_anti( usedat, uselabs, usespec );
  
  pl = plotlabeled.make_spectrogram( freqs, t );
  
  mask = find( uselabs, 'choice' );
  pcats = { 'outcomes', 'administration', 'trialtypes' };
  
  pl.imagesc( rowref(usedat, mask), uselabs(mask), pcats );
  
  full_p = fullfile( base_save_p, rev_type, summary_type, 'nondrug', sub_spec );
  dsp3.req_savefig( gcf, full_p, uselabs, pcats, 'spectra' );
end


end
