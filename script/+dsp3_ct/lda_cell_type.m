function [lda_perf, lda_labels] = lda_cell_type(psth, targets, each_I, varargin)

defaults = struct();
defaults.hold_out = 0.25;

params = dsp3.parsestruct( defaults, varargin );

assert_ispair( psth );

psth_dat = psth.data;
psth_labs = psth.labels;

validateattributes( psth_dat, {'double'}, {'vector'}, mfilename, 'psth data' );

hold_out = params.hold_out;

lda_labels = cell( numel(each_I), 1 );
lda_perf = nan( size(lda_labels) );

for i = 1:numel(each_I)
  cond_I = findall( psth_labs, targets, each_I{i} );
  
  all_inds = vertcat( cond_I{:} );
  all_conditions = make_conditions( cond_I );
  cv_inds = cvpartition( numel(all_inds), 'holdout', hold_out );

  train_inds = all_inds(cv_inds.training);
  test_inds = all_inds(cv_inds.test);

  train_dat = psth_dat(train_inds);
  train_condition = all_conditions(cv_inds.training);

  test_dat = psth_dat(test_inds);
  test_condition = all_conditions(cv_inds.test);

  mdl = fitcdiscr( train_dat, train_condition, 'discrimtype', 'pseudoLinear' );
  predicted = predict( mdl, test_dat );

  performance = sum( predicted == test_condition ) / numel( test_condition );
  
  lda_labels{i} = append1( fcat(), psth_labs, all_inds );
  lda_perf(i) = performance;
end

lda_labels = vertcat( fcat, lda_labels{:} );

assert_ispair( lda_perf, lda_labels );

end

function inds = make_conditions(cond_inds)

nums = cellfun( @numel, cond_inds );
tot = sum( nums );
inds = nan( tot, 1 );
stp = 1;

for i = 1:numel(cond_inds)
  inds(stp:stp+nums(i)-1) = i-1;
  stp = stp + nums(i);
end

end