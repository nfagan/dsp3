consolidated = dsp3.get_consolidated_data();

labs = fcat.from( consolidated.trial_data.labels );

analysis_p = dsp3.analysisp( {'behavior', dsp3.datedir} );

%%

drug_type = 'nondrug';
per_mag = false;

spec = { 'outcomes', 'trialtypes', 'days', 'drugs', 'administration' };

if ( per_mag ), spec{end+1} = 'magnitudes'; end

subsetlabs = dsp3.get_subset( labs', drug_type );

[prefdat, preflabs] = dsp3.get_pref( subsetlabs', setdiff(spec, 'outcomes') );

replace( preflabs, 'selfMinusBoth', 'selfboth' );
replace( preflabs, 'otherMinusNone', 'othernone' );

%%  sign rank against 0 preference

do_save = true;
prefix = 'preference__stats';

uselabs = preflabs';
usedat = prefdat;

mask = find( uselabs, 'choice' );

[tlabs, I] = keepeach( uselabs', setdiff(spec, 'days'), mask );

funcs = { @median, @mean, @plotlabeled.sem, @signrank };
names = { 'median', 'mean', 'sem', 'p value' };
assert( numel(funcs) == numel(names) );

vals = cellfun( @(x) rownan(rows(x)), cell(size(funcs)), 'un', 0 );

for i = 1:numel(I)
  X = usedat(I{i});
  for j = 1:numel(funcs)
    vals{j}(i) = funcs{j}( X );
  end
end

[t, rc] = tabular( tlabs, spec );

t_vals = cellfun( @(x) cellrefs(x, t), vals, 'un', 0 );

repset( addcat(rc{1}, 'measure'), 'measure', names );

ps_tbl = fcat.table( vertcat(t_vals{:}), rc{:} );

if ( do_save )
  shared_utils.io.require_dir( analysis_p );
  fname = dsp3.prefix( prefix, dsp3.fname(tlabs, spec) );
  dsp3.writetable( ps_tbl, fullfile(analysis_p, fname) );  
end