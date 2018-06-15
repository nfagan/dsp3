import shared_utils.cell.percell;

unit_mats = dsp3.require_intermediate_mats( 'unit_conts' );

unitlabs = fcat();

for i = 1:numel(unit_mats)
  dsp3.progress( i, numel(unit_mats) );
  unit_file = shared_utils.io.fload( unit_mats{i} );  
  append( unitlabs, fcat.from(unit_file.units_to_picto_time.labels) );
end

%%

[n_unitlabs, I] = keepeach( unitlabs', 'region' );

counts = cellfun( @numel, I );

[t, rc] = tabular( n_unitlabs, 'region', 'days' );

tbl = fcat.table( rowrefs(counts, t), rc{:} )