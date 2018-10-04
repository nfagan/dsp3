conf = dsp3.config.load();

date_dir = '072618';  % sites;
lda_dir = fullfile( conf.PATHS.dsp2_analyses, 'lda', date_dir );

lda = get_messy_lda_data( lda_dir );

%%
revs = dsp3.get_rev_types();

rev_types = revs.keys();

C = dsp3.numel_combvec( rev_types );

for i = 1:size(C, 2)
  
  rev_type = rev_types{C(1, i)};
  to_remove = revs(rev_type);

  stats__lda_hists( ...
      'lda',          lda ...
    , 'config',       conf ...
    , 'base_subdir',  rev_type ...
    , 'remove',       to_remove ...
    , 'drug_type',    'nondrug' ...
  );
  
end