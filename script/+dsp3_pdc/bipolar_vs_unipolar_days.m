function days = bipolar_vs_unipolar_days()

days = arrayfun( @(x) sprintf('day-%d', x), [35:43, 45, 47], 'un', 0 );

end