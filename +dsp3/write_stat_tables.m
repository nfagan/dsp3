function write_stat_tables(tables, labels, pathstr, filenames_are)

if ( iscell(tables) )
  for i = 1:numel(tables)  
    if ( iscell(labels) )
      labs = copy( labels{i} );
    else
      labs = labels(i);
    end
    
    dsp3.savetbl( tables{i}, pathstr, prune(labs), filenames_are );
  end
else
  dsp3.savetbl( tables, pathstr, prune(labels), filenames_are );
end

end