function [pl2_files, labels] = dsp3_get_signal_table_info()

db = dsp2.database.get_sqlite_db();

signal_info = db.get_fields( '*', 'signals' );
signal_fields = db.get_field_names( 'signals' );

required_fields = { 'session', 'channel', 'region', 'file' };

[exists, locs] = ismember( required_fields, signal_fields );
assert( all(exists) ...
  , 'Some required fields were missing from signal table.' );

pl2_files = signal_info(:, strcmp(signal_fields, 'file'));
labels = fcat.from( signal_info(:, locs), required_fields );

end