function [data, labels] = dsp3_anatomy_xls_to_data_and_labels(xls_raw)

header = xls_raw(1, :);

date_monk_ind = find_one_in_header( header, 'date' );
region_ind = find_one_in_header( header, 'region' );
channel_ind = find_one_in_header( header, 'channel' );
ml_ind = find_one_in_header( header, 'mlcorrect' );
ap_ind = find_one_in_header( header, 'ap' );
z_ind = find_one_in_header( header, 'z (' );

unit_inds = find_in_header( header, 'unit' );

remainder = xls_raw(2:end, :);

[dates, monkeys] = get_dates_monks( remainder(:, date_monk_ind) );
[channels, regions] = get_channels_regions( remainder(:, channel_ind), remainder(:, region_ind) );

labs = fcat.create( 'days', dates, 'monkeys', monkeys, 'channel', channels, 'region', regions );

ap_data = vertcat( remainder{:, ap_ind} );
ml_data = vertcat( remainder{:, ml_ind} );
z_data = vertcat( remainder{:, z_ind} );

unit_ids = cell2mat( remainder(:, unit_inds) );

[data, labels] = expand_unit_data( ap_data, ml_data, z_data, labs, unit_ids );

assert_ispair( data, labels );

end

function [data, labels] = expand_unit_data(ap, ml, z, labs, unit_ids)

max_n_units = size( unit_ids, 2 );
n_rows = size( unit_ids, 1 );

data = [];
labels = fcat.like( labs );
str_unit_ids = {};

for i = 1:n_rows
  for j = 1:max_n_units
    unit_id = unit_ids(i, j);
    
    if ( isnan(unit_id) )
      continue;
    end
    
    str_unit_id = sprintf( 'unit_uuid__%d', unit_id );
    
    data(end+1, :) = [ ap(i), ml(i), z(i) ];
    str_unit_ids{end+1} = str_unit_id;
    append( labels, labs, i );
  end
end

addcat( labels, 'unit_uuid' );
setcat( labels, 'unit_uuid', str_unit_ids );

end

function [channels, regions] = get_channels_regions(channel_col, region_col)

channels = cell( numel(channel_col), 1 );
regions = lower( region_col );

channel_col = vertcat( channel_col{:} );

assert( numel(regions) == numel(channel_col), 'Mismatching rows of channels and regions.' );

for i = 1:numel(channel_col)
  chan = channel_col(i);
  
  if ( chan < 10 )
    channels{i} = sprintf( 'SPK0%d', chan );
  else
    channels{i} = sprintf( 'SPK%d', chan );
  end
end

end

function [dates, monks] = get_dates_monks(date_monk_col)

dates = cell( numel(date_monk_col), 1 );
monks = cell( numel(date_monk_col), 1 );

is_space = @(x) x == 160; % x == ' ';
remove_space = @(x) x(~is_space(x));
only_alpha_and_underscores = @(x) x(isstrprop(x, 'alphanum') | x == '_');

for i = 1:numel(date_monk_col)
  current_row = strsplit( date_monk_col{i}, ' ' );
  current_row = cellfun( remove_space, current_row, 'un', 0 );
  current_row = cellfun( only_alpha_and_underscores, current_row, 'un', 0 );
  current_row(cellfun(@isempty, current_row)) = [];
  
  assert( numel(current_row) == 2, 'date-monkey pairs expected.' );
  
  is_date = cellfun( @(x) numel(x) == 13, current_row );
  
  assert( nnz(is_date) == 1, 'Improper date format; no match.' );
  
  dates{i} = current_row{is_date};
  monks{i} = current_row{~is_date};
end

end

function inds = find_one_in_header(header, substr)

inds = find_in_header( header, substr );

msg = 'Expected to find 1: "%s"; instead there were %d.';

assert( numel(inds) == 1, msg, substr, numel(inds) );

end

function inds = find_in_header(header, substr)

inds = find( cellfun(@(x) ~isempty(strfind(lower(x), substr)), header) );

end