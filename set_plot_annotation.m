function set_plot_annotation(data)

    % Calculate the min, max, mean, median, and standard deviation
    dmin = min(data);
    dmax = max(data);
    mn = mean(data);
    md = median(data);
    stdv = std(data);
    % Create the labels
    n = sprintf('N: %d', numel(data));
    minlabel = sprintf('Min: %g', dmin);
    maxlabel = sprintf('Max: %g', dmax);
    mnlabel = sprintf('Mean: %g', mn);
    mdlabel = sprintf('Median: %g', md);
    stdlabel = sprintf('Std Deviation: %g', stdv);
    % Create the textbox
    h = annotation('textbox', [0.58 0.75 0.1 0.1]);
    set(h,'String', { n, minlabel, maxlabel, mnlabel, mdlabel, stdlabel });        

end   