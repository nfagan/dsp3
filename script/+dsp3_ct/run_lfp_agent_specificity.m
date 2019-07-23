psd_subdir = 'original_per_trial_psd';

targ_lfp_agency_spec = dsp3_ct.lfp_agency_specificity( 'targAcq-150-cc' ...
  , 'psd_subdir', psd_subdir ...
  , 't_window', [0, 150] ...
);

rwd_lfp_agency_spec = dsp3_ct.lfp_agency_specificity( 'rwdOn-150-cc' ...
  , 'psd_subdir', psd_subdir ...
  , 't_window', [0, 150] ...
);

%%

rwd_labs = rwd_lfp_agency_spec.anova_labels';
targ_labs = targ_lfp_agency_spec.anova_labels';

cat_rwd_labs = categorical( rwd_labs, setdiff(getcats(rwd_labs), 'epochs') );
cat_targ_labs = categorical( targ_labs, setdiff(getcats(targ_labs), 'epochs') );

assert( isequal(cat_rwd_labs, cat_targ_labs) );

%%

tbl_p = char( dsp3.analysisp({'lfp_site_agency', dsp3.datedir}) );

p_func = @(x) cellfun(@(y) y.Prob_F{1}, x);

rwd_anova_ps = p_func( rwd_lfp_agency_spec.anova_tables );
targ_anova_ps = p_func( targ_lfp_agency_spec.anova_tables );

sig_rwd = rwd_anova_ps < 0.05;
sig_targ = targ_anova_ps < 0.05;
sig_either = sig_rwd | sig_targ;
sig_both = sig_rwd & sig_targ;

sig_kinds = { 'rwd', 'targ', 'either_rwd_targ', 'both_rwd_targ' };
sigs = { sig_rwd, sig_targ, sig_either, sig_both };
assert( numel(sigs) == numel(sig_kinds) );

for i = 1:numel(sigs)
  
use_sig = sigs{i};

[t, rc] = tabular( rwd_labs, {'trialtypes', 'bands'}, 'regions' );

counts_sig = cellfun( @(x) sum(use_sig(x)), t );
props_sig = cellfun( @(x) sum(use_sig(x)) / numel(x), t ) * 100;

counts_tbl = fcat.table( counts_sig, rc{:} );
props_tbl = fcat.table( props_sig, rc{:} );

save_p = fullfile( tbl_p, sig_kinds{i} );
prefix = psd_subdir;

dsp3.req_writetable( props_tbl, save_p, rwd_labs, {'regions'}, prefix );

end

%%

use_sig = sig_either;

targ_acq_labs = fcat.from( dsp3_load_cc_targacq_labels() );
[I, C] = findall( targ_acq_labs, {'days', 'regions', 'channels'} );

band_names = combs( rwd_labs, 'bands' );
num_bands = numel( band_names );

per_band_labels = fcat.empties( size(band_names) );
addcat( targ_acq_labs, {'agent_selectivity', 'bands'} );

for i = 1:numel(I)
  matching_site = find( rwd_labs, C(:, i) );
  
  current_rows = rows( per_band_labels{1} );
  
  if ( numel(matching_site) ~= num_bands )
    assert( isempty(matching_site) );
  end
  
  for j = 1:num_bands 
    curr_ind = find( rwd_labs, band_names{j}, matching_site );
    
    if ( isempty(curr_ind) )
      agent_lab = 'non-agent-selective';
    else
      agent_lab = ternary( use_sig(curr_ind), 'agent-selective', 'non-agent-selective' );
    end
    
    append( per_band_labels{j}, targ_acq_labs, I{i} );
    setcat( per_band_labels{j}, 'agent_selectivity', agent_lab ...
      , (current_rows+1):rows(per_band_labels{j}) );
    setcat( per_band_labels{j}, 'bands', band_names{j} );
  end
end

%%
per_band_sp_labs = cellfun( @(x) SparseLabels.from_fcat(x), per_band_labels, 'un', 0 );

for i = 1:numel(per_band_sp_labs)
  fname = fullfile( tbl_p, sprintf('agent_labels_%s', band_names{i}) );
  band_labs = per_band_sp_labs{i};
  save( fname, 'band_labs' );
end

