classdef SpotTracker < handle   

properties
   
    spots_history = {};
    prev_spots_history = {};
    time_point = 1;
    
end
    
methods

    % constructor                 
    function o = SpotTracker()
        
        
    end
    
    % destructor
    function delete(o)
    end  
    
    function [spots, spots_amp, ld, spots_area] = detect_spots(o, data)
 
        wl_opts.waveletLevelThresh = 2; % threshold scale for local MAD thresholding
        wl_opts.waveletLevelAdapt = 1; % use adaptive setting for above.
        wl_opts.waveletNumLevels = 3;  % number of wavelet levels
        wl_opts.waveletLocalMAD = 0; % locally estimated MAD
        wl_opts.waveletBackSub = 0;  % background subtraction
        wl_opts.waveletMinLevel = 1; % discard wavelet levels below this

        wl_opts.waveletPrefilter = 0;
        wl_opts.debug.showWavelet = 0; 
        
        % [spots, spots_amp, ld, spots_area]
        [spots, spots_amp, ld, spots_area] = waveletSpots(data, wl_opts);        
       
    end    
    
    function spots = track(o, data)
        
        o.prev_spots_history = o.spots_history;
        
        [spots, spots_amp, ld, spots_area] = o.detect_spots(data);
        
        for spi = 1:size(spots, 1)
            
            sp = spots(spi, :);
            spa = spots_amp(spi);
            sp_area = spots_area(spi);

            identified = 0;

            for j = 1:numel(o.spots_history)

                spot_history = o.spots_history{j};

                last = spot_history(end, :);            
                last_pos = last(4:5);
                curr_pos = sp(1:2);

                d  = sqrt(sum((last_pos - curr_pos) .^ 2));
                td = i - last(1);

                if td < 5 && d < max_distance

                    spots_history{j} = [ spots_history{j}; [i spa sp_area sp] ];
                    identified = 1;

                end

            end

            if identified == 0
               spots_history{end + 1} = [o.time_point spa sp_area sp];
            end

        end

        spots = {};
        
        for spi = 1:numel(o.spots_history)
            
            sph = o.spots_history{spi};
            sp = sph(end, :);

            if i - sp(1) > 5
                continue
            end
            
            spots{end + 1} = [spi sp(2:5)];

        end
        
        o.time_point = o.time_point - 1;
        
    end

    function spots = retrack(o, data)
        o.spots_history = o.prev_spot_history(data);
        spots = o.track(data);
    end
    
    function on_analyze_single(o, button_object, event_data)
        o.run();
    end
    
    function on_analyze_all(o, ~, event_data)
        
        wait_bar = waitbar(0, 'Analyzing spots...');
        
        life_times = [];
        displacements = [];
        
        for xi = 1:size(o.xenapse_centers, 1)
            
            spots_history = o.analyze_xenapse(xi);

            
            for i = 1:numel(spots_history)
                sph = spots_history{i};

                life_time = sph(end, 1) - sph(1, 1);
                
                if life_time < 3
                    continue
                end
                
                life_times = [life_times life_time];
                
                path = sph(:, 4:5);
                max_displacement = 0;
                for j = 1:size(path, 1)
                    d = sqrt(sum((path(1, :) - path(j, :)) .^ 2));
                    if d > max_displacement
                        max_displacement = d;
                    end
                end
                displacements = [displacements max_displacement];
            end
            
            p = single(xi) / size(o.xenapse_centers, 1);
            waitbar(p, wait_bar);

            
        end

        close(wait_bar);
        
        f = figure;
        set(f, 'name', o.loaded_file_name, 'NumberTitle', 'off');
        h = histogram(life_times, 'FaceColor', 'g');
        
        % Calculate the min, max, mean, median, and standard deviation
        dmin = min(life_times);
        dmax = max(life_times);
        mn = mean(life_times);
        md = median(life_times);
        stdv = std(life_times);
        % Create the labels
        minlabel = sprintf('Min: %g', dmin);
        maxlabel = sprintf('Max: %g', dmax);
        mnlabel = sprintf('Mean: %g', mn);
        mdlabel = sprintf('Median: %g', md);
        stdlabel = sprintf('Std Deviation: %g', stdv);
        % Create the textbox
        h = annotation('textbox', [0.58 0.75 0.1 0.1]);
        set(h,'String',{minlabel, maxlabel, mnlabel, mdlabel, stdlabel});        

        f = figure;
        set(f, 'name', o.loaded_file_name, 'NumberTitle', 'off');
        
        h = histogram(displacements, 'FaceColor', 'r');

        % Calculate the min, max, mean, median, and standard deviation
        dmin = min(displacements);
        dmax = max(displacements);
        mn = mean(displacements);
        md = median(displacements);
        stdv = std(displacements);
        % Create the labels
        minlabel = sprintf('Min: %g', dmin);
        maxlabel = sprintf('Max: %g', dmax);
        mnlabel = sprintf('Mean: %g', mn);
        mdlabel = sprintf('Median: %g', md);
        stdlabel = sprintf('Std Deviation: %g', stdv);
        % Create the textbox
        h = annotation('textbox',[0.58 0.75 0.1 0.1]);
        set(h,'String', {minlabel, maxlabel, mnlabel, mdlabel, stdlabel});        
        
    end
        
    function spots_history = analyze_xenapse(o, xenapse_index)
    
        opts.waveletLevelThresh = 2; % threshold scale for local MAD thresholding
        opts.waveletLevelAdapt = 1; % use adaptive setting for above.
        opts.waveletNumLevels = 3;  % number of wavelet levels
        opts.waveletLocalMAD = 0; % locally estimated MAD
        opts.waveletBackSub = 0;  % background subtraction
        opts.waveletMinLevel = 1; % discard wavelet levels below this

        opts.waveletPrefilter = 0;
        opts.debug.showWavelet = 0;
     

        starting_frame = 20;

        rect = get_xenapse_rectangle(o, xenapse_index);
        rect = int32(rect);
        
        current = double(o.data(:, :, starting_frame));
        current = current(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)));
        bg = o.background(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)));

        current = current - bg;

        alpha = 0.2;

        spots_history = {};

        for i = starting_frame:size(o.data, 3)
            frame = double(o.data(:, :, i));
            frame = frame(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)));
            frame = frame - bg;

            frame = alpha * frame + (1.0 - alpha) * current;
            current = frame;
            
            [spots, spots_amp, ld, spots_area] = waveletSpots(frame, opts);

            max_distance = 2.;

            for spi = 1:size(spots, 1)
                sp = spots(spi, :);
                spa = spots_amp(spi);
                sp_area = spots_area(spi);

                identified = 0;

                for j = 1:numel(spots_history)

                    spot_history = spots_history{j};

                    last = spot_history(end, :);            
                    last_pos = last(4:5);
                    curr_pos = sp(1:2);

                    d  = sqrt(sum((last_pos - curr_pos) .^ 2));
                    td = i - last(1);

                    if td < 5 && d < max_distance

                        spots_history{j} = [ spots_history{j}; [i spa sp_area sp] ];
                        identified = 1;

                    end

                end

                if identified == 0
                   spots_history{end + 1} = [i spa sp_area sp];
                end

            end

        end

    end 
    
    
    function run(o)
    
        opts.waveletLevelThresh = 2; % threshold scale for local MAD thresholding
        opts.waveletLevelAdapt = 1; % use adaptive setting for above.
        opts.waveletNumLevels = 3;  % number of wavelet levels
        opts.waveletLocalMAD = 0; % locally estimated MAD
        opts.waveletBackSub = 0;  % background subtraction
        opts.waveletMinLevel = 1; % discard wavelet levels below this

        opts.waveletPrefilter = 0;
        opts.debug.showWavelet = 0;
     

        starting_frame = 20;

        rect = get_xenapse_rectangle(o, o.selected_xenapse);
        rect = int32(rect);
        
        current = double(o.data(:, :, starting_frame));
        current = current(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)));
        bg = o.background(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)));

        current = current - bg;

        alpha = 0.2;

        spots_history = {};

        for i = starting_frame:size(o.data, 3)
            frame = double(o.data(:, :, i));
            frame = frame(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)));
            frame = frame - bg;

            frame = alpha * frame + (1.0 - alpha) * current;
            current = frame;
            
            [spots, spots_amp, ld, spots_area] = waveletSpots(frame, opts);

            max_distance = 2.;

            for spi = 1:size(spots, 1)
                sp = spots(spi, :);
                spa = spots_amp(spi);
                sp_area = spots_area(spi);

                identified = 0;

                for j = 1:numel(spots_history)

                    spot_history = spots_history{j};

                    last = spot_history(end, :);            
                    last_pos = last(4:5);
                    curr_pos = sp(1:2);

                    d  = sqrt(sum((last_pos - curr_pos) .^ 2));
                    td = i - last(1);

                    if td < 5 && d < max_distance

                        spots_history{j} = [ spots_history{j}; [i spa sp_area sp] ];
                        identified = 1;

                    end

                end

                if identified == 0
                   spots_history{end + 1} = [i spa sp_area sp];
                end

            end

        end

        disp(size(spots_history));

        %quiver(x,y,u,v);
        figure;
        %65:100, 115:155
        xlim([1 40])
        ylim([1 35])
        ax = gca;
        ax.YDir = 'reverse';
        xlabel('pixels');
        ylabel('pixels');
        hold;
        
        life_times = [];
        displacements = [];
       
        for i = 1:numel(spots_history)
            sph = spots_history{i};

            path = sph(:, 4:5);
            
            max_displacement = 0;
            
            %path 
            
            for j = 1:size(path, 1)
                
                d = sqrt(sum((path(1, :) - path(j, :)) .^ 2));
                
                if d > max_displacement
                    max_displacement = d;
                end

            end

            displacements = [displacements max_displacement];
            
            life_time = sph(end, 1) - sph(1, 1);
            
            life_times = [life_times life_time];

            if life_time < 5
                continue
            end

            a = max(sph(:, 2));

            %disp(avg_a);
            %{
            if a < 0.005
                continue
            end
            %}

            x = path(:, 2);
            y = path(:, 1);
            plot(x, y);
            axis equal
        end

        figure;
        %65:100, 115:155
        xlim([1 40])
        ylim([1 35])
        ax = gca;
        ax.YDir = 'reverse';
        xlabel('pixels');
        ylabel('pixels');
        hold;

        for i = 1:numel(spots_history)

            sph = spots_history{i};

            path = sph(:, 4:5);

            life_time = sph(end, 1) - sph(1, 1) + 1;

            if life_time < 5
                continue
            end

            max_area = max(sph(:, 3));
            mean_area = mean(sph(:, 3));

            if max_area < 5
                continue
            end

            x = mean(path(:, 2));
            y = mean(path(:, 1));

            r = sqrt(mean_area / 3.14);


            cc =  min(0.8, 10. / life_time); 
            color = [cc, cc, cc, 1.0 - cc];

            c = draw_circle(x, y, r);

            c.FaceColor = color;
            c.EdgeColor = color;

            text_color = [1, 1, 1, 1.0 - cc];
            text(x, y, num2str(life_time), 'Color', text_color, 'HorizontalAlignment', 'center');   

        end
        
        figure;
        h = histogram(life_times)

        figure;
        h = histogram(displacements)
        
    end % method
    
end % methods

end % class