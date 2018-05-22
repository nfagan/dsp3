function all_units = make_ms_units( xls_unit_map, pl2_channel_map, pl2_start_times, pl2_filenames, pl2_sessions, pl2_days, mda_dir, mda_file )

import shared_utils.assertions.*;
import shared_utils.char.starts_with;
import shared_utils.char.ends_with;

assert__isa( xls_unit_map, 'containers.Map' );
assert__isa( pl2_channel_map, 'containers.Map' );
assert__is_cellstr( pl2_filenames );
assert__is_cellstr( pl2_sessions );
assert__isa( mda_dir, 'char' );
assert__isa( mda_file, 'char' );
assert( numel(pl2_filenames) == numel(pl2_sessions), 'Number of .pl2 files must match number of sessions.' );
assert( numel(pl2_sessions) == numel(pl2_days), 'Number of pl2 days must match number of pl2 sessions.' );
assert( numel(pl2_start_times) == numel(pl2_days), 'Number of pl2 start times must match number of pl2 sessions.' );

[pl2_filename, pl2_region, pl2_pre_post] = dsp3.decompose_mda_filename( mda_file );

assert( pl2_channel_map.isKey(pl2_filename), 'Unrecognized .pl2 file "%s"', pl2_filename );

sample_rate = 40e3;

xls_days = xls_unit_map( 'session_name' );
xls_channel_ns = xls_unit_map( 'channel_number' );
xls_epochs = xls_unit_map( 'epoch' );
xls_regions = xls_unit_map( 'region' );
xls_unit_rating = xls_unit_map( 'unit_rating' );
xls_unit_uuid = xls_unit_map( 'unit_uuid' );
xls_unit_numbers = xls_unit_map( 'unit_number' );
xls_mda_files = xls_unit_map( 'mda_file' );

pl2_ind = strcmp( pl2_filenames, pl2_filename );
assert( sum(pl2_ind) == 1, 'No .pl2 files matched "%s"', pl2_filename );

pl2_session = char( pl2_sessions(pl2_ind) );
pl2_day = char( pl2_days(pl2_ind) );
pl2_start_time = pl2_start_times(pl2_ind);

day_ind = strfind( pl2_day, 'day__' );
assert( day_ind == 1, ['Expected a day format like this: day__04192016' ...
  , ' but got this: "%s"'], pl2_day );

xls_day = pl2_day(numel('day__')+1:end);
xls_day_ind = strcmp( xls_days, xls_day );
xls_epoch_ind = strcmp( xls_epochs, pl2_pre_post );
xls_region_ind = strcmp( xls_regions, pl2_region );

for i = 1:numel(xls_mda_files)
  if ( ~ends_with(xls_mda_files{i}, '.mda') )
    xls_mda_files{i} = [ xls_mda_files{i}, '.mda' ];
  end
end

xls_mda_ind = strcmpi( xls_mda_files, mda_file );

all_units = [];

if ( ~any(xls_mda_ind) )
  fprintf( '\n No data matched .mda file "%s" in the excel file', mda_file );
  return;
end

% xls_subset_ind = xls_day_ind & xls_epoch_ind & xls_region_ind;
xls_subset_ind = xls_mda_ind;

% if ( ~any(xls_subset_ind) )
%   fprintf( '\n No data matched "%s" in the excel file' ...
%     , strjoin({xls_day, pl2_pre_post, pl2_region}, ', ') );
%   return;
% end

c_xls_channels = xls_channel_ns(xls_subset_ind);
c_xls_unit_uuids = xls_unit_uuid(xls_subset_ind);
c_xls_unit_ratings = xls_unit_rating(xls_subset_ind);
c_xls_unit_numbers = xls_unit_numbers(xls_subset_ind);
c_xls_regions = xls_regions(xls_subset_ind);

[~, I] = sort( c_xls_channels );
c_xls_channels = c_xls_channels(I);
c_xls_unit_uuids = c_xls_unit_uuids(I);
c_xls_unit_ratings = c_xls_unit_ratings(I);
c_xls_unit_numbers = c_xls_unit_numbers(I);
c_xls_regions = c_xls_regions(I);

c_xls_unique_channels = unique( c_xls_channels );
c_xls_first_channel = c_xls_unique_channels(1);

unit_data = readmda( fullfile(mda_dir, mda_file) );

ms_channel_ids = unit_data(1, :);
ms_spike_indices = unit_data(2, :);
ms_unit_ids = unit_data(3, :);
ms_unique_channels = unique( ms_channel_ids );

stp = 1;

for i = 1:numel(ms_unique_channels)
  c_channel = ms_unique_channels(i);
  ind_this_channel = ms_channel_ids == c_channel;
  unique_units_this_channel = unique( ms_unit_ids(ind_this_channel) );
  
  xls_channel = c_channel + c_xls_first_channel - 1;
  xls_ind_this_channel = c_xls_channels == xls_channel;
  
  if ( ~any(xls_ind_this_channel) )
    fprintf( '\n Warning: No units identified for channel "%d"', xls_channel );
  end
  
  for j = 1:numel(unique_units_this_channel)
    c_unit = unique_units_this_channel(j);
    
    c_unit_ind = ms_unit_ids == c_unit & ind_this_channel;
    
    c_xls_unit_ind = c_xls_unit_numbers == j & xls_ind_this_channel;
    
    c_xls_unit_str = sprintf( '"unit %d, channel %d"', j, xls_channel );
    
    if ( sum(c_xls_unit_ind) == 0 )
      fprintf( '\n Skipping %s', c_xls_unit_str );
      continue; 
    end
    
    assert( sum(c_xls_unit_ind) == 1, ['Expected to find 1 or 0 rows matching' ...
      , ' %s, for "%s" but found %d.'], c_xls_unit_str, mda_file, sum(c_xls_unit_ind) );
    
    c_ms_spike_indices = ms_spike_indices(c_unit_ind);
    
    unit_info = struct();
    unit_info.indices = { c_ms_spike_indices };
    unit_info.times = { (c_ms_spike_indices ./ sample_rate) + pl2_start_time };
    unit_info.start_time = pl2_start_time;
    unit_info.channel_number = xls_channel;
    unit_info.channel_str = dsp3.channel_n_to_str( 'SPK', xls_channel );
    unit_info.unit_uuid = c_xls_unit_uuids(c_xls_unit_ind);
    unit_info.unit_number = c_xls_unit_numbers(c_xls_unit_ind);
    unit_info.region = c_xls_regions(c_xls_unit_ind);
    unit_info.rating = c_xls_unit_ratings(c_xls_unit_ind);
    unit_info.session = pl2_session;
    unit_info.day = pl2_day;
    unit_info.pl2_file = pl2_filename;
    unit_info.mda_file = mda_file;
    
    if ( stp == 1 )
      all_units = unit_info;
    else
      all_units(stp) = unit_info;
    end
    
    stp = stp + 1;    
    
  end      
end

end