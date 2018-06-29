%%

consolidated = dsp3.get_consolidated_data();

%%

behav = consolidated.trial_data;
baselabs = fcat.from( behav.labels );

%%

drugtypes = { 'drug', 'nondrug' };

behavlabs = fcat();

for i = 1:numel(drugtypes)
  drugt = drugtypes{i};
  
  labs = dsp3.get_subset( baselabs', drugt );
  
  addcat( labs, 'dataset' );
  setcat( labs, 'dataset', sprintf('dataset: %s', drugt) );
  append( behavlabs, labs );
end

%%  pref index


[preflabs, I] = keepeach( behavlabs', {'days', 'administration', 'trialtypes', 'dataset'} );

pfunc = @(x, y) (x-y) / (x+y);

pairs = {
  {'both', 'self'},
  {'other', 'none'},
};

repset( preflabs, 'outcomes', cellfun(@strjoin, pairs, 'un', 0) );

prefdat = nan( length(preflabs), 1 );

for i = 1:numel(I)
  for j = 1:numel(pairs)
    l1 = pairs{j}{1};
    l2 = pairs{j}{2};
    
    p1 = count( behavlabs, l1, I{i} );
    p2 = count( behavlabs, l2, I{i} );
    
    pref = pfunc( double(p1), double(p2) );
    
    idx = (j-1)*numel(I) + i;
    
    prefdat(idx) = pref;
  end
end

%%

pl = plotlabeled( 'error_func', @plotlabeled.nansem );

xcats = 'outcomes';
gcats = 'administration';
pcats = { 'drugs', 'dataset' };

axs = pl.bar( prefdat, preflabs, xcats, gcats, pcats );

%%

axs = pl.errorbar( prefdat, preflabs, xcats, gcats, pcats );

%%

pl = plotlabeled();

gcats = { 'outcomes', 'administration' };
pcats = { 'drugs', 'dataset' };

axs = pl.boxplot( prefdat, preflabs, gcats, pcats );

