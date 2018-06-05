[cohdat, cohlabs, t, freqs] = dsp3.get_intermediate_measure( 'coherence/targacq' );

prune( dsp3.add_context_labels(cohlabs) );

%%

drug_type = 'nondrug';

%%

coh = dsp3.get_subset( Container(cohdat, SparseLabels.from_fcat(cohlabs)), drug_type );
coh = rm( coh, 'cued' );

cohdat = coh.data;
cohlabs = fcat.from( coh.labels );

%%

combined = dsp3.get_consolidated_data();

behav = require_fields( combined.trial_data, {'channels', 'regions', 'sites'} );
behav = dsp3.get_subset( behav, drug_type );
pref = dsp3.get_processed_pref_index( behav );

pref = pref({'choice'});

preflabs = fcat.from( pref.labels );
prefdat = full( pref.data );

%% pro v. anti, individual bands

ts = [ -250, 0 ];
bands = { [4, 8], [15, 25], [45, 60] };
bandnames = { 'theta', 'beta', 'gamma' };

% sub_each = { 'days', 'sites', 'channels', 'regions', 'trialtypes', 'administration' };
sub_each = { 'days', 'trialtypes', 'administration' };
match_each = setdiff( sub_each, {'channels', 'regions', 'sites'} );

[newlabs, I] = keepeach( cohlabs', sub_each );

sb_data = zeros( [numel(I), 1] );
on_data = zeros( size(sb_data) );

sb_pref = nan( numel(I) * numel(bandnames), 1 );
on_pref = nan( size(sb_pref) );

sblab = 'bothOverself';
onlab = 'otherOvernone';

sblabs = fcat();
onlabs = fcat();

for idx = 1:numel(bandnames)
  
  t_ind = t >= ts(1) & t <= ts(2);
  f_ind = freqs >= bands{idx}(1) & freqs <= bands{idx}(2);
  meaned = squeeze( nanmean(nanmean(cohdat(:, f_ind, t_ind), 3), 2) );  

  for i = 1:numel(I)    
    ind = trueat( cohlabs, I{i} );

    self = nanmean( meaned(ind & trueat(cohlabs, find(cohlabs, 'self'))) );
    both = nanmean( meaned(ind & trueat(cohlabs, find(cohlabs, 'both'))) );
    other = nanmean( meaned(ind & trueat(cohlabs, find(cohlabs, 'other'))) );
    none = nanmean( meaned(ind & trueat(cohlabs, find(cohlabs, 'none'))) );
    
    stp = (idx-1) * numel(I) + i;

    sb_data(stp) = self - both;
    on_data(stp) = other - none;

    ids = partcat( newlabs, match_each, i );  

    sb_ind = find( preflabs, [ids, sblab] );
    on_ind = find( preflabs, [ids, onlab] );

    assert( numel(sb_ind) == 1 && numel(on_ind) == 1 );

    sb_pref(stp) = prefdat(sb_ind);
    on_pref(stp) = prefdat(on_ind);
  end
  
  setcat( addcat(newlabs, 'band'), 'band', bandnames{idx} );
  
  append( sblabs, setcat(newlabs, 'outcomes', 'selfMinusBoth') );
  append( onlabs, setcat(newlabs, 'outcomes', 'otherMinusNone') );
end

newlabs = append( sblabs', onlabs );
roi_meaned = [ sb_data; on_data ];
newpref = [ sb_pref; on_pref ];

%% pro v. anti, ratio

betas = [ 15, 25 ];
gammas = [ 45, 60 ];
ts = [ -250, 0 ];

t_ind = t >= ts(1) & t <= ts(2);
g_ind = freqs >= gammas(1) & freqs <= gammas(2);
b_ind = freqs >= betas(1) & freqs <= betas(2);

% sub_each = { 'days', 'sites', 'channels', 'regions', 'trialtypes', 'administration' };
sub_each = { 'days', 'trialtypes', 'administration' };
match_each = setdiff( sub_each, {'channels', 'regions', 'sites'} );

[newlabs, I] = keepeach( cohlabs', sub_each );

sb_data = zeros( [numel(I), 1] );
on_data = zeros( size(sb_data) );

sb_pref = nan( numel(I), 1 );
on_pref = nan( size(sb_pref) );

sblab = 'bothOverself';
onlab = 'otherOvernone';

gamma = squeeze( nanmean(nanmean(cohdat(:, g_ind, t_ind), 2), 3) );
beta = squeeze( nanmean(nanmean(cohdat(:, b_ind, t_ind), 2), 3) );

for i = 1:numel(I)    
  ind = trueat( cohlabs, I{i} );
  
  pairs = { {'self', 'both'}, {'other', 'none'} };
  
  for j = 1:numel(pairs)
    trial_ind1 = ind & trueat( cohlabs, find(cohlabs, pairs{j}{1}) );
    trial_ind2 = ind & trueat( cohlabs, find(cohlabs, pairs{j}{2}) );
    
    gamma1 = nanmean( gamma(trial_ind1) );
    gamma2 = nanmean( gamma(trial_ind2) );
    
    beta1 = nanmean( beta(trial_ind1) );
    beta2 = nanmean( beta(trial_ind2) );
    
    ratio_diff = (gamma1 ./ beta1) - (gamma2 ./ beta2);
    
    if ( j == 1 )
      sb_data(i) = ratio_diff;
    else
      on_data(i) = ratio_diff; 
    end
  end
  
  ids = partcat( newlabs, match_each, i );
  
  sb_ind = find( preflabs, [ids, sblab] );
  on_ind = find( preflabs, [ids, onlab] );
  
  assert( numel(sb_ind) == 1 && numel(on_ind) == 1 );
  
  sb_pref(i) = prefdat(sb_ind);
  on_pref(i) = prefdat(on_ind);
end

sblabs = setcat( newlabs', 'outcomes', 'selfMinusBoth' );
onlabs = setcat( newlabs', 'outcomes', 'otherMinusNone' );

newlabs = append( sblabs, onlabs );
newdat = [ sb_data; on_data ];
newpref = [ sb_pref; on_pref ];

addcat( newlabs, 'band' );
setcat( newlabs, 'band', 'gamma beta ratio' );

roi_meaned = newdat;

%%

figure(2);
clf();

groups_are = { 'trialtypes', 'band' };
panels_are = { 'outcomes', 'band' };

pl = plotlabeled();
pl.color_func = @hsv;
pl.marker_size = 10;
pl.plot_empties = false;
[axs, ids] = pl.scatter( newpref, roi_meaned, newlabs, groups_are, panels_are );

arrayfun( @(x) xlabel(x, 'Prosocial Preference'), axs );
arrayfun( @(x) ylabel(x, 'Coherence Difference'), axs );

for i = 1:numel(ids)
  ax = ids(i).axes;
  data_inds = ids(i).index;
  
  x = newpref(data_inds);
  y = roi_meaned(data_inds);
  
  if ( isempty(x) || isempty(y) ), continue; end
  
  [r, p] = corr( x, y, 'rows', 'complete' );
  ps = polyfit( x, y, 1 );
  xs = get( ax, 'xtick' );
  ys = polyval( ps, xs );
  plot( ax, xs, ys );
  
  txt = sprintf( 'R=%0.3f, P=%0.3f', r, p );
  
  if ( p < 0.05 ), txt = sprintf( '%s *', txt); end
  
  text( ax, xs(end-1), ys(end), txt );    
end





