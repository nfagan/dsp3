function stats__rt(varargin)

defaults = dsp3.get_behav_stats_defaults();
params = dsp3.parsestruct( defaults, varargin );

drug_type = params.drug_type;
per_mag = params.per_magnitude;
do_save = params.do_save;
bs = params.base_subdir;
conf = params.config;

%%

if ( isempty(params.consolidated) )
  consolidated = dsp3.get_consolidated_data( conf );
else
  consolidated = params.consolidated;
end

labs = fcat.from( consolidated.trial_data.labels );
rt = consolidated.reaction_time;

mag_type = ternary( per_mag, 'magnitude', 'non_magnitude' );

path_components = { 'behavior', dsp3.datedir, bs, drug_type, 'rt', mag_type };

analysis_p = char( dsp3.analysisp(path_components, conf) );
plot_p = char( dsp3.plotp(path_components, conf) );

%%

spec = { 'outcomes', 'trialtypes', 'days', 'drugs', 'administration' };

if ( per_mag ), spec{end+1} = 'magnitudes'; end

[subsetlabs, I] = dsp3.get_subset( labs', drug_type );
subsetrt = rt(I);

subsetrt = indexpair( subsetrt, subsetlabs, findnone(subsetlabs, params.remove) );

[subsetlabs, I] = keepeach( subsetlabs, spec );
subsetrt = rownanmean( subsetrt, I );

%%  compare means

prefix = 'rt__stats';

mask = find( subsetlabs, 'choice' );

[tlabs, I] = keepeach( subsetlabs', setdiff(spec, {'outcomes', 'days'}), mask );
setcat( addcat(tlabs, 'measure'), 'measure', 'p value' );

pairs = { 
    {'self', 'both'} ...
  , {'self', 'other'} ...
  , {'self', 'none'} ...
  , {'both', 'other'} ...
  , {'both', 'none'} ...
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

rowcats = dsp3.nonun_or_all( tlabs, {'outcomes', 'measure', 'drugs', 'administration'} );
colcats = dsp3.nonun_or_all( tlabs, {'trialtypes', 'magnitudes'} );

[t, rc] = tabular( tlabs, rowcats, colcats );

ps_tbl = fcat.table( cellfun(@(x) ps(x), t), rc{:} );

if ( do_save )
  dsp3.savetbl( ps_tbl, analysis_p, tlabs, spec, prefix );
end

%%  get means & devs

prefix = 'rt__descriptives';

mask = setdiff( find(subsetlabs, 'choice'), find(subsetlabs, 'errors') );

[meanlabs, I] = keepeach( subsetlabs', setdiff(spec, {'days'}), mask );

means = rownanmean( subsetrt, I );
devs = rowop( subsetrt, I, @plotlabeled.nansem );

rowcats = dsp3.nonun_or_all( meanlabs, {'outcomes', 'administration'} );
colcats = dsp3.nonun_or_all( meanlabs, {'trialtypes', 'drugs', 'magnitudes'} );

[t, rc] = tabular( meanlabs, rowcats, colcats );

t_means = cellfun( @(x) means(x), t );
t_devs = cellfun( @(x) devs(x), t );

repset( addcat(rc{1}, 'measure'), 'measure', {'mean', 'sem'} );

means_tbl = fcat.table( [t_means; t_devs], rc{:} );

if ( do_save )
  dsp3.savetbl( means_tbl, analysis_p, tlabs, spec, prefix );
end

%%  anova with magnitude

if ( per_mag )
  pref = 'rt__magnitudes__';
  
  uselabs = subsetlabs';
  usedat = subsetrt;
  
  mask = fcat.mask( uselabs, @find, 'choice', @findnone, 'errors' );
  factors = { 'outcomes', 'magnitudes' };
  anovas_each = setdiff( spec, union(factors, {'days'}) );
  
  outs = dsp3.anovan( usedat, uselabs', anovas_each, factors, 'mask', mask );
  
  if ( do_save )
    a_tbls = outs.anova_tables;
    a_labs = outs.anova_labels';
    
    c_tbls = outs.comparison_tables;
    
    m_tbl = outs.descriptive_tables;
    m_labs = outs.descriptive_labels';
    
    for i = 1:numel(a_tbls)
      dsp3.savetbl( a_tbls{i}, analysis_p, a_labs(i), anovas_each, sprintf('%sanova', pref) );
      dsp3.savetbl( c_tbls{i}, analysis_p, a_labs(i), anovas_each, sprintf('%scomparisons', pref) );
    end
    
    dsp3.savetbl( m_tbl, analysis_p, m_labs, anovas_each, sprintf('%sdescriptives', pref) );    
  end
end

%%  t test for each context

pref = 'rt__t_per_context__';

usedat = subsetrt;
uselabs = subsetlabs';

usespec = cssetdiff( spec, {'days', 'outcomes'} );

mask = fcat.mask( uselabs, @find, 'choice', @findnone, 'errors' );

outs = dsp3.ttest2( usedat, uselabs', usespec, 'selfboth', 'othernone' ...
  , 'mask', mask ...
);

m_tbl = outs.descriptive_tables;
mlabs = outs.descriptive_labels;
meanspec = outs.descriptive_specificity;
t_tbls = outs.t_tables;
tlabs = outs.t_labels;

if ( do_save )
  dsp3.savetbl( m_tbl, analysis_p, mlabs, meanspec, sprintf('%sdescriptives', pref) );
  
  for i = 1:numel(t_tbls)
    dsp3.savetbl( t_tbls{i}, analysis_p, tlabs(i), usespec, sprintf('%st_tables', pref) );
  end
end

%%

prefix = 'rt';

pltlabs = subsetlabs';
pltdat = subsetrt;

pl = plotlabeled();
pl.summary_func = @plotlabeled.nanmean;
pl.error_func = @plotlabeled.nansem;
pl.x_order = { 'self', 'both', 'other', 'none' };
pl.group_order = { 'low', 'medium', 'high' };

mask = fcat.mask( pltlabs, @find, 'choice', @findnone, 'errors' );

pl.bar( pltdat(mask), pltlabs(mask), 'outcomes', 'magnitudes', {'drugs', 'trialtypes'} );

if ( do_save )
  fname = dsp3.prefix( prefix, dsp3.fname(pltlabs, {'outcomes', 'drugs', 'trialtypes'}) );
  dsp3.savefig( gcf, fullfile(plot_p, fname) );
end