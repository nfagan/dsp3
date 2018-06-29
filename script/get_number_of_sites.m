io = dsp2.io.get_dsp_h5();

p = io.fullfile( 'Signals', 'none', 'complete', 'targacq' );

labs = io.read_labels_( p );

%%
conf = dsp3.config.load();
analysis_p = fullfile( conf.PATHS.data_root, 'analyses', 'behavior', dsp3.datedir ); 

%%

flabs = fcat.from( labs );

%%

[druglabs, I] = dsp3.get_subset( flabs', 'drug' );

prune( druglabs );

%%
do_save = true;
prefix = 'n_sites';

spec = { 'days', 'channels', 'regions', 'sites' };

sitelabs = keepeach( druglabs', spec, findor(druglabs, {'bla', 'acc'}) );

drugspec = { 'drugs', 'regions' };

[drug_sitelabs, I] = keepeach( sitelabs', drugspec );
counts = cellfun( @numel, I );

[t, rc] = tabular( drug_sitelabs, drugspec );

tbl = fcat.table( cellfun(@(x) counts(x), t), rc{:} );

if ( do_save )
  shared_utils.io.require_dir( analysis_p );
  fname = sprintf( '%s_%s', prefix, joincat(drug_sitelabs, drugspec) );
  dsp3.writetable( tbl, fullfile(analysis_p, fname) );
end



