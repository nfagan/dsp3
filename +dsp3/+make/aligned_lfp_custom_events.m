function out = aligned_lfp_custom_events(files, picto_event_times, picto_event_labels, consolidated, varargin)

defaults = dsp3.make.defaults.aligned_lfp();
params = dsp3.parsestruct( defaults, varargin );

assert_ispair( picto_event_times, picto_event_labels );

lfp_file = shared_utils.general.get( files, 'lfp' );

align_ind = lfp_file.align_ind;
align_times = consolidated.align.data(align_ind, :);

plex_times = align_times(:, consolidated.align_key('plex'));
picto_times = align_times(:, consolidated.align_key('picto'));

min_session_t = min( lfp_file.t );
max_session_t = max( lfp_file.t );

picto_event_times(picto_event_times == 0) = nan;

plex_events = shared_utils.sync.cinterp( picto_event_times, picto_times, plex_times, true );
% Discard events that occur after the end of recording.
plex_events(plex_events > max_session_t) = nan;

span_t = params.max_t - params.min_t + params.window_size;
span_samples = round( span_t * lfp_file.sample_rate );

% Align start times to the middle of the window.
start_ts = plex_events + params.min_t - params.window_size/2;

% Determine whether the sampled window includes samples before the start of
% recording, or after the end of recording. 
start_offsets = start_ts - min_session_t;

has_full_start = start_offsets >= 0;
missing_full_start = start_offsets < 0;

start_offsets(has_full_start) = 0;
start_offsets(missing_full_start) = ...
  round( abs(start_offsets(missing_full_start)) * lfp_file.sample_rate );

start_inds = double( bfw.find_nearest(lfp_file.t, start_ts) );
% indices in find_nearest that occur before `min_session_t` will be 1;
% set them to 0.
start_inds(missing_full_start) = 0;
start_inds = start_inds + start_offsets;

stop_inds = start_inds + span_samples;

stop_offsets = numel( lfp_file.t ) - stop_inds;
has_full_stop = stop_offsets >= 0;
missing_full_stop = stop_offsets < 0;
stop_offsets(has_full_stop) = 0;
stop_offsets(missing_full_stop) = ...
  round( abs(stop_offsets(missing_full_stop)) * lfp_file.sample_rate );

lfp_values = lfp_file.lfp;

num_events = numel( plex_events );
num_channels = size( lfp_values, 1 );
aligned_mat = nan( num_events * num_channels, span_samples );

stp = 1;

for i = 1:num_channels
  for j = 1:num_events
    evt = plex_events(j);

    if ( isnan(evt) )
      stp = stp + 1;
      continue;
    end
    
    start_offset = start_offsets(j);
    stop_offset = stop_offsets(j);

    start_assign = start_offset + 1;
    stop_assign = span_samples - stop_offset;
    
    start_ind = start_inds(j) + start_offset;
    stop_ind = stop_inds(j) - stop_offset - 1;

    aligned_mat(stp, start_assign:stop_assign) = lfp_values(i, start_ind:stop_ind);
    stp = stp + 1;
  end
end

t_series = (0:(span_samples-1)) + params.min_t*lfp_file.sample_rate;

event_inds = repmat( reshape(1:num_events, [], 1), num_channels, 1 );

out = struct();
out.src_filename = lfp_file.src_filename;
out.params = params;
out.sample_rate = lfp_file.sample_rate;
out.data = aligned_mat;
out.t = t_series;
out.labels = make_labels( lfp_file, picto_event_labels, params );
out.has_partial_data = repmat( missing_full_stop | missing_full_start, num_channels, 1 );
out.event_ind = event_inds;

end

function labels = make_labels(lfp_file, event_labels, params)

labels = fcat();

evt_labs = fcat.from( event_labels );
base_labs = fcat.from( SparseLabels(lfp_file.labels) );
rmcat( base_labs, 'session' );

for i = 1:size(base_labs, 1)
  merge( evt_labs, prune(base_labs(i)) );
  append( labels, evt_labs );
end

addsetcat( labels, 'epoch', lower(params.event_name) );

end