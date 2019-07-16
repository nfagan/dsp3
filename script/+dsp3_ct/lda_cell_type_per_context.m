function [lda_perf, lda_labels] = lda_cell_type_per_context(psth, each_I, varargin)

defaults = struct();
defaults.hold_out = 0.25;

params = dsp3.parsestruct( defaults, varargin );

assert_ispair( psth );

psth_dat = psth.data;
psth_labs = psth.labels;

validateattributes( psth_dat, {'double'}, {'vector'}, mfilename, 'psth data' );

lda_labels = cell( numel(each_I), 1 );
lda_perf = cell( size(lda_labels) );

parfor i = 1:numel(each_I)
  context_I = findall( psth_labs, 'contexts', each_I{i} );
  
  tmp_labs = fcat();
  tmp_performance = [];
  
  for j = 1:numel(context_I)
    outcome_I = findall( psth_labs, 'outcomes', context_I{j} );
    
    if ( numel(outcome_I) ~= 2 )
      error( 'Expected 2 outcomes; got %d.', numel(outcome_I) );
    end
    
    all_inds = vertcat( outcome_I{:} );
    all_conditions = [ zeros(numel(outcome_I{1}), 1); ones(numel(outcome_I{2}), 1) ];
    cv_inds = cvpartition( numel(all_inds), 'holdout', params.hold_out );
    
    train_inds = all_inds(cv_inds.training);
    test_inds = all_inds(cv_inds.test);
    
    train_dat = psth_dat(train_inds);
    train_condition = all_conditions(cv_inds.training);
    
    test_dat = psth_dat(test_inds);
    test_condition = all_conditions(cv_inds.test);
    
    mdl = fitcdiscr( train_dat, train_condition, 'discrimtype', 'pseudoLinear' );
    predicted = predict( mdl, test_dat );
  
    performance = sum( predicted == test_condition ) / numel( test_condition );
    
    append1( tmp_labs, psth_labs, all_inds );
    tmp_performance(end+1, 1) = performance;
  end
  
  lda_labels{i} = tmp_labs;
  lda_perf{i} = tmp_performance;
end

lda_perf = vertcat( lda_perf{:} );
lda_labels = vertcat( fcat, lda_labels{:} );

assert_ispair( lda_perf, lda_labels );

end