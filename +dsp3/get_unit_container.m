function unit_info = get_unit_container( units )

labs = arrayfun( @(x) dsp3.get_unit_labels(x), units, 'un', false );

unit_info = Container();

for i = 1:numel(labs)
  unit_info = append( unit_info, Container(units(i).times, labs{i}) );
end

end