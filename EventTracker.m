classdef EventTracker < handle

properties
   
    spots_history = {};
    
end
    
methods

    % constructor                 
    function o = EventTracker()
        
        
    end
    
    % destructor
    function delete(o)
    end  
    
    function [spots_history, regions, sigma] = detect_events(o, data, subtract_background, lowpass_filtering, stim_start_frame)

        spots_history = {};
        regions = {};
        xenapse_data = data;      

        start_frame = 1;
        
        for i = start_frame:size(xenapse_data, 3)

            frame = xenapse_data(:, :, i);
        
            if lowpass_filtering == 1
    
                frame = imgaussfilt(frame, 2.0);
                
                %frame = o.lowpass_wavelet_filter(frame);

            end
            
            xenapse_data(:, :, i) = frame;
            
        end
        
        if subtract_background
            
            %o.get_stim_start_frame();
            %bg = o.background(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)));
            
            if stim_start_frame ~= 0
                bg = mean(xenapse_data(:, :, 1:stim_start_frame), 3);
                %bg = mean(xenapse_data(:, :, :), 3);
            else
                bg = zeros(size(xenapse_data, 1), size(xenapse_data, 2));
            end            
            
            xenapse_data = xenapse_data - bg;
            
        end
 
        sigma = mean(mean(std(xenapse_data(:, :, 1:stim_start_frame), 0, 3)));

        data_3d = xenapse_data;
        
        data_3d = imbinarize(xenapse_data, 3*sigma);
        data_3d = imfill(data_3d, 6, 'holes');

        
        for i = 1:size(xenapse_data, 3)

            ws_data = xenapse_data(:, :, i);
            d_3d = data_3d(:, :, i);
            
            ws_data(d_3d <= 0) = 0.0;
            d = - ws_data;
            d(ws_data == 0) = Inf;
            d = watershed(d);
            d(d_3d <= 0) = 0.0;
            d_3d(d == 0) = 0;   
            data_3d(:, :, i) = d_3d;
            
        end
        
        
        % do watersched 3d
            
       
        %{
        ws_data = xenapse_data;
        
        ws_data(data_3d <= 0) = 0.0;
        d = - ws_data;
        d(ws_data == 0) = Inf;
        d = watershed(d, 26);
        d(data_3d <= 0) = 0.0;
        data_3d(d == 0) = 0;        
        %}
        
        se = strel('sphere', 3);
        se = strel(se.Neighborhood(:, :, 4));
        %se = strel(se.Neighborhood(:, :, 3:5));
        %se = offsetstrel('ball', 2, 3)
        data_3d = imerode(data_3d, se);
        data_3d = imdilate(data_3d, se);
        
        
        
        %data_3d = imopen(data_3d, se);
        
        %data_3d = bwconvhull(data_3d, 'objects');
        data_3d = imfill(data_3d, 6, 'holes');
        
        
        cc = bwconncomp(data_3d, 6);
        
        lifetime = [];
        latency = [];
        
        props = regionprops(cc, 'Image', 'BoundingBox');
        
        for i = 1:numel(cc.PixelIdxList)
        
           pixels = cc.PixelIdxList{i};
           
           [x, y, z] = ind2sub(size(data_3d), pixels);
    
           lt = max(z) - min(z) + 1;
           lat = min(z);
           
           %if lt < 50
           %    continue;
           %end
           
           
           fi = props(i).Image;
           bb = uint32(props(i).BoundingBox);
           
           spot = [];
           
           for k = bb(3):(bb(3) + bb(6) - 1)
               
               frame = xenapse_data(:, :, k);
               fi_z = fi(:, :, k - bb(3) + 1);
               mask = zeros(size(frame));
               mask(bb(2):(bb(2) + bb(5) - 1), bb(1):(bb(1) + bb(4) - 1)) = fi_z;
               frame(mask <= 0) = 0;

               frame = flipud(frame);
               
               matrix = frame;
               matrix = matrix / sum(matrix(:));
               [m,n] = size(matrix);
               [I, J] = ndgrid(1:m,1:n);
               centroid = [dot(I(:), matrix(:)),  dot(J(:), matrix(:))];             
               
               amplitude = max(max(frame));
               area = nnz(mask);
               
               % o.time_point s(2:3) spa sp_area
               
               spot = [spot; double(k) centroid amplitude area];
               
           end

           spots_history{end + 1} = double(spot);
           
           %vis3D(fi, 'bicubic');
           
           %{
           [x y z] = ind2sub(size(fi), find(fi));
           figure;
           plot3(x, y, z, 'k.');
           %}
          
           %lifetime = [lifetime; lt];
           %latency = [latency; lat];
            
        end
        
        
    end
        
end % methods

end % class