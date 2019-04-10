classdef SpotTracker < handle

properties
   
    spots_history = {};
    prev_spots_history = {};
    active_spots = {};
    time_point = 1;
    madwc = 1.4826;
    %madwc = 0;
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
    
    function [spots, regions] = detect_spots(o, data)
 
        wl_opts.waveletLevelThresh = 2; % threshold scale for local MAD thresholding
        wl_opts.waveletLevelAdapt = 1; % use adaptive setting for above.
        wl_opts.waveletNumLevels = 3;  % number of wavelet levels
        wl_opts.waveletLocalMAD = 0; % locally estimated MAD
        wl_opts.waveletBackSub = 0;  % background subtraction
        wl_opts.waveletMinLevel = 1; % discard wavelet levels below this

        wl_opts.waveletPrefilter = 0;
        wl_opts.debug.showWavelet = 0; 
        
        % [spots, spots_amp, ld, spots_area]
        [spots_pos, spots_amp, ld, spots_area, regions] = waveletSpots(data, wl_opts, o.madwc);
        
        regions(regions <= 0) = 0.0;
        regions(regions > 0) = 1.0;
        regions = imfill(regions, 8, 'holes');
        regions = bwareaopen(regions, 4, 4);


        data(regions <= 0) = 0.0;



        %frame_data(regions > 0) = 1.0; 

        %frame_data(regions > 0) = 1.0; 

        d = - data;
        d(data == 0) = Inf;


        d = watershed(d);
        d(regions <= 0) = 0.0;
        data(d == 0) = 0;

        fdr = data;
        fdr = bwareaopen(fdr, 4, 4);
        fdr = imfill(fdr, 8, 'holes');
        
        regions = fdr;
        
        spots = regionprops(regions > 0, regions, 'Centroid', 'MeanIntensity', 'Area');
        spots_amp = vertcat(spots.MeanIntensity);
        spots_area = vertcat(spots.Area);
        spots_pos = vertcat(spots.Centroid);

        spots = {};
        
        for i = 1:numel(spots_amp)
            
            spots{end + 1} = [i spots_pos(i, :) spots_amp(i) spots_area(i) ];

        end
        
    end    
    
    function clear_history(o)
       o.spots_history = {}; 
       o.active_spots = {};
    end
    
    function [spots, regions] = track(o, data)
        
        o.prev_spots_history = o.spots_history;
        
        [spots, regions] = o.detect_spots(data);
        
        new_active_spots = {};
        
        for spi = 1:numel(spots)
                        
            s = spots{spi};
            spa = s(4);
            sp_area = s(5);

            identified = 0;

            %for j = 1:numel(o.prev_spots_history)
            
            % identify spots
            
            min_distance = Inf;
            closest_ai = 0;
            
            for ai = 1:numel(o.active_spots)

                j = o.active_spots{ai};

                spot_history = o.prev_spots_history{j};

                last = spot_history(end, :);            
                td = o.time_point - last(1);
                
                if td >= o.inertia
                    continue
                end
                
                last_pos = last(2:3);
                curr_pos = s(2:3);

                d  = sqrt(sum((last_pos - curr_pos) .^ 2));
                
                if d < min_distance
                    
                    min_distance = d;
                    closest_ai = ai;
                    
                end
                
            end
            
            if min_distance < o.max_distance

                j = o.active_spots{closest_ai};
                o.spots_history{j} = [ o.spots_history{j}; [o.time_point s(2:3) spa sp_area] ];
                %o.active_spots{closest_ai} = [];
                identified = 1;

            end
            

            % tossed differently?
            if identified == 0
               o.spots_history{end + 1} = [o.time_point s(2:3) spa sp_area];
               new_active_spots{end + 1} = numel(o.spots_history);
            end

        end
        
        % get rid of old spots
        for ai = 1:numel(o.active_spots)

            j = o.active_spots{ai};      

            spot_history = o.spots_history{j};

            last = spot_history(end, :);            
            td = o.time_point - last(1);
                
            if td < o.inertia
                new_active_spots{end + 1} = j;
            end
            
        end
        
        spots = {};
        
        for ai = 1:numel(new_active_spots)
            
            spi = new_active_spots{ai};
            sph = o.spots_history{spi};
            last = sph(end, :);
            
            td = o.time_point - last(1);

            if td > 0
                continue;
            end
            
            spots{end + 1} = [spi last(2:5)];

        end
        
        o.time_point = o.time_point + 1;
        o.active_spots = new_active_spots;
        
    end

    function spots = retrack(o, data)
        % BUGGED restore active spots
        o.spots_history = o.prev_spot_history(data);
        spots = o.track(data);
    end
        
end % methods

end % class