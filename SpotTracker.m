classdef SpotTracker < handle   

properties
   
    spots_history = {};
    prev_spots_history = {};
    time_point = 1;
    madwc = 1.4826;
    max_distance = 2.0;
    inertia = 5.0;
    
end
    
methods

    % constructor                 
    function o = SpotTracker()
        
        
    end
    
    % destructor
    function delete(o)
    end  
    
    function spots = detect_spots(o, data)
 
        wl_opts.waveletLevelThresh = 2; % threshold scale for local MAD thresholding
        wl_opts.waveletLevelAdapt = 1; % use adaptive setting for above.
        wl_opts.waveletNumLevels = 3;  % number of wavelet levels
        wl_opts.waveletLocalMAD = 0; % locally estimated MAD
        wl_opts.waveletBackSub = 0;  % background subtraction
        wl_opts.waveletMinLevel = 1; % discard wavelet levels below this

        wl_opts.waveletPrefilter = 0;
        wl_opts.debug.showWavelet = 0; 
        
        % [spots, spots_amp, ld, spots_area]
        [spots_pos, spots_amp, ld, spots_area] = waveletSpots(data, wl_opts, o.madwc);
        
        spots = {};
        
        for i = 1:numel(spots_amp)
            
            spots{end + 1} = [i spots_pos(i, :) spots_amp(i) spots_area(i) ];

        end
        
    end    
    
    function clear_history(o)
       o.spots_history = {}; 
    end
    
    function spots = track(o, data)
        
        o.prev_spots_history = o.spots_history;
        
        spots = o.detect_spots(data);
        
        for spi = 1:numel(spots)
            
            s = spots{spi};
            spa = s(4);
            sp_area = s(5);

            identified = 0;

            for j = 1:numel(o.prev_spots_history)

                spot_history = o.prev_spots_history{j};

                last = spot_history(end, :);            
                last_pos = last(2:3);
                curr_pos = s(2:3);

                d  = sqrt(sum((last_pos - curr_pos) .^ 2));
                td = o.time_point - last(1);

                if td < o.inertia && d < o.max_distance

                    o.spots_history{j} = [ o.spots_history{j}; [o.time_point s(2:3) spa sp_area] ];
                    identified = 1;
                    break;

                end

            end

            if identified == 0
               o.spots_history{end + 1} = [o.time_point s(2:3) spa sp_area];
            end

        end

        spots = {};
        
        for spi = 1:numel(o.spots_history)
            
            sph = o.spots_history{spi};
            sp = sph(end, :);

            if o.time_point - sp(1) > o.inertia
                continue
            end
            
            spots{end + 1} = [spi sp(2:5)];

        end
        
        o.time_point = o.time_point + 1;
        
    end

    function spots = retrack(o, data)
        o.spots_history = o.prev_spot_history(data);
        spots = o.track(data);
    end
        
end % methods

end % class