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
    
    if temp_averaging > 0.0
        
        wait_bar = waitbar(0, 'Processing frames...');

        
        alpha = temp_averaging;
        current = data(:, :, 1);

        for i = 2:size(data, 3)
            frame = single(data(:, :, i));
            current = alpha * frame + (1.0 - alpha) * current;  
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

    stim_start_frame = 50; 
    
    background = mean(data(:, :, 1:stim_start_frame), 3);
                    
    minimum_values = min(data, [], 3);
    min_value = min(min(minimum_values - background));
    
    start_frame = 1;
    
    if temp_averaging > 0.0
        
        start_frame = int32(1 / temp_averaging);
        
    end
    
    for i = start_frame:size(data, 3)

        frame_data = data(:, :, i);
                
        frame_data = frame_data - background;
        if min_value < 0
            frame_data = frame_data - min_value;
        end

        if remove_bkgd == 1
           
            frame_data(BW == 0) = 0;
            
        end
        
        frame_data = uint16(frame_data);

        if i == 1
            imwrite(frame_data, out_fn)
        else
            imwrite(frame_data, out_fn, 'WriteMode', 'append')
        end

    end
    
    
end