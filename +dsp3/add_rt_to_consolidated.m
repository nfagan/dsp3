function add_rt_to_consolidated()

io = dsp2.io.get_dsp_h5();
p = dsp2.io.get_path( 'behavior' );

behav = io.read( p );
key = io.read( io.fullfile(p, 'Key') );
[consolidated, fname] = dsp3.get_consolidated_data();

behav = dsp2.process.format.fix_block_number( behav );
behav = dsp2.process.format.fix_administration( behav );

behav2 = consolidated.trial_data;

miss_cats1 = setdiff( categories(behav2), categories(behav) );
miss_cats2 = setdiff( categories(behav), categories(behav2) );

behav2('contexts') = '';
behav('contexts') = '';

behav2 = rm_fields( behav2, miss_cats1 );
behav = rm_fields( behav, miss_cats2 );

assert( behav2.labels == behav.labels );

rt_ind = find( strcmp(key, 'reaction_time') );

rt = behav.data(:, rt_ind);

consolidated.reaction_time = rt;

save( fname, 'consolidated' );

end