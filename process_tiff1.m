function process_tiff(fn, out_fn, sigma, remove_bkgd, temp_averaging)

    wait_bar = waitbar(0, 'Loading file...');

    info = imfinfo(fn);

    data = zeros(info(1).Height, info(1).Width, numel(info), 'single');
    for i = 1:numel(info)
        frame = imread(fn, i);
        data(:, :, i) = single(frame);
        if sigma > 0
            data(:, :, i) = imgaussfilt(data(:, :, i), sigma);
        end
        %data = cat(3, data, frame);
        p = single(i) / numel(info);
        waitbar(p, wait_bar);

    end
    
    close(wait_bar);    

    stim_start_frame = 50; 
    
    if temp_averaging > 0.0
        
        wait_bar = waitbar(0, 'Processing frames...');

        
        alpha = temp_averaging;
        current = data(:, :, 1);

        for i = 2:size(data, 3)
            frame = single(data(:, :, i));
            if (i == stim_start_frame) || (mod(i, stim_start_frame) == 0) 
                current = frame;
            else
                current = alpha * frame + (1.0 - alpha) * current;  
            end
            data(:, :, i) = current;
            p = single(i) / size(data, 3);
            waitbar(p, wait_bar);

        end

        close(wait_bar);    
            
    end
    
    t = mean(data(:, :, :), 3);
    mx = max(max(t));
    
    t = t / mx;
    
    level = graythresh(t);
    BW = imbinarize(t,level);
    BW = imfill(BW,'holes');
    BW = bwconvhull(BW,'objects');
    BW = imfill(BW,'holes');
    
    p = stim_start_frame;
    min_value = Inf;
    max_value = 0;
    for i = 1:(size(data, 3) - 1)
        frame = single(data(:, :, i));
        if (i == 1) || (mod(i, stim_start_frame) == 0) 
            sub = data(:, :, i:(i + p));
            minimum_values = min(sub, [], 3);
            maximum_values = max(sub, [], 3);
            l_min = min(min(minimum_values - frame));
            l_max = max(max(maximum_values - frame));
            
            min_value = min(min_value, l_min);
            max_value = max(max_value, l_max);
        end    

    end    
    
    start_frame = 1;
    
    %{
    if temp_averaging > 0.0
        
        start_frame = int32(1 / temp_averaging);
        
    end
    %}

    %bg = background;
    
    bg = data(:, :, 1);  
               
    for i = start_frame:size(data, 3)

        frame_data = data(:, :, i);
         
        if mod(i, stim_start_frame) == 0
           bg = data(:, :, i);             
        end
        
        %{
        if i >= stim_start_frame
           bg = background1; 
        end
        
        if i >= stim_start_frame*2
           bg = background2; 
        end
        %}
        
        %if remove_bkgd == 1
        frame_data = frame_data - bg;
        %end
        
        if min_value < 0
            frame_data = frame_data - min_value;
        end

        if remove_bkgd == 1
           
            frame_data(BW == 0) = 0;
            
        end
        
        frame_data = uint8((frame_data / (max_value - min_value)) * 255);

        %disp(max(max(frame_data)));
        
        if i == 1
            imwrite(frame_data, out_fn)
        else
            imwrite(frame_data, out_fn, 'WriteMode', 'append')
        end

    end
    
    
end