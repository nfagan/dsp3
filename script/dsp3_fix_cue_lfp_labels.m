function dsp3_fix_cue_lfp_labels()

src_choice_p = 'H:\data\cc_dictator\mua';
src_cue_p = 'H:\data\cc_dictator\mua\cued_data';

dest_cue_p = fullfile( src_cue_p, 'match_choice_labels' );
shared_utils.io.require_dir( dest_cue_p );

src_choice_files = shared_utils.io.findmat( src_choice_p );
src_choice_files = shared_utils.io.filter_files( src_choice_files, 'lfp_' );
src_choice_files = shared_utils.io.filter_files( src_choice_files, 'targacq' )';

cue_epochs = { 'targon', 'cueon' };

for i = 27:numel(src_choice_files)
  shared_utils.general.progress( i, numel(src_choice_files) );
  
  src_choice_filename = shared_utils.io.filenames( src_choice_files{i}, true );
  src_choice_file = shared_utils.io.fload( src_choice_files{i} );
  
  assert( strcmp(src_choice_file('epochs'), 'targAcq') );
  
  choice_labels = src_choice_file.labels;
  
  for j = 1:numel(cue_epochs)
    src_cue_filename = strrep( src_choice_filename, 'targacq', cue_epochs{j} );
    
    src_cue_file = shared_utils.io.fload( fullfile(src_cue_p, src_cue_filename) );
    cue_labels = src_cue_file.labels;
    
    if ( ~eq_ignoring(choice_labels, cue_labels, 'epochs') )
      fprintf( '\n Labels non-matching for: "%s".', char(src_cue_file('days')) );
      
      src_cue_file = match_choice_cue( choice_labels, src_cue_file );
      assert( eq_ignoring(choice_labels, src_cue_file.labels, 'epochs') );
    end
    
    dest_cue_fullfile = fullfile( dest_cue_p, src_cue_filename );
    
    save( dest_cue_fullfile, 'src_cue_file' );
  end
end

end

function matched_cue_file = match_choice_cue(choice_labels, src_cue_file)

choice_cont = Container( zeros(shape(choice_labels, 1), 1), choice_labels );
choice_cont = dsp2.process.format.fix_block_number( choice_cont );
choice_cont = dsp2.process.format.fix_administration( choice_cont );

fixed_choice_labels = choice_cont.labels;
cue_labels = src_cue_file.labels;

choice_fcat = fcat.from( fixed_choice_labels );
cue_fcat = fcat.from( cue_labels );

[choice_I, cue_I] = sort_by_trial_block_session( choice_fcat, cue_fcat );

cats_to_check = setdiff( getcats(choice_fcat) ...
  , {'epochs', 'administration', 'blocks', 'sessions'} );

assert( size(choice_fcat, 1) == size(cue_fcat, 1), 'Rows mismatch.' );

for i = 1:size(choice_fcat, 1)
  choice_vals = cellstr( choice_fcat, cats_to_check, i );
  cue_vals = cellstr( cue_fcat, cats_to_check, i );
  
  assert( all(strcmp(choice_vals, cue_vals)), 'Values mismatch' );
end

tmp_cue_fcat = fcat.from( cue_labels );

for i = 1:numel(choice_I)
  assign( tmp_cue_fcat, cue_fcat, choice_I(i), i );
end

test_cue_labels = SparseLabels.from_fcat( tmp_cue_fcat );
assert( eq_ignoring(test_cue_labels, choice_labels, {'epochs', 'administration', 'blocks', 'sessions'}) );

copy_cats = { 'administration', 'blocks', 'sessions' };
copy_choice = fcat.from( choice_labels );

for i = 1:numel(copy_cats)
  setcat( tmp_cue_fcat, copy_cats{i}, fullcat(copy_choice, copy_cats{i}) );
end

test_cue_labels = SparseLabels.from_fcat( tmp_cue_fcat );
assert( eq_ignoring(test_cue_labels, choice_labels, 'epochs') );

matched_cue_file = src_cue_file;

src_dat = src_cue_file.data;
assert( ismatrix(src_dat) );

new_dat = nan( size(src_dat) );
src_dat = src_dat(cue_I, :);

for i = 1:numel(choice_I)
  new_dat(choice_I(i), :) = src_dat(i, :);
end

matched_cue_file.data = new_dat;
matched_cue_file.labels = test_cue_labels;

end

function [choice_I, cue_I] = sort_by_trial_block_session(choice_fcat, cue_fcat)

choice_m = get_label_mat( choice_fcat );
cue_m = get_label_mat( cue_fcat );

[~, choice_I] = sortrows( choice_m );
[~, cue_I] = sortrows( cue_m );

keep( choice_fcat, choice_I );
keep( cue_fcat, cue_I );

end

function m = get_label_mat(labs)

trials_blocks_sessions = cellstr( labs, {'trials', 'blocks', 'sessions', 'sites'} );

trials = cellfun( @(x) str2double(x(numel('trial__')+1:end)), trials_blocks_sessions(:, 1) );
blocks = cellfun( @(x) str2double(x(numel('block__')+1:end)), trials_blocks_sessions(:, 2) );
sessions = cellfun( @(x) str2double(x(numel('session__')+1:end)), trials_blocks_sessions(:, 3) );
sites = cellfun( @(x) str2double(x(numel('site__')+1:end)), trials_blocks_sessions(:, 4) );

m = [ sessions, blocks, trials, sites ];
assert( ~any(isnan(m(:))), 'Failed to parse blocks / trials / sessions.' );

end