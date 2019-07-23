function [spikes, events, event_key] = load_linearized_sua(conf)

if ( nargin < 1 || isempty(conf) )
  conf = dsp3.config.load();
end

consolidated = dsp3.get_consolidated_data( conf );
sua = dsp3_ct.load_sua_data( conf );

[spike_ts, spike_labels, event_ts, event_labels] = dsp3_ct.linearize_sua( sua );
event_ts(event_ts == 0) = nan;

spikes = mkpair( spike_ts, spike_labels );
events = mkpair( event_ts, event_labels );

event_key = consolidated.event_key;

end

