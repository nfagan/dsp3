function out = dsp3_make_lfp_file(pl2_file, consolidated)

pl2_filename = shared_utils.io.filenames( pl2_file, true );
  
consolidated_pl2_files = consolidated.pl2_info.files;
pl2_ind = find( strcmp(consolidated_pl2_files, pl2_filename) );

assert( numel(pl2_ind) == 1, 'No or more than 1 match for "%s".', pl2_filename );

channel_region_info = consolidated.pl2_info.channel_map(pl2_filename);
num_channels_total = sum( arrayfun(@(x) numel(x.channels), channel_region_info) );
stp = 1;

matching_session = consolidated.pl2_info.sessions{pl2_ind};
session_start = consolidated.pl2_info.start_times(pl2_ind);

align_ind = find( where(consolidated.align, matching_session) );
assert( ~isempty(align_ind), 'No align data for session: "%s".', matching_session );

event_ind = find( where(consolidated.events, matching_session) );
assert( ~isempty(event_ind), 'No event data for session: "%s".', matching_session );

matching_events = consolidated.events.only(matching_session);
non_zero_events = matching_events.data ~= 0;
matching_event_times = reshape( matching_events.data(non_zero_events), [], 1 );

first_event_time = min( matching_event_times );
last_event_time = max( matching_event_times );

align_times = consolidated.align.data(align_ind, :);
plex_align_times = align_times(:, consolidated.align_key('plex'));
picto_align_times = align_times(:, consolidated.align_key('picto'));

assert( first_event_time > min(picto_align_times), 'First event time before first align time.' );

region_strs = {};
channel_strs = {};
channel_nums = [];
sample_rate = [];

is_first = true;

for i = 1:numel(channel_region_info)
  region = channel_region_info(i).region;
  channels = channel_region_info(i).channels;
  
  for j = 1:numel(channels)
    channel_str = dsp3.channel_n_to_str( 'FP', channels(j) ); 
    
    raw_data = PL2Ad( pl2_file, channel_str );
    
    if ( is_first )
      all_region_data = nan( num_channels_total, numel(raw_data.Values) );
      t = (0:numel(raw_data.Values)-1) * 1 / raw_data.ADFreq + session_start;
      sample_rate = raw_data.ADFreq;
      is_first = false;
    end
    
    all_region_data(stp, :) = raw_data.Values;
    stp = stp + 1;

    region_strs{end+1, 1} = region;
    channel_strs{end+1, 1} = channel_str;
    channel_nums(end+1, 1) = channels(j);
  end
end

labels = struct();
labels.region = region_strs;
labels.channel = channel_strs;
labels.session = repmat( {matching_session}, size(region_strs) );
labels.pl2 = repmat( {pl2_filename}, size(region_strs) );

out = struct();
out.labels = labels;
out.channel_nums = channel_nums;
out.lfp = all_region_data;
out.t = t;
out.sample_rate = sample_rate;
out.align_ind = align_ind;
out.event_ind = event_ind;
out.src_filepath = pl2_file;
out.src_filename = pl2_filename;

end