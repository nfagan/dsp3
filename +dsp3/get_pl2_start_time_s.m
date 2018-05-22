function start_time_sec = get_pl2_start_time_s( pl2_file )

pl2_file = PL2GetFileIndex( pl2_file );
tick_start = pl2_file.StartRecordingTimeTicks; % get start time of recording in ticks
pl2_recording_time = pl2_file.DurationOfRecordingSec; % get length of recording time in s
tick_duration = pl2_file.DurationOfRecordingTicks; % get length of recording in ticks
factor = tick_duration/pl2_recording_time; % find the factor by which to convert start time to s
start_time_sec = tick_start/factor; % converted to seconds

end