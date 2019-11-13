
data = [];
for i = 1:239
    frame = imread('AVG_MDA_6 50Ap 20hz cont_MMStack_Pos0.ome.tif', i);
    data = cat(3, data, frame);
end

data = double(data);
data(data < 2000) = 2000;

mx = double(max(max(max(data))));
mn = double(min(min(min(data))));

data = (data - 2000) / (mx - 2000);

background = mean(data(:, :, 1:20), 3);

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
                   0.1 0 0
                   0.2 0 0
                   0.3 0 0
                   0.4 0 0
                   0.5 0 0
                   0.6 0 0
                   0.7 0 0
                   0.8 0 0
                   0.9 0 0
                   1.0 0 0];

%cm_max = mx / 2;
%cm_min = -cm_max;

cm_max = 1 / 4;
cm_min = -cm_max;

current = double(data(:, :, 1));
%current = current - background;

alpha = 0.05;

for i = 1:200
    frame = double(data(:, :, i));
    %frame = frame - background;

    frame = alpha * frame + (1.0 - alpha) * current;
    current = frame;
    
    %caxis([-500 500]);
    %figure(figure_all);
    subplot(1,2,1);
    imagesc(frame);
    colorbar;
    colormap(blue_to_red_map);

    caxis([cm_min cm_max]);
    
    frame = frame(65:100, 115:155);
    
    %figure(figure_single);    
    subplot(1,2,2);
    imagesc(frame);
    colorbar;
    colormap(blue_to_red_map);
    caxis([cm_min cm_max]);
    
    pause(0.1);
    
    %waitforbuttonpress;
end