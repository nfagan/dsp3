consolidated = dsp3.get_consolidated_data();

labs = fcat.from( consolidated.trial_data.labels );
rt = consolidated.reaction_time;

analysis_p = dsp3.analysisp( {'behavior', dsp3.datedir} );

%%

drug_type = 'nondrug';
per_mag = false;

spec = { 'outcomes', 'trialtypes', 'days', 'drugs', 'administration' };

if ( per_mag ), spec{end+1} = 'magnitudes'; end

[subsetlabs, I] = dsp3.get_subset( labs', drug_type );
subsetrt = rt(I);

%%  compare means

do_save = true;
prefix = 'rt__stats';

mask = find( subsetlabs, 'choice' );

[tlabs, I] = keepeach( subsetlabs', setdiff(spec, {'outcomes', 'days'}), mask );
setcat( addcat(tlabs, 'measure'), 'measure', 'p value' );

pairs = { 
    {'self', 'both'} ...
  , {'both', 'other'} ...
  , {'other', 'none'} ...
  };

repset( tlabs, 'outcomes', cellfun(@(x) strjoin(x, ' vs. '), pairs, 'un', 0) );
ps = rowzeros( rows(tlabs) );

for j = 1:numel(pairs)
  for i = 1:numel(I)
    ind_a = find( subsetlabs, pairs{j}{1}, I{i} );
    ind_b = find( subsetlabs, pairs{j}{2}, I{i} );

    [h, p, ~, stats] = ttest2( subsetrt(ind_a), subsetrt(ind_b) );
    
    stp = i + (j-1)*numel(I);
    
    ps(stp) = p;
  end
end

[t, rc] = tabular( tlabs, {'outcomes', 'measure'}, {'trialtypes', 'magnitudes'} );

ps_tbl = fcat.table( cellfun(@(x) ps(x), t), rc{:} );

if ( do_save )
  shared_utils.io.require_dir( analysis_p );
  fname = dsp3.prefix( prefix, dsp3.fname(tlabs, spec) );
  dsp3.writetable( ps_tbl, fullfile(analysis_p, fname) );  
end

%%  get means & devs

do_save = true;
prefix = 'rt__descriptives';

mask = setdiff( find(subsetlabs, 'choice'), find(subsetlabs, 'errors') );

[meanlabs, I] = keepeach( subsetlabs', setdiff(spec, {'days'}), mask );

means = rownanmean( subsetrt, I );
devs = rownanstd( subsetrt, I );

[t, rc] = tabular( meanlabs, 'outcomes', {'trialtypes', 'drugs', 'magnitudes'} );

t_means = cellfun( @(x) means(x), t );
t_devs = cellfun( @(x) devs(x), t );

repset( addcat(rc{1}, 'measure'), 'measure', {'mean', 'std'} );

means_tbl = fcat.table( [t_means; t_devs], rc{:} );

if ( do_save )
  shared_utils.io.require_dir( analysis_p );
  fname = dsp3.prefix( prefix, dsp3.fname(tlabs, spec) );
  dsp3.writetable( means_tbl, fullfile(analysis_p, fname) );  
end

