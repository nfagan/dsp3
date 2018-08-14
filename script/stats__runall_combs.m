function stats__runall_combs(varargin)

defaults = dsp3.get_behav_stats_defaults();
defaults.funcs = { ...
    @stats__percent_correct ...
  , @stats__pref ...
  , @stats__rt ...
  , @stats__gaze ...
  , @plot_pref_index_over_time ...
  , @stats__proanti_coh ...
  , @stats__gamma_beta_ratio ...
};

defaults.do_save = true;

inputs = dsp3.parsestruct( defaults, varargin );

conf = inputs.config;

inputs.consolidated = dsp3.get_consolidated_data( conf );

permonks = [true, false];
permag = false;

% rev_types = { 'revA', 'orig', 'full' };
rev_types = { 'revB', 'revA', 'orig', 'full' };
drug_types = { 'nondrug' };

C = dsp3.numel_combvec( permonks, permag, rev_types, drug_types );

for i = 1:size(C, 2)
  shared_utils.general.progress( i, size(C, 2) );
  
  col = C(:, i);

  is_permonk = permonks( col(1) );
  is_permag = permag( col(2) );
  revtype = rev_types{ col(3) };
  drugtype = drug_types{ col(4) };

  switch ( revtype )
    case 'revA'
      inputs.remove = dsp3.bad_days_revA();
    case 'revB'
      inputs.remove = dsp3.bad_days_revB();
    case 'orig'
      inputs.remove = dsp2.process.format.get_bad_days();
    case 'full'
      inputs.remove = {};  % remove nothing
    otherwise
      error( 'Unrecognized revision "%s".', revtype );
  end

  inputs.drug_type = drugtype;
  inputs.rev_type = revtype;
  inputs.base_subdir = revtype;
  inputs.per_monkey = is_permonk;
  inputs.per_magnitude = is_permag;

  funcs = reqcell( inputs.funcs );

  for j = 1:numel(funcs)
    try
      funcs{j}( inputs );
    catch err
      warning( err.message );
    end
  end

end

end