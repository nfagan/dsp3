function [coh_dat, coh_labs] = dsp3_linearize_cc_sf(acc, bla, spikes, events, targacq_labels)

validate( acc, bla, events );

outcome_names = { 'self', 'both', 'other', 'none' };

acc_stp = 1;
coh_labs = fcat();
coh_dat = cell( numel(events), 1 );

for i = 1:numel(events)
  shared_utils.general.progress( i, numel(events) );
  
  event_labs = fcat.from( events{i}.event.labels );
  addcat( event_labs, {'regions', 'channels', 'spike_channels', 'lfp_channels'} );
  
  if ( isempty(bla{i}) )
    use_coh = acc{acc_stp};
    acc_stp = acc_stp + 1;
    spk_region_name = 'acc';
    lfp_region_name = 'bla';
  else
    use_coh = bla{i};
    spk_region_name = 'bla';
    lfp_region_name = 'acc';
  end
  
  num_conditions = numel( use_coh );
  num_pairs = cellfun( @numel, use_coh );
  
  assert( num_conditions == 4 );
  assert( numel(unique(num_pairs)) == 1 );
  
  is_cell_matching_region = find( cellfun( @(x) strcmp(x.name{1}, spk_region_name), spikes{i}.data) );
  [channel_I, channel_C] = findall( targacq_labels, {'channels', 'regions'} ...
    , find(targacq_labels, [combs(event_labs, 'days'), {lfp_region_name}]) );
  
  num_cells = numel( is_cell_matching_region );  
  num_chans = numel( channel_I );
  
  chan_cell_cmbtns = dsp3.ncombvec( num_cells, num_chans );
  num_chan_cell_cmbtns = size( chan_cell_cmbtns, 2 );
  
  cmbtns = dsp3.ncombvec( num_conditions, num_pairs(1) );
  num_cmbtns = size( cmbtns, 2 );
  
  assert( num_cmbtns == num_chan_cell_cmbtns*num_conditions );
  coh_arrays = cell( num_conditions*num_chan_cell_cmbtns, 1 );
  stp = 1;
  
  for j = 1:num_conditions
    for k = 1:num_chan_cell_cmbtns
      cell_ind = chan_cell_cmbtns(1, k);
      chan_ind = chan_cell_cmbtns(2, k);
    
      site = use_coh{j}{k}.C;      
      match_ind = find( event_labs, {outcome_names{j}, 'choice'} );
      
      if ( isempty(site) )
        stp = stp + 1;
        continue;
      end
      
      num_trials = size( site{1}, 2 );
      assert( num_trials == numel(match_ind) );

      curr_rows = rows( coh_labs );
      append( coh_labs, event_labs, match_ind );
      new_rows = rows( coh_labs );
      
      lfp_region_info = channel_C(:, chan_ind);
      spk_region_info = spikes{i}.data{is_cell_matching_region(cell_ind)}.name;
      
      assign_ind = curr_rows+1:new_rows;

      assert( strcmp(lfp_region_info{2}, lfp_region_name) );
      assert( strcmp(spk_region_info{1}, spk_region_name) );
      
      region_str = sprintf( '%s_%s', spk_region_info{1}, lfp_region_info{2} );
      channel_str = sprintf( '%s_%s', spk_region_info{2}, lfp_region_info{1} );
      
      setcat( coh_labs, 'regions', region_str, assign_ind );
      setcat( coh_labs, 'channels', channel_str, assign_ind );
      setcat( coh_labs, 'spike_channels', spk_region_info{2}, assign_ind );
      setcat( coh_labs, 'lfp_channels', lfp_region_info{1}, assign_ind );
      
      coh = cat_expanded( 3, cellfun(@(x) x', site, 'un', 0) );
      coh_arrays{stp} = coh;
      stp = stp + 1;
    end
  end
  
  coh_dat{i} = vertcat( coh_arrays{:} );
end

coh_dat = vertcat( coh_dat{:} );

end

function validate(acc, bla, events)

acc_empties = cellfun( @isempty, acc );
bla_empties = cellfun( @isempty, bla );

assert( ~any(acc_empties) );
assert( nnz(bla_empties) == numel(acc_empties) );
assert( numel(events) == numel(bla) );

end