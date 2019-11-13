classdef PeakTracker < handle

properties
   
    spots_history = {};
    prev_spots_history = {};
    active_spots = {};
    time_point = 1;
    %madwc = 1.4826;
    max_distance = 4.0;
    inertia = 3.0;
    prominence_threshold = 0;
    
end
    
methods

    % constructor                 
    function o = PeakTracker()
        
        
    end
    
    % destructor
    function delete(o)
    end  
    
    function [spots, regions] = detect_spots(o, data)
 
        data = flipud(data);
        
        column_peaks = zeros(size(data));
        column_proms = zeros(size(data));
        row_peaks = zeros(size(data));
        row_proms = zeros(size(data));
        
        for i = 1:size(data, 1)
            column = data(i, :);
            [pks, locs, widths, proms] = findpeaks(column);
            for j = 1:numel(pks)                
                column_peaks(i, locs(j)) = 1;
                column_proms(i, locs(j)) = proms(j);                
            end
        end
        
        for i = 1:size(data, 2)
            row = data(:, i);
            [pks, locs, widths, proms] = findpeaks(row);
            for j = 1:numel(pks)                
                row_peaks(locs(j), i) = 1;
                row_proms(locs(j), i) = proms(j);                
            end
        end
        
        peaks = column_peaks & row_peaks;
        %peaks = column_peaks;
        proms = max(column_proms, row_proms);
        
        peaks = find(peaks ~= 0);

        spots = {};
        
        for i = 1:numel(peaks)
           
            v = int64(peaks(i));
            
            [y, x] = ind2sub(size(proms), v);
            
            if x == 1 || y == 1 || x == size(data, 2) || y == size(data, 1)
               continue; 
            end
           
            %{
            if proms(y, x) < 2*sigma(y, x)
                continue;
            end
            %}
            
            spots{end + 1} = double([i y x proms(y, x) 1.0 ]);
            
        end        
        
        regions = [];
        
    end    
    
    function clear_history(o)
       o.spots_history = {}; 
       o.active_spots = {};
    end
    
    function [spots, regions] = track(o, data)
        
        o.prev_spots_history = o.spots_history;
        
        [spots, regions] = o.detect_spots(data);
        
        new_active_spots = {};
        identified_active_spots = zeros(1, numel(o.active_spots));
        
        for spi = 1:numel(spots)
                        
            s = spots{spi};
            spa = s(4);
            
            if spa < o.prominence_threshold
                continue;
            end
            
            sp_area = s(5);

            identified = 0;

            %for j = 1:numel(o.prev_spots_history)
            
            % identify spots
            
            max_age = -Inf;
            closest_ai = 0;
            
            
            
            for ai = 1:numel(o.active_spots)

                j = o.active_spots{ai};

                spot_history = o.prev_spots_history{j};

                last = spot_history(end, :);            
                first = spot_history(1, :);            
                td = o.time_point - last(1);
                age = o.time_point - first(1);
                
                if td > o.inertia
                    continue;
                end
                
                last_pos = last(2:3);
                curr_pos = s(2:3);

                d  = sqrt(sum((last_pos - curr_pos) .^ 2));
                
                %{
                if d < min_distance
                    
                    min_distance = d;
                    closest_ai = ai;
                    
                end
                %}

                
                
                if d < o.max_distance && age > max_age
                    
                    %min_distance = d;
                    max_age = age;
                    closest_ai = ai;
                    
                end
                
            end
            
            %if min_distance < o.max_distance
            if closest_ai > 0

                j = o.active_spots{closest_ai};
                
                h = o.spots_history{j};
                last = h(end, :);            
                
                if last(1) == o.time_point
                   last(2) = last(2) + s(2);
                   last(3) = last(3) + s(3);
                   o.spots_history{j}(end, :) = last;
                else
                    o.spots_history{j} = [ o.spots_history{j}; [o.time_point s(2:3) spa sp_area] ];                
                end    
                
                identified_active_spots(closest_ai) = identified_active_spots(closest_ai) + 1;
                
                %o.active_spots{closest_ai} = [];
                identified = 1;

            end
            

            % tossed differently?
            if identified == 0
               o.spots_history{end + 1} = [o.time_point s(2:3) spa sp_area];
               new_active_spots{end + 1} = numel(o.spots_history);
            end

        end
        
        % average multiple identifications
        
        for ai = 1:numel(o.active_spots)
        
            ni = identified_active_spots(ai);
            
            if ni < 2
                continue;
            end

            j = o.active_spots{ai};
            h = o.spots_history{j};
            
            last = h(end, :);            

            last(2) = last(2) / double(ni);
            last(3) = last(3) / double(ni);

            o.spots_history{j}(end, :) = last;
                        
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