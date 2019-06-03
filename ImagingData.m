classdef ImagingData < handle   
properties
        
    xenapse_centers = 0;
    xenapse_radii = 0;
    xenapse_metric = 0;    
    responded_xenapses = 0;
    
    selected_xenapse = 1;
    
    xenapse_circles = 0;
    selected_xenapse_rectangle = 0;
    
    xenapse_size_extension = 1.3;
    
    original_data = 0;
    data = 0;
    background = 0;
    frame_rate = 100;
    pixel_size = 160;
    %stimulation_start = 0.5;
    %stimulation_start = 0.0;  
    stimulation_start = 0.5;     
    temporal_averaging_alpha = 0.2;
    
    min_life_time = 0.5;
    
    spot_tracker = 0;
    peak_tracker = 0;
        
    spot_circles = {};
    spot_texts = {};
    
    loaded_file_name = 0;

    min_value = 0;
    
end
    
methods

    % constructor
                 
    function o = ImagingData()        
    end
    
    % destructor
    
    function delete(o)
    end          
        
    function r = lowpass_wavelet_filter(o, image)
       
        r = imgaussfilt(image, 2.0);
        
        %{
        total_levels = 2;
        level = 1;
        n = prod( size(image) );
        Ib = image;
        [C,S] = wavedec2(Ib,total_levels,'bior3.7');
        DH = detcoef2('all',C,S,level);% extract details coefficient from level 1
        DH = DH(:);
        delta = median( abs(DH) ) / 0.6745;
        %delta = median( abs(DH) ) / 0.0001;
        thr = delta * sqrt(2*log(n));
        NC = wthcoef2('t',C,S,level,thr,'s'); % i use the soft threshold
        r = waverec2(NC, S, 'bior3.7');
        %}
        
    end
        
    function r = get_stim_start_frame(o) 
    
        r = round(o.stimulation_start * o.frame_rate + 1, 0);

    end
    
    function prepare_processed_data(o, temporal_averaging)
                
        ta = temporal_averaging;
        %ta = 0;
        
        if ta == 0
            o.data = o.original_data;
        else
            
            wait_bar = waitbar(0, 'Processing frames...');

            alpha = temporal_averaging;
            current = o.original_data(:, :, 1);
            
            o.data = o.original_data;
            
            for i = 2:size(o.original_data, 3)
                frame = single(o.data(:, :, i));
                
                %frame = imgaussfilt(frame, 1.0);

                        
                current = alpha * frame + (1.0 - alpha) * current;  
                o.data(:, :, i) = current;
                p = single(i) / size(o.original_data, 3);
                waitbar(p, wait_bar);
                
            end
            
            close(wait_bar);
                    
        end
     
        stim_start_frame = o.get_stim_start_frame();
        if stim_start_frame ~= 0
            
            %o.background = mean(o.data(:, :, 1:stim_start_frame), 3);
            
            o.background = mean(o.data(:, :, :), 3);
            
            minimum_values = min(o.data, [], 3);
                     
            o.min_value = min(min(minimum_values - o.background));
            
            %o.min_value = 0; 
            
            %o.background = mean(o.data(:, :, :), 3);
        else
            o.background = zeros(size(o.data, 1), size(o.data, 2));
        end
    
        %{
        for i = 1:size(o.data, 3)
    
            frame_data = o.data(:, :, i);
            frame_data = frame_data - o.background;
            if o.min_value < 0
                frame_data = frame_data - o.min_value;
            end
            
            frame_data = uint16(frame_data);
        
            if i == 1
                imwrite(frame_data, 'out_ctrl.tif')
            else
                imwrite(frame_data, 'out_ctrl.tif', 'WriteMode', 'append')
            end
            
        end
        %}
        

        
    end
    
    function r = get_xenapse_rectangle(o, xenapse_index)
        
        center = o.xenapse_centers(xenapse_index, :);
        radius = o.xenapse_radii(xenapse_index);
       
        rs = radius * 2 * o.xenapse_size_extension;
        hs = rs / 2;
       
        max_x = size(o.data, 1);
        max_y = size(o.data, 2);
        bottom = max(center(1) - hs, 1);
        left = max(center(2) - hs, 1);
        
        r = [bottom left min(rs, max_y - bottom) min(rs, max_x - left) ];
        
        %r = [center(1) - hs center(2) - hs rs rs];
        
    end
    
    
    function load(o, fn, temporal_averaging)
     

        o.selected_xenapse = 1;
        
        o.loaded_file_name = fn;
                
        wait_bar = waitbar(0, 'Loading file...');
        
        info = imfinfo(fn);
        
        data = zeros(info(1).Height, info(1).Width, numel(info), 'single');
        for i = 1:numel(info)
            frame = imread(fn, i);
            data(:, :, i) = single(frame);
            
            %data = cat(3, data, frame);

            p = single(i) / numel(info);
            waitbar(p, wait_bar);
                
        end
        
        depth = info(1).BitDepth;
        
        data = single(data);  
        data = data - single(min(min(min(data))));
        data = single(data) / single(max(max(max(data))));
        
        total_mean = mean(data(:, :, :), 3);
        
        mean_value = mean(mean(total_mean));
        
        t = total_mean;
        %t(t < mean_value) = 0;
        
        %t = o.lowpass_wavelet_filter(t);
        
        level = graythresh(t);
        BW = imbinarize(t,level);
        BW = imfill(BW,'holes');
        
        se = strel('disk',5);
        BW = imopen(BW, se);
        
        BW = bwconvhull(BW,'objects');
        BW = imfill(BW,'holes');
        CC = bwconncomp(BW);
        S = regionprops(CC,'Centroid');
        ma = regionprops(CC,'MajorAxisLength');
      
        centers = [];
        radii = [];
        
        for i = 1:numel(S)
            
            s = S(i);
            s = s.Centroid;
            
            m = ma(i);
            m = m.MajorAxisLength;
            
            if m < 20
                continue;
            end
            
            centers = [centers; s];
            radii = [radii; (m / 2)];
                            
        end
        

        
        
        %figure;
        %imshow(BW);
      
        %{
        total_levels = 2;
        level = 1;
        n = prod( size(total_mean) );
        Ib = total_mean;
        [C,S] = wavedec2(Ib,total_levels,'bior3.7');
        DH = detcoef2('all',C,S,level);% extract details coefficient from level 1
        DH = DH(:);
        delta = median( abs(DH) ) / 0.6745;
        %delta = median( abs(DH) ) / 0.0001;
        thr = delta * sqrt(2*log(n));
        NC = wthcoef2('t',C,S,level,thr,'s'); % i use the soft threshold
        X = waverec2(NC, S, 'bior3.7');
        %figure;
        %imagesc(Ib); title('Noisy Image'); colormap gray;
        %figure;
        %imagesc(X); title('Denoised 1st level coeffs'); colormap gray;        
        
        
        mean_value = mean(mean(X));
        
        t = X;
        %t(t < mean_value*1) = 0;
        
        figure;
        imshow(t);
        
        %}
        
        
        
        %data = data / (2^(depth - 8));
       
        %set(o.general_view_axes, 'Visible', 'off'); % imagesc makes axes visible again!       
        
        %[centers, radii, metric] = imfindcircles(total_mean, [7 22], 'ObjectPolarity', 'bright');
        %[centers, radii, metric] = imfindcircles(total_mean, [7 22], 'ObjectPolarity', 'bright');
        o.xenapse_centers = centers; 
        o.xenapse_radii = radii;
        o.xenapse_radii(:) = mean(o.xenapse_radii);
        %o.xenapse_metric = metric;
        
        o.original_data = data;
        o.data = data;
        
        close(wait_bar);
        
        o.prepare_processed_data(temporal_averaging);        

        o.responded_xenapses = zeros(size(o.xenapse_centers, 1), 1);
        
        for i = 1:size(o.xenapse_centers, 1)
            
            rect = get_xenapse_rectangle(o, i);
            rect = int32(rect);

            data = o.data(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)), :);
            
            intensity = mean(data, [1, 2]);
            intensity = imgaussfilt(squeeze(intensity), 100.0);
            [pks, locs, widths, proms] = findpeaks(intensity);
            
            if numel(pks) == 0
                continue;
            end
            
            [argvalue, argmax] = max(pks);
            
            time = locs(argmax) / o.frame_rate; 
            
            if time > o.stimulation_start + 1 && time < o.stimulation_start + 5
               
                o.responded_xenapses(i) = 1;
                
            end
        
        end
                        
    end

    function [spots_history, intensity, sigma] = analyze_xenapse(o, xenapse_index, waitbar_object, current_progress, total_work, subtract_background, lowpass_filtering)

        rect = get_xenapse_rectangle(o, xenapse_index);
        rect = int32(rect);
                
        if subtract_background
            start_frame = o.get_stim_start_frame();
            bg = o.background(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)));
        else
            start_frame = 1;
        end
        
        intensity = [];     
        
        for i = start_frame:size(o.data, 3)
                        
            frame = single(o.data(:, :, i));
            frame = frame(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)));

            if subtract_background == 1

                frame = frame - bg;
                %frame = frame + 1;

            end
                
            if lowpass_filtering == 1

                frame = o.lowpass_wavelet_filter(frame);

            end
            
            intensity = [intensity mean(mean(frame))];     
            
            %{
            if o.get_do_track()    
                tracker.track(frame);
            end
            %}
            
            %disp(tracker.spots_history{6});            
            
            waitbar(single(current_progress) / total_work, waitbar_object);
            current_progress = current_progress + 1;

        end
        
        %spots_history = tracker.spots_history;
        %spots_history = o.find_events(xenapse_index);

        rect = get_xenapse_rectangle(o, xenapse_index);
        rect = int32(rect);
        
        xenapse_data = o.data(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)), :);      
        
        event_tracker = EventTracker();
        
        stim_start_frame = o.get_stim_start_frame();
                    
        prominent_spots = {};
        [spots_history, ~, sigma] = event_tracker.detect_events(xenapse_data, subtract_background, lowpass_filtering, stim_start_frame);
        
        for i = 1:numel(spots_history)
            
            h = spots_history{i};
            
            %{
            max_prominence = max(h(:, 4));
            
            if max_prominence < 3*sigma
                continue;
            end
            %}

            latency = h(1, 1);
            latency_s = single(latency) / o.frame_rate;  
            
            %if latency_s > 5
            %    continue;                
            %end
            
            
            life_time = h(end, 1) - h(1, 1) + 1;
            life_time_s = single(life_time) / o.frame_rate;  
            
            if life_time_s < o.min_life_time
                continue;
            end
                        
            prominent_spots{end + 1} = h;
            
        end
        
        spots_history = prominent_spots;
        
    end 
    
    function [intensities, all_spots_history] = analyze_xenapses(o, indices, subtract_background, lowpass_filtering)

        wait_bar = waitbar(0, 'Analyzing events...');

        if subtract_background ~= 0
            start_frame = o.get_stim_start_frame();
        else
            start_frame = 1;
        end
        
        total_frames_to_analyze = size(o.data, 3) - start_frame + 1;
        total_work = total_frames_to_analyze * numel(indices);
        current_progress = 1;
        
        life_times = [];
        displacements = [];
        
        intensities = [];
        latencies = [];

        all_spots_history = {};
        
        for k = 1:numel(indices)
            
            xi = indices(k);
            
            [spots_history, intensity, sigma] = o.analyze_xenapse(xi, wait_bar, current_progress, total_work, subtract_background, lowpass_filtering);
           
            all_spots_history{end + 1} = struct('events', spots_history, 'sigma', sigma);
            
            current_progress = current_progress + total_frames_to_analyze;

            intensities = [intensities; intensity];
            
            for i = 1:numel(spots_history)
                
                sph = spots_history{i};

                latency = sph(1, 1);
                                  
                latencies = [latencies latency];
                                
                life_time = sph(end, 1) - sph(1, 1) + 1;
                life_times = [life_times life_time];
                
                path = sph(:, 2:3);
                max_displacement = 0;
                for j = 1:size(path, 1)
                    d = sqrt(sum((path(1, :) - path(j, :)) .^ 2));
                    if d > max_displacement
                        max_displacement = d;
                    end
                end
                displacements = [displacements max_displacement];
                
            end
                        
        end

        close(wait_bar);

    end
    
        
end % methods

end % class