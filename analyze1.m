
opts.waveletLevelThresh = 2; % threshold scale for local MAD thresholding
opts.waveletLevelAdapt = 1; % use adaptive setting for above.
opts.waveletNumLevels = 3;  % number of wavelet levels
opts.waveletLocalMAD = 0; % locally estimated MAD
opts.waveletBackSub = 0;  % background subtraction
opts.waveletMinLevel = 1; % discard wavelet levels below this

opts.waveletPrefilter = 0;
opts.debug.showWavelet = 0;

data = [];
for i = 1:239
    frame = imread('AVG_MDA_6 50Ap 20hz cont_MMStack_Pos0.ome.tif', i);
    %frame = frame(65:100, 115:155);

    %frame = imread('AVG_MDA_6 50Ap 20hz cont_MMStack_Pos0.ome.ap180.tif', i);
    %frame = imsharpen(frame);
    data = cat(3, data, frame);
end

data = double(data);

figure;

%diff_y = abs(diff(data));
%diff_y = squeeze(mean(mean(diff_y, 1), 2)); 
%plot(diff_y);

total_mean = mean(data(:, :, :), 3);
background = mean(data(:, :, 1:20), 3);

data = bsxfun(@minus, data, background);

%data(data < 2000) = 2000;

mx = double(max(max(max(data))));
mn = double(min(min(min(data))));



%data = (data - 2000) / (mx - 2000);

data = data / mx;

%plot(squeeze(mean(mean(data, 1), 2)));
%xlabel('frames');
%ylabel('normalized intensity');


%data(data < 0.05) = 0;

    
figure_all = figure;
%figure_single = figure;

blue_to_red_map = [0 0 1.0
                   0 0 0.9
                   0 0 0.8
                   0 0 0.7
                   0 0 0.6
                   0 0 0.4
                   0 0 0.3
                   0 0 0.2
                   0 0 0.1                   
                   0 0 0
                   0.2 0 0
                   0.3 0 0
                   0.45 0 0
                   0.6 0 0
                   0.7 0 0
                   0.8 0 0
                   0.85 0 0
                   0.9 0 0
                   0.95 0 0
                   1.0 0 0];

%cm_max = 1;
%cm_min = -cm_max;

cm_max = 1 / 4;
cm_min = -cm_max;

current = double(data(:, :, 1));
%current = current - background;

alpha = 0.2;

spots_history = {};

%imagesc(data(:, :, 30));

[centers, radii, metric] = imfindcircles(total_mean, [7 20], 'ObjectPolarity','bright');
imagesc(total_mean);

centersStrong5 = centers; 
radiiStrong5 = radii;
metricStrong5 = metric;

viscircles(centersStrong5, radiiStrong5,'EdgeColor','b');



%{
centersStrong5 = centers(1:5,:); 
radiiStrong5 = radii(1:5);
metricStrong5 = metric(1:5);
%}

for i = 20:200
    frame = double(data(:, :, i));
    %frame = frame - background;

    frame = alpha * frame + (1.0 - alpha) * current;
    current = frame;
    
    %caxis([-500 500]);
    %figure(figure_all);
    subplot(1,2,1);
    imagesc(frame);

    viscircles(centersStrong5, radiiStrong5,'EdgeColor','b');

    colorbar;
    colormap(blue_to_red_map);

    caxis([cm_min cm_max]);
    xlabel('pixels');
    ylabel('pixels');

    
    frame = frame(65:100, 115:155);

    [spots, spots_amp, ld, spots_area] = waveletSpots(frame, opts);
    
    
    %figure(figure_single);    
    subplot(1,2,2);
    imagesc(frame);
    colorbar;
    colormap(blue_to_red_map);
    caxis([cm_min cm_max]);
    xlabel('pixels');
    ylabel('pixels');
    
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
    
    %{
    for spi = 1:size(spots, 1)
        sp = spots(spi, :);
        draw_circle(sp(2), sp(1), 2);
    end
    %}
    
    for spi = 1:numel(spots_history)
        sph = spots_history{spi};
        sp = sph(end, :);
        
        if i - sp(1) > 5
            continue
        end
        
        a = sph(:, 2);
        %a = max(sph(:, 2));
        a = a(end);

        if a < 0.0000
            continue
        end
      
        area = sph(:, 3);
        %a = max(sph(:, 2));
        max_area = max(area);
        area = area(end);
        
        if max_area < 3
           continue
        end
        
        
        
        x = sp(5);
        y = sp(4);
        
        r = sqrt(area / 3.14);
        
        draw_circle(x, y, r);
        text(x, y, num2str(area), 'Color', 'green', 'HorizontalAlignment', 'center')
        
    end
    
    
    %rectangle('Position', [5 10 5 5], 'EdgeColor', 'g');
    
    pause(0.1);
    
    %waitforbuttonpress;
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


for i = 1:numel(spots_history)
    sph = spots_history{i};
    
    path = sph(:, 4:5);
    
    life_time = sph(end, 1) - sph(1, 1);
    
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
    
    life_time = sph(end, 1) - sph(1, 1);
    
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

