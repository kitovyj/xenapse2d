classdef MainFigure < handle   
properties
    
    figure_id = 0; 

    initial_figure_width = 1100;
    initial_figure_height = 630;    
    initial_figure_x = 100;
    initial_figure_y = 100;

    general_view_axes = 0;
    general_view_image = 0;
    general_view_image_initialized = 0;
    xenapse_view_axes = 0;
    xenapse_view_image = 0;
    xenapse_view_image_initialized = 0;

    data = 0;

    peak_tracker = PeakTracker();
    spot_tracker = SpotTracker();

    selected_xenapse = 1;
    
    xenapse_circles = 0;
    selected_xenapse_rectangle = 0;
    
    xenapse_size_extension = 1.3;
    
    pixel_size = 160;
    %stimulation_start = 0.5;
    %stimulation_start = 0.0;  
        
    viewed_frame_index = 1; 
    
    spot_circles = {};
    spot_texts = {};
    
    loaded_file_name = 0;
    views_colormap = jet;
 
    min_value = 0;
    
    % gui controls
    
    panel_top = 0;
    panel_top_separator = 0;
    panel_general = 0;
    panel_display_settings = 0;
    panel_xenapse = 0;

    % general panel 
    
    slider_frames = 0;
    button_prev = 0;
    button_next = 0;
    text_duration = 0;
    text_total_frames = 0;
    text_current_frame = 0;
    panel_separator_general_1st = 0;
    panel_separator_general_2nd = 0;
    edit_temporal_averaging = 0;
    
    checkbox_subtract_background = 0; 
    checkbox_temporal_averaging = 0;
    checkbox_lowpass_wavelet = 0;
   
    % display settings

    slider_display_threshold = 0;
    text_color_map_label = 0;      
    combobox_color_map = 0;   
    
    % xenapse panel
    
    slider_madwc = 0;
    
    panel_separator_xenapse_1st = 0;
    panel_separator_xenapse_2nd = 0;
    
    checkbox_track = 0;
    checkbox_show_detected_spots = 0;
    
end
    
methods

    % constructor
                 
    function o = MainFigure()
        
        o.data = ImagingData();
        
        o.figure_id = figure; 
        
        figure_size = [o.initial_figure_x, o.initial_figure_y, o.initial_figure_width, o.initial_figure_height];
      
        set(o.figure_id, 'Position', figure_size, ...
            'NumberTitle', 'off', ...
            'Toolbar', 'none', 'Menubar', 'none', 'Resize', 'on', 'ResizeFcn', @o.on_figure_resized);    
        
        set(o.figure_id, 'name', "Xenapse2D", 'NumberTitle', 'off');
        
        %menu = uimenu('Label', 'Misc');
        %uimenu(menu, 'Label', 'Make a movie...', 'Callback',  @O.onMakeMovie);
        
        o.arrange_controls();
        
        %o.load('AVG_MDA_6 50Ap 20hz cont_MMStack_Pos0.ome.tif');
        %o.load('Dynamin\Dynamin single pulse latency analysis Baseline 50frame 100hz acqusition\37_CMOS\0125\2\MDA_1 1Ap\MDA_1 1Ap_MMStack_Pos0.ome.tif')
        %o.load('Dynamin\Dynamin single pulse latency analysis Baseline 50frame 100hz acqusition\Test analysis\0121\1_37c\MD-5 bleach ctrl\MD-5 bleach ctrl_MMStack_Pos0.ome.tif');
        %o.load('Dynamin\Dynamin single pulse latency analysis Baseline 50frame 100hz acqusition\Test analysis\0121\1_37c\MDA_3 5Ap 100hz\MDA_3 5Ap 100hz_MMStack_Pos0.ome.tif');
        
        %o.load('newest\MDA_4 4Ap\MDA_4 4Ap_MMStack_Pos0.ome.tif');     
        %o.load('d:\muenster\xenapse2d\newest\MDA_1 4Ap\MDA_1 4Ap_MMStack_Pos0.ome.tif');
        o.load('d:\muenster\xenapse2d\newest\MDA_7_2 2Ap\MDA_7_2 2Ap_MMStack_Pos0.ome.tif');
        %o.load('d:\muenster\xenapse2d\newest\MDA_7 4Ap\MDA_7 4Ap_MMStack_Pos0.ome.tif');
        
    end
    
    % destructor
    
    function delete(o)
        %close(o.figure_id); 
    end  
    
    % create/rearrange ui contols
    
    function arrange_controls(o)
                  
      figure(o.figure_id);
      
      figure_position = get(o.figure_id, 'Position');
      
      figure_width = figure_position(3);
      figure_height = figure_position(4);  
      
      top_panel_height = 120;
      
      views_border = 15;
            
      views_width = (figure_width - views_border*3) / 2;
      
      general_view_position = [ views_border, views_border, ...
        views_width, figure_height - views_border*2 - top_panel_height]; 

      xenapse_view_position = [ views_border*2 + views_width, views_border, ...
        views_width, figure_height - views_border*2 - top_panel_height]; 
      
      frame_height = 100;
      frame_width = 100;
    
      if o.general_view_axes == 0

          o.general_view_axes = axes('Units', 'pixels', 'Position', general_view_position, 'Parent', o.figure_id, ...
              'Visible', 'off');
          white = ones(frame_height, frame_width, 'uint8') * 255;
          o.general_view_image = imshow(white);                
          
      else

         set(o.general_view_axes, 'Position', general_view_position); 

      end    
      
      if o.xenapse_view_axes == 0

          o.xenapse_view_axes = axes('Units', 'pixels', 'Position', xenapse_view_position, 'Parent', o.figure_id, ...
              'Visible', 'off');
          white = ones(frame_height, frame_width, 'uint8') * 255;
          o.xenapse_view_image = imshow(white);                

      else

         set(o.xenapse_view_axes, 'Position', xenapse_view_position); 

      end 
 
      panel_top_position = [0, figure_height - top_panel_height, figure_width, top_panel_height];
      separator_margin = views_border;
      panel_separator_position = [separator_margin, 1, figure_width - separator_margin*2, 1 ];
      
      if o.panel_top == 0
          
        o.panel_top = uipanel('Parent', o.figure_id, 'Title', '', 'Units', 'Pixels', 'Position', ...
          panel_top_position, 'Visible', 'on', 'BorderType', 'none');
      
        o.panel_top_separator = uipanel('Parent', o.panel_top, 'Units', 'Pixels', 'BorderType', 'none', ...          
          'BackgroundColor', 'black', 'Position', panel_separator_position );      
      
      else
         
        set(o.panel_top, 'Position', panel_top_position); 
        set(o.panel_top_separator, 'Position', panel_separator_position);
      
      end
      
      panel_general_width = int32(figure_width / 2);
      panel_general_position = [0, 2, panel_general_width, top_panel_height - 1];
      
      prev_next_buttons_width = 50;
      text_current_frame_width = 70;
      space = 10;
      margin = 15;
      x = margin;
           
      slider_width = panel_general_width - margin * 2 - space * 3 - 2*prev_next_buttons_width - text_current_frame_width;
      slider_position = [x, 15, slider_width, 20];
      x = x + slider_width + space;
      text_current_frame_position = [x, 11, text_current_frame_width, 20];
      x = x + text_current_frame_width + space;      
      button_prev_position = [x, 15, prev_next_buttons_width, 20];
      x = x + prev_next_buttons_width + space;
      button_next_position = [x, 15, prev_next_buttons_width, 20];         

      y = 75;
      separator_margin = views_border;
      sep_width = panel_general_width - separator_margin * 2;
      panel_separator_general_1st_position = [separator_margin, y, sep_width, 1 ];
      y = y - 30;
      panel_separator_general_2nd_position = [separator_margin, y, sep_width, 1 ];
      
      panel_display_settings_width = 230;
      panel_display_settings_position = [panel_general_width - panel_display_settings_width, 51, ... 
                                         panel_display_settings_width, 23];
            
      if o.panel_general == 0
          
        o.panel_general = uipanel('Parent', o.panel_top, 'Title', '', 'Units', 'Pixels', 'Position', ...
          panel_general_position, 'Visible', 'on', 'BorderType', 'none');
      
        %max_frames = size(o.data, 3);
        max_frames = 100;
        slider_step = 1 / max(1, max_frames - 1);
            
        jSlider = javax.swing.JSlider;
        [jSlider, hContainer] = javacomponent(jSlider, slider_position, o.panel_general);
        o.slider_frames = {jSlider, hContainer};
        set(o.slider_frames{1}, 'MajorTickSpacing', 10, 'PaintTicks', true, 'PaintLabels', false);
        set(o.slider_frames{1}, 'Value', 1, 'Minimum', 1, 'Maximum', max_frames);
        set(o.slider_frames{1}, 'StateChangedCallback', @o.on_slider_frames_changed);

        o.text_current_frame = uicontrol('Parent', o.panel_general, 'Style', 'text', 'String', '', ...
          'Position', text_current_frame_position, 'HorizontalAlignment', 'left');            
        o.update_current_frame_text();

        o.button_prev = uicontrol('Parent', o.panel_general, 'Style', 'pushbutton', 'String', '<<', ...
          'Position', button_prev_position, ...
          'Callback', @o.on_button_prev);

        o.button_next = uicontrol('Parent', o.panel_general, 'Style', 'pushbutton', 'String', '>>', ...
          'Position', button_next_position, ...
          'Callback', @o.on_button_next);
      
            %{
            
            o.slider_frames = uicontrol(o.panel_general, 'Style', 'slider', 'Min', 1, 'Max', max_frames, 'Value', 1, ...
                'Position', slider_position, 'SliderStep', [slider_step, slider_step*10], ...
                'Callback', @o.on_slider_frames_changed);
            %}
            
        x = margin;
        button_open_file_width = 100;
        
        button_open_file = uicontrol('Parent', o.panel_general, 'Style', 'pushbutton', 'String', 'Load file...', ...
          'Position', [x, 90, button_open_file_width, 20], ...
          'Callback', @o.on_load_file);
      
        x = x + button_open_file_width + space;
       
        top_y = 90;
        y = top_y;
        label_width = 60;
        text_width = 30;       
        label_space = 2;
        
        text_total_frames_label_width = label_width;
        text_total_frames_label = uicontrol('Parent', o.panel_general, 'Style', 'text', 'String', 'Frames:', ...
          'Position', [x, y, text_total_frames_label_width, 20], 'HorizontalAlignment', 'left');       
        px = x + 45 + label_space;
        o.text_total_frames = uicontrol('Parent', o.panel_general, 'Style', 'text', 'String', '', ...
          'Position', [px, y, text_width, 20], 'HorizontalAlignment', 'left');         
      
        y = y - 15;
      
        text_duration_label = uicontrol('Parent', o.panel_general, 'Style', 'text', 'String', 'Duration, s:', ...
          'Position', [x, y, label_width, 20], 'HorizontalAlignment', 'left');       
        px = x + 60 + label_space;
        o.text_duration = uicontrol('Parent', o.panel_general, 'Style', 'text', 'String', '', ...
          'Position', [px, y, text_width, 20], 'HorizontalAlignment', 'left');      

        o.update_duration_text();          
             
        x = x + label_width + label_space + text_width + space;
        y = top_y;
        
        label_width = 80;
        text_width = 40;
        
        text_frame_rate_label = uicontrol('Parent', o.panel_general, 'Style', 'text', 'String', 'Frame rate, Hz:', ...
          'Position', [x, y, label_width, 20], 'HorizontalAlignment', 'left');        
        px = x + label_width + label_space;       
        
        combobox_frame_rate_width = 40;
        combobox_frame_rate_position = [px, y + 3, combobox_frame_rate_width, 20];
       
        frame_rates = { '20', '100' };
                    
        selection = 2;
        o.data.frame_rate = str2num(frame_rates{selection});
        
        combobox_frame_rate = uicontrol(o.panel_general, 'Style', 'popupmenu', 'String', frame_rates, ...
          'Enable', 'on', 'Position', combobox_frame_rate_position, 'Callback', @o.on_combobox_frame_rate_changed, ...
          'Value', selection);            
        y = y - 15;

        text_pixel_size_label = uicontrol('Parent', o.panel_general, 'Style', 'text', 'String', 'Pixel size, nm:', ...
            'Position', [x, y, label_width, 20], 'HorizontalAlignment', 'left');           
        px = x + 70 + label_space;   
        text_pixel_size_width = text_width;
        pixel_size_str = num2str(o.pixel_size);
        text_pixel_size = uicontrol('Parent', o.panel_general, 'Style', 'text', 'String', pixel_size_str, ...
          'Position', [px, y, text_pixel_size_width, 20], 'HorizontalAlignment', 'left');        
        
        x = x + label_width + label_space + text_width + space;
        y = top_y;
        
        label_width = 70;
        text_width = 30;
        
        ss_str = num2str(o.data.stimulation_start, '%.2f');
        text_stimulation_start_label = uicontrol('Parent', o.panel_general, 'Style', 'text', 'String', 'Stim. start, s:', ...
          'Position', [x, y, label_width, 20], 'HorizontalAlignment', 'right');       
        px = x + label_width + label_space;
        text_duration_width = label_width;        
        text_stimulation_start = uicontrol('Parent', o.panel_general, 'Style', 'text', 'String', ss_str, ...
          'Position', [px, y, text_width, 20], 'HorizontalAlignment', 'left');          
 
        y = y - 15;
        
        o.panel_separator_general_1st = uipanel('Parent', o.panel_general, 'Units', 'Pixels', 'BorderType', 'none', ...          
          'BackgroundColor', [0.7, 0.7, 0.7], 'Position', panel_separator_general_1st_position );      
        o.panel_separator_general_2nd = uipanel('Parent', o.panel_general, 'Units', 'Pixels', 'BorderType', 'none', ...          
          'BackgroundColor', [0.7, 0.7, 0.7], 'Position', panel_separator_general_2nd_position );      
      
        x = margin;
        y = 50;
        checkbox_subtract_background_width = 120;
        
        o.checkbox_subtract_background = uicontrol('Parent', o.panel_general, 'Style', 'checkbox', 'String', ' Subtract background', ...
          'Position', [x, y, checkbox_subtract_background_width, 20], 'Value', 1, ...
          'Callback', @o.on_checkbox_subtract_background_clicked);  
    
        x = x + space + checkbox_subtract_background_width;
        checkbox_temporal_averaging_width = 120;
        
        o.checkbox_temporal_averaging = uicontrol('Parent', o.panel_general, 'Style', 'checkbox', 'String', ' Temporal averaging,', ...
          'Position', [x, y, checkbox_temporal_averaging_width, 20], 'Value', 1, ...
          'Callback', @o.on_checkbox_temporal_averaging_clicked);      
      
        x = x + space/3 + checkbox_temporal_averaging_width;
        edit_temporal_averaging_width = 40;
        
        o.edit_temporal_averaging = uicontrol(o.panel_general, 'Style', 'edit', 'String', num2str(o.data.temporal_averaging_alpha), ...
          'Enable', 'on', 'Position', [x, y, edit_temporal_averaging_width, 20], 'Callback', @o.on_edit_temporal_averaging_changed);      
      
        x = x + edit_temporal_averaging_width + space;

        checkbox_lowpass_wavelet_width = 120;
        
        o.checkbox_lowpass_wavelet = uicontrol('Parent', o.panel_general, 'Style', 'checkbox', 'String', ' Lowpass wl filter', ...
          'Position', [x, y, checkbox_lowpass_wavelet_width, 20], 'Value', 1, ...
          'Callback', @o.on_checkbox_lowpass_wavelet_clicked);      
      
        x = x + space + checkbox_lowpass_wavelet_width        
        % panel display settings
        
        o.panel_display_settings = uipanel('Parent', o.panel_general, 'Title', '', 'Units', 'Pixels', 'Position', ...
          panel_display_settings_position, 'Visible', 'on', 'BorderType', 'none');
      
        label_space = 2;
        x = 0; 
        y = 0;

        text_display_threshold_label_width = 50;
        text_display_threshold_label_position = [x, y, text_display_threshold_label_width, 18];

        text_display_threshold_label = uicontrol('Parent', o.panel_display_settings, 'Style', 'text', 'String', "Thresh.:", ...
          'Position', text_display_threshold_label_position, 'HorizontalAlignment', 'right');        

        x = x + text_display_threshold_label_width + label_space;

        slider_max = 300;
        slider_min = 0;
        slider_width = 50;
        slider_position = [x, y, slider_width, 20];
            
        jSlider = javax.swing.JSlider;
        [jSlider, hContainer] = javacomponent(jSlider, slider_position, o.panel_display_settings);
        o.slider_display_threshold = {jSlider, hContainer};
        set(o.slider_display_threshold{1}, 'MajorTickSpacing', 10, 'PaintTicks', true, 'PaintLabels', false);
        set(o.slider_display_threshold{1}, 'Value', 100, 'Minimum', slider_min, 'Maximum', slider_max);
        set(o.slider_display_threshold{1}, 'StateChangedCallback', @o.on_slider_display_threshold_changed);
       
        x = x + slider_width + label_space;        
        
        text_color_map_label_width = 35;
        text_color_map_label_position = [x, y, text_color_map_label_width, 18];

        o.text_color_map_label = uicontrol('Parent', o.panel_display_settings, 'Style', 'text', 'String', "Color map:", ...
          'Position', text_color_map_label_position, 'HorizontalAlignment', 'right');        

        x = x + text_color_map_label_width + label_space;

        combobox_color_map_width = 80;
        combobox_color_map_position = [x, y, combobox_color_map_width, 20];
       
        cmaps = {'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', ...
                 'autumn', 'winter', 'gray', 'bone', 'copper', 'pink' };
                    
        selection = 10; % gray
        o.views_colormap = cmaps{selection};
        
        o.combobox_color_map = uicontrol(o.panel_display_settings, 'Style', 'popupmenu', 'String', cmaps, ...
          'Enable', 'on', 'Position', combobox_color_map_position, 'Callback', @o.on_combobox_color_map_changed, ...
          'Value', selection);      
              
      else
         
        set(o.panel_general, 'Position', panel_general_position); 
        set(o.slider_frames{2}, 'Position', slider_position);
        set(o.text_current_frame, 'Position', text_current_frame_position);
        set(o.button_prev, 'Position', button_prev_position);     
        set(o.button_next, 'Position', button_next_position);  
        set(o.panel_separator_general_1st, 'Position', panel_separator_general_1st_position);  
        set(o.panel_separator_general_2nd, 'Position', panel_separator_general_2nd_position); 
        set(o.panel_display_settings, 'Position', panel_display_settings_position); 
        
      end
      
      panel_xenapse_position = [panel_general_width, 2, views_width, top_panel_height - 1];

      y = 75;
      separator_margin = views_border;
      sep_width = views_width - separator_margin;
      panel_separator_xenapse_1st_position = [separator_margin, y, sep_width, 1 ];
      y = y - 30;
      panel_separator_xenapse_2nd_position = [separator_margin, y, sep_width, 1 ];
      
      if o.panel_xenapse == 0
          
        o.panel_xenapse = uipanel('Parent', o.panel_top, 'Title', '', 'Units', 'Pixels', 'Position', ...
          panel_xenapse_position, 'Visible', 'on', 'BorderType', 'none');
      
        x = 1;
        separator_margin = 5;
        
        panel_separator = uipanel('Parent', o.panel_xenapse, 'Units', 'Pixels', 'BorderType', 'none', ...          
          'BackgroundColor', 'black', 'Position', [x, separator_margin, 1, top_panel_height - separator_margin*2 ] );
      
        x = 15;
        y = 85;
        button_width = 100;
        button_height = 25;
        space = 10;
        
        button_analyze_single = uicontrol('Parent', o.panel_xenapse, 'Style', 'pushbutton', 'String', 'Analyze single', ...
          'Position', [x, y, button_width, button_height], ...
          'Callback', @o.on_analyze_single);
      
        x = x + button_width + space;

        button_analyze_all = uicontrol('Parent', o.panel_xenapse, 'Style', 'pushbutton', 'String', 'Analyze all', ...
          'Position', [x, y, button_width, button_height], ...
          'Callback', @o.on_analyze_all);

        x = x + button_width + space;

        button_make_movie = uicontrol('Parent', o.panel_xenapse, 'Style', 'pushbutton', 'String', 'Movie', ...
          'Position', [x, y, button_width, button_height], ...
          'Callback', @o.on_movie);
        
        o.panel_separator_xenapse_1st = uipanel('Parent', o.panel_xenapse, 'Units', 'Pixels', 'BorderType', 'none', ...          
          'BackgroundColor', [0.7, 0.7, 0.7], 'Position', panel_separator_xenapse_1st_position );      

        o.panel_separator_xenapse_2nd = uipanel('Parent', o.panel_xenapse, 'Units', 'Pixels', 'BorderType', 'none', ...          
          'BackgroundColor', [0.7, 0.7, 0.7], 'Position', panel_separator_xenapse_2nd_position );      
      
      
        x = 15;
        y = 50;
        checkbox_track_width = 60;    
        
        o.checkbox_track = uicontrol('Parent', o.panel_xenapse, 'Style', 'checkbox', 'String', ' Track', ...
          'Position', [x, y, checkbox_track_width, 20], 'Value', 1, ...
          'Callback', @o.on_checkbox_track_clicked);      

        x = x + checkbox_track_width + space;      
      
        checkbox_show_detected_spots_width = 120;    
        
        o.checkbox_show_detected_spots = uicontrol('Parent', o.panel_xenapse, 'Style', 'checkbox', 'String', ' Show detected spots', ...
          'Position', [x, y, checkbox_show_detected_spots_width, 20], 'Value', 1, ...
          'Callback', @o.on_checkbox_show_detected_spots_clicked);      
      
        x = 15;
        y = 15;
      
        text_wadc_label_width = 40;
        
        text_wadc_label = uicontrol('Parent', o.panel_xenapse, 'Style', 'text', 'String', "MADC:", ...
          'Position', [x, y - 3, text_wadc_label_width, 20], 'HorizontalAlignment', 'left'); 
      
        x = x + text_wadc_label_width;
      
        slider_max = 50000;
        slider_min = 0;
        slider_width = 80;
        slider_position = [x, y, slider_width, 20];
            
        jSlider = javax.swing.JSlider;
        [jSlider, hContainer] = javacomponent(jSlider, slider_position, o.panel_xenapse);
        o.slider_madwc = {jSlider, hContainer};
        set(o.slider_madwc{1}, 'MajorTickSpacing', 100, 'PaintTicks', true, 'PaintLabels', false);
        set(o.slider_madwc{1}, 'Minimum', slider_min, 'Maximum', slider_max);
        %set(o.slider_madwc{1}, 'Value', o.spot_tracker.madwc * 10000);
        set(o.slider_madwc{1}, 'StateChangedCallback', @o.on_slider_madwc_changed);
        
      else
         
        set(o.panel_xenapse, 'Position', panel_xenapse_position); 
        set(o.panel_separator_xenapse_1st, 'Position', panel_separator_xenapse_1st_position);  
        set(o.panel_separator_xenapse_2nd, 'Position', panel_separator_xenapse_2nd_position); 
      
      end
      
    end 
    
    % non-event methods
    
    function update_title(o)
        [~, fn, ~] = fileparts(o.loaded_file_name);
        title = strcat("Xenapse2D - ", fn); 
        set(o.figure_id, 'name', title);
    end

    function update_duration_text(o)
        
        fn = size(o.data, 3);
        if o.pixel_size ~= 0
            duration_s = double(fn - 1) / o.data.frame_rate;
        else
            duration_s = 0;
        end
        
        duration_str = sprintf('%s', num2str(duration_s, '%.2f'));
        %duration_str = strcat(num2str(duration_s), ['s' chr newline], int2str(fn), ' fr');
        total_frames_str = sprintf('%s', int2str(fn));
        
        set(o.text_duration, 'String', duration_str);
        set(o.text_total_frames, 'String', total_frames_str);
        
    end
    
    function update_current_frame_text(o)
        
        if o.pixel_size ~= 0
            cf_s = double(o.viewed_frame_index - 1) / o.data.frame_rate;
        else
            cf_s = 0;
        end
        
        current_frame_str = sprintf('%s | %s s', int2str(o.viewed_frame_index), num2str(cf_s, '%.2f'));
        set(o.text_current_frame, 'String', current_frame_str);
        
    end
    
    % figure events
    
    function on_figure_resized(o, figure_object, ~)
                  
        o.arrange_controls();
      
    end
    
    % general events

    function on_combobox_frame_rate_changed(o, combobox_object, ~)
       
       index = get(combobox_object, 'Value');
       frame_rates = get(combobox_object, 'String');
       o.frame_rate = str2num(frame_rates{index});
        
       o.update_duration_text();
       o.prepare_processed_data();
       o.update_general_view();
       o.update_xenapse_view();

    end
    
    function on_edit_temporal_averaging_changed(o, image_object, ~)
       o.prepare_processed_data();
       o.update_general_view();
       o.update_xenapse_view();

    end
    
    function on_checkbox_subtract_background_clicked(o, image_object, ~)
       o.update_general_view();
       o.update_xenapse_view();
    end
    
    function on_checkbox_temporal_averaging_clicked(o, image_object, ~)
       o.prepare_processed_data();
       o.update_general_view();
       o.update_xenapse_view();
    end
    
    function on_checkbox_lowpass_wavelet_clicked(o, image_object, ~)
       o.update_general_view();
       o.update_xenapse_view();
    end
    
    function on_general_view_image_clicked(o, image_object, ~)

       axes  = get(image_object, 'Parent');
       coord = get(axes, 'CurrentPoint'); 
       coord = coord(1,1:2);        
      
       newly_selected_xenapse = o.selected_xenapse;
       
       for i = 1:numel(o.xenapse_radii)
          
           center = o.xenapse_centers(i, :);
           d = sqrt(sum((center - coord) .^ 2));
           
           if d <= o.xenapse_radii(i)
               newly_selected_xenapse = i;
               break;         
           end
           
       end
       
       if newly_selected_xenapse ~= o.selected_xenapse
           
           o.selected_xenapse = newly_selected_xenapse;
           o.update_selected_xenapse();
           o.update_xenapse_view(); 
           
       end
       
    end   

    % display settings
    
    function on_combobox_color_map_changed(o, ~, ~)
        index = get(o.combobox_color_map, 'Value');
        cms = get(o.combobox_color_map, 'String');
        o.views_colormap = cms{index};
        colormap(o.xenapse_view_axes, o.views_colormap);
        colormap(o.general_view_axes, o.views_colormap);
    end

    function on_slider_display_threshold_changed(o, ~, ~)
        o.update_xenapse_view();
        o.update_general_view();
    end
    
    % frames navigation
    
    function on_slider_frames_changed(o, slider_object, event_data)
        
        value = round(get(slider_object, 'Value'));
        if value == o.viewed_frame_index
            return
        end
        
        if o.get_do_track() && o.viewed_frame_index > value
            o.spot_tracker.clear_history();
            o.peak_tracker.clear_history();
        end

        o.viewed_frame_index = value;
        
        o.update_current_frame_text();
        o.update_xenapse_view();
        o.update_general_view();
        
    end

    function on_button_prev(o, ~, ~)
        if o.viewed_frame_index == 1
            return
        end
        o.viewed_frame_index = o.viewed_frame_index - 1;
        
        if o.get_do_track()
            o.spot_tracker.clear_history();
            o.peak_tracker.clear_history();
        end
        
        set(o.slider_frames{1}, 'Value', o.viewed_frame_index);
        o.update_current_frame_text();
        o.update_xenapse_view();
        o.update_general_view();
    end

    function on_button_next(o, ~, ~)
        if o.viewed_frame_index >= size(o.data, 3)
            return
        end
        o.viewed_frame_index = o.viewed_frame_index + 1;
        set(o.slider_frames{1}, 'Value', o.viewed_frame_index);
        o.update_current_frame_text();
        o.update_xenapse_view();
        o.update_general_view();
    end
    
    % file load
    
    function on_load_file(o, button_object, event_data) 
        
        [file, path] = uigetfile('*.tiff;*.tif');
        
        if file ~= 0
           ff = fullfile(path, file);
           o.load(ff);          
        end        
        
    end

    % xenapse events
    
    function on_slider_madwc_changed(o, slider_object, event_data)
        
        o.update_xenapse_view();
        
    end    
    
    function on_checkbox_track_clicked(o, checkbox_object, event_data)
        
        o.spot_tracker.clear_history();
        
        %if o.get_do_track() == 0
           
        o.update_xenapse_view();
            
        %end
        
        
    end
    
    function on_checkbox_show_detected_spots_clicked(o, checkbox_object, event_data)
 
        o.update_xenapse_view();
        
    end
        
    function on_analyze_single(o, button_object, event_data)
        o.analyze_xenapses([o.selected_xenapse]);
    end

    function on_analyze_all(o, button_object, event_data)
        
        o.analyze_xenapses([1:size(o.xenapse_centers, 1)]);
                
    end

    function on_movie(o, button_object, event_data)

        total_work = size(o.data, 3);
        current_progress = 0;
        wait_bar = waitbar(0, 'Doing analysis...');
        
        spots_history = [];
        intensity = [];
        %[spots_history intensity] = o.analyze_xenapse(o.selected_xenapse, wait_bar, current_progress, total_work);
        %spots_history = cell2mat(spots_history);
        %spots_history = sortrows(spots_history, 2);
        
        close(wait_bar);
        
        wait_bar = waitbar(0, 'Processing frames...');
        

        
        rect = get_xenapse_rectangle(o, o.selected_xenapse);
        rect = int32(rect);
        
        subtract_background = o.get_subtract_background();
        lowpass_filtering = o.get_do_lowpass_filtering();

        xenapse_data = o.data(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)), :);      
        
        
        event_tracker = EventTracker();
        
        stim_start_frame = o.get_stim_start_frame();
                    
        spots_history = event_tracker.detect_events(xenapse_data, subtract_background, lowpass_filtering, stim_start_frame);

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

                
        intensity = mean(xenapse_data, [1, 2]);
        intensity = intensity - min(intensity);
        intensity = intensity / max(intensity); 
 
        mx = max(max(max(xenapse_data)));
        mn = min(min(min(xenapse_data)));
        xenapse_data = xenapse_data - mn;
        xenapse_data = xenapse_data / (mx - mn);
        
        first_frame = single(xenapse_data(:, :, start_frame));
        
        displayed_intensity = [ intensity(1) ];

        current_progress = 0;
        total_work = size(o.data, 3); 
        
        fid = figure('Position', [10 10 900 600]);
        left = subplot(2, 2, 1);

        x = 1:double(rect(4) + 1);
        y = 1:double(rect(3) + 1);
        [X, Y] = meshgrid(x, y);
        
        surface_h = surf(X, Y, first_frame, 'FaceAlpha', 1.0);
        zlim([0 1]);
        caxis([0 1])
        
        right = subplot(2, 2, 2);
         
        [~, contour_h] = contourf(X, Y, first_frame, 20);
        caxis([0 1])        
        
        bottom = subplot(2, 2, [3, 4]);

        %ip = plot(a, intensity);         
        
        
        A = get(bottom, 'position');          % gca points at the second one
        A(1, 4) = A(1, 4) / 2;              % reduce the height by half
        %A(1, 2) = A(1, 2) + A(1, 4);         % change the vertical position
        set(bottom, 'position', A);            % set the values you just changed

        lp = get(left, 'position');          % gca points at the second one
        lp(1, 4) = lp(1, 4) + A(1, 4);              % reduce the height by half        
        lp(1, 2) = lp(1, 4) - A(1, 4);              % reduce the height by half        
        set(left, 'position', lp);            % set the values you just changed
 
        rp = get(right, 'position');          % gca points at the second one
        rp(1, 4) = rp(1, 4) + A(1, 4);              % reduce the height by half        
        rp(1, 2) = rp(1, 2) - A(1, 4);              % reduce the height by half        
        set(right, 'position', rp);            % set the values you just changed
        
        %subplot(2, 2, [3, 4]);        
        ip = plot(bottom, displayed_intensity);  

        xlim([1 size(o.data, 3)])
        ylim([0 1]);
        xlabel('frames')
        ylabel('mean intensity')
        
        set(ip, 'YDataSource', 'displayed_intensity');

        spot_circles = {};
        spot_texts = {};
        
        for i = start_frame:size(o.data, 3)

            frame = single(xenapse_data(:, :, i));

            %{
            if subtract_background == 1

                frame = frame - bg;
                %frame = frame + 1;

                if o.min_value < 0
                    frame = frame - o.min_value;
                end
                
            end
            %}
            
            
            frame = flipud(frame); 

            set(surface_h, 'ZData', frame);
            set(contour_h, 'ZData', frame);
                         
            displayed_intensity = intensity(1:i);
            refreshdata(ip, 'caller');

            % draw spots
  
            axes(right);
            
            new_spot_circles = {};
            new_spot_texts = {};
            
            for j = 1:numel(spots_history)
                
                h = spots_history{j};
                
                appearance_time_point = h(1, 1);
                
                if appearance_time_point > i
                   continue; 
                end
                
                disappearance_time_point = h(end, 1);
                
                if disappearance_time_point < i
                   continue; 
                end
                
                
                % hp = h(int64(i - appearance_time_point + 1), :);
                
                index = find(h(:, 1) > i, 1);
                
                if isempty(index)
                   hp = h(end, :);
                else
                   hp = h(index - 1, :);                    
                end
                
                p = hp(2:3);
                area = hp(5);
                id = j;
                x = p(2);
                y = p(1);
                r = sqrt(area / 3.14);
                c = draw_circle(x, y, r);
                new_spot_circles{end + 1} = c;
                t = text(x, y, num2str(id), 'Color', 'black', 'HorizontalAlignment', 'center', 'BackgroundColor', [1, 1, 1, 0.5], ...
                    'EdgeColor', [0, 0, 0, 0.5]);
                new_spot_texts{end + 1} = t;
                
            end

            cellfun(@delete, spot_circles)        
            cellfun(@delete, spot_texts)

            spot_circles = new_spot_circles;
            spot_texts = new_spot_texts;
            
            %drawnow;
            %pause(.1);
            
            F = getframe(fid);
            [X, Map] = frame2im(F);

            imwrite(X, "out.tif", 'WriteMode', 'append');
            %saveas(fid, "out.tif", 'WriteMode', 'append');
            
            %disp(tracker.spots_history{6});            
            
            waitbar(single(current_progress) / total_work, wait_bar);
            current_progress = current_progress + 1;

        end
        
        close(wait_bar);
        
    end    
    
    function r = get_subtract_background(o)
         r = get(o.checkbox_subtract_background, 'Value');
    end

    function r = get_do_lowpass_filtering(o)
         r = get(o.checkbox_lowpass_wavelet, 'Value');
    end
    
    function r = get_do_track(o)
         r = get(o.checkbox_track, 'Value');
    end
    
    function r = get_show_detected_spots(o)
         r = get(o.checkbox_show_detected_spots, 'Value');
    end

    function r = get_stim_start_frame(o) 
        r = round(o.data.stimulation_start * o.data.frame_rate + 1, 0);
    end

    function r = get_display_threshold(o)
         r = get(o.slider_display_threshold{1}, 'Value') / 100.;
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
        
    
    function prepare_processed_data(o)
                
        ta = get(o.checkbox_temporal_averaging, 'Value');
        
        o.data.prepare_processed_data(ta);
        
    end
    
    function update_selected_xenapse(o)
        
        axes(o.general_view_axes);
        
        displayed_centers = o.data.xenapse_centers;
        displayed_radii = o.data.xenapse_radii;
        
        displayed_centers(o.selected_xenapse, :) = [];
        displayed_radii(o.selected_xenapse, :) = [];
        
        new_xenapse_circles = viscircles(displayed_centers, displayed_radii, ...
            'EdgeColor', 'g', 'LineWidth', 0.7, 'EnhanceVisibility', false, 'LineStyle', '--');
        
        responded_centers = o.xenapse_centers(o.responded_xenapses == 1.0, :);
        responded_radii = zeros(size(responded_centers, 1), 1);
        responded_radii(:) = 2;
        
        new_responded_circles = viscircles(responded_centers, responded_radii, ...
            'EdgeColor', 'g', 'LineWidth', 0.7, 'EnhanceVisibility', false, 'LineStyle', '-');       
        
        %new_xenapse_circlesnew_responded_circles
        
        
        %o.responded_xenapses
        
        rect_position = o.get_xenapse_rectangle(o.selected_xenapse);
        rect_color = [1.0 1.0 1.0];
        new_selected_xenapse_rectangle = rectangle('Position', rect_position, 'EdgeColor', rect_color, 'LineStyle', ':', 'Curvature', 0.0, 'LineWidth', 0.6);
        
        if o.xenapse_circles ~= 0
            delete(o.xenapse_circles);
        end
        
        if o.selected_xenapse_rectangle ~= 0
            delete(o.selected_xenapse_rectangle);
        end    
        
        o.xenapse_circles = new_xenapse_circles;
        o.selected_xenapse_rectangle = new_selected_xenapse_rectangle;
        
    end    
    
    function r = get_xenapse_rectangle(o, xenapse_index)
        
        center = o.data.xenapse_centers(xenapse_index, :);
        radius = o.data.xenapse_radii(xenapse_index);
       
        rs = radius * 2 * o.xenapse_size_extension;
        hs = rs / 2;
       
        max_x = size(o.data, 1);
        max_y = size(o.data, 2);
        bottom = max(center(1) - hs, 1);
        left = max(center(2) - hs, 1);
        
        r = [bottom left min(rs, max_y - bottom) min(rs, max_x - left) ];
        
        %r = [center(1) - hs center(2) - hs rs rs];
        
    end
    
    function update_xenapse_view(o)
        
        rect = get_xenapse_rectangle(o, o.selected_xenapse);
        rect = int32(rect);
        
        frame_data = o.data.data(:, :, o.viewed_frame_index);
        frame_data = frame_data(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)));
        bg_data = o.data.background(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)));
        
        if o.get_subtract_background() == 1
            frame_data = frame_data - bg_data;
            if o.min_value < 0
                frame_data = frame_data - o.min_value;
            end
        end

        if o.get_do_lowpass_filtering() == 1
            
            %frame_data = imgaussfilt(frame_data, 1.0);
            
            frame_data = o.lowpass_wavelet_filter(frame_data);
            
        end
            
                
        madwc = get(o.slider_madwc{1}, 'Value') / 10000.;
        o.spot_tracker.madwc = madwc;
       
        pt_start_frame = o.data.get_stim_start_frame();
        frame_data_all = o.data.data(:, :, 1:pt_start_frame);
        frame_data_all = frame_data_all(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)), :);
        sigma = mean(mean(std(frame_data_all, 0, 3)));

        o.peak_tracker.prominence_threshold = sigma;
        
        if o.get_do_track()
            
            %[spots, regions] = o.spot_tracker.track(frame_data);        
            [spots, regions] = o.peak_tracker.track(frame_data);        
                    
        else
            
            %[spots, regions] = o.spot_tracker.detect_spots(frame_data);
            [spots, regions] = o.peak_tracker.detect_spots(frame_data);
            
        end
        
        if o.get_show_detected_spots()
                        
            frame_data(regions == 0) = 0.0;
                        
        end
        
        dt = o.get_display_threshold();        
        frame_data_u8 = frame_data / dt;
        frame_data_u8(frame_data_u8 > 1) = 1;
        frame_data_u8 = uint8(frame_data_u8 * 255);
            
        % update image data 
        
        axes(o.xenapse_view_axes);
        
        frame_data = flipud(frame_data);
        
        x = 1:double(rect(4) + 1);
        y = 1:double(rect(3) + 1);
        [X, Y] = meshgrid(x, y);
        contourf(X, Y, frame_data, 20)
        
        %surf(X, Y, frame_data, 'Edgecolor', 'none');
        %surf(X, Y, frame_data);
        zlim([0 1]);
        caxis([0 0.5])
        set(gca, 'xtick', []);
        set(gca, 'xticklabel', []);
        set(gca,'Visible','off');
        
        
        % iterate, find inersection
        
        %{

        column_peaks = zeros(size(frame_data));
        column_proms = zeros(size(frame_data));
        row_peaks = zeros(size(frame_data));
        row_proms = zeros(size(frame_data));
        
        for i = 1:size(frame_data, 1)
            column = frame_data(i, :);
            [pks, locs, widths, proms] = findpeaks(column);
            for j = 1:numel(pks)                
                column_peaks(i, locs(j)) = 1;
                column_proms(i, locs(j)) = proms(j);                
            end
        end
        
        for i = 1:size(frame_data, 2)
            row = frame_data(:, i);
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
        %}
        
        start_frame = o.data.get_stim_start_frame();
        frame_data_all = o.data.data(:, :, 1:start_frame);
        frame_data_all = frame_data_all(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)), :);
        sigma = std(frame_data_all, 0, 3);
        sigma = flipud(sigma);
        
        
        %{
        dilationMask = ones(3);
        dilationMask(5) = 0;
        dilSignal = imdilate(frame_data, dilationMask);
        
        peaks = frame_data > dilSignal;
        
        %peaks = (frame_data - dilSignal) > 0.002;
        
        peaks = find(peaks == 1);
        %}
        
        %{
        centers = [];
        radii = [];
        
        for i = 1:numel(peaks)
           
            v = int64(peaks(i));
            x = idivide(v, int64(size(frame_data, 1))) + 1;
            y = mod(v, size(frame_data, 1)) + 1;
            
            if x == 1 || y == 1 || x == size(frame_data, 2) || y == size(frame_data, 1)
               continue; 
            end
            
            if proms(y, x) < 2*sigma(y, x)
                continue;
            end
            
            centers = [centers; [x, y] ];
            radii = [radii; 1];
            
        end
        
        viscircles(centers, radii);
        
        %}
        
        i = 1;
        
        %n = 20;
        %shading interp;
        %colormap(parula(n + 1)); 
        %hold on;
        %[M, c] = contour3(X, Y, frame_data, n);
        
        %surf(X, Y, frame_data, 'Edgecolor', 'none');
        
        %c.LineWidth = 3;
        
        
        %{
        if o.xenapse_view_image_initialized
            
            set(o.xenapse_view_image, 'CData', frame_data_u8); 
            
        else
            
            delete(o.xenapse_view_image);
            o.xenapse_view_image = imshow(frame_data_u8); 
            %caxis(o.xenapse_view_axes, [0 1]);
            %colormap(o.xenapse_view_axes, o.views_colormap);
            colormap(o.xenapse_view_axes, o.views_colormap);
            % 'CDataMapping', 'scaled'
            o.xenapse_view_image_initialized = 1;
            
        end
        %}
        
        
        % id y x amplitude area
        
        new_spot_circles = {};
        new_spot_texts = {};
        
        if o.get_show_detected_spots()
        
            for spi = 1:numel(spots)

                s = spots{spi};

                p = s(2:3);
                area = s(5);
                id = s(1);

                x = p(2);
                y = p(1);

                r = sqrt(area / 3.14);

                c = draw_circle(x, y, r);
                new_spot_circles{spi} = c;
                
                if o.get_do_track()
                    t = text(x, y, num2str(id), 'Color', 'black', 'HorizontalAlignment', 'center', 'BackgroundColor', [1, 1, 1, 0.5], ...
                        'EdgeColor', [0, 0, 0, 0.5]);
                    new_spot_texts{spi} = t;
                end    



            end
            
        end
        
        cellfun(@delete, o.spot_circles)        
        cellfun(@delete, o.spot_texts)
        
        o.spot_circles = new_spot_circles;
        o.spot_texts = new_spot_texts;
        
        
        %{
        center = o.xenapse_centers(o.selected_xenapse, :);
        radius = o.xenapse_radii(o.selected_xenapse);
       
        rs = radius * 2 * o.xenapse_size_extension;
        hs = rs / 2;
       
        rect_position = [center(1) - hs center(2) - hs rs rs];
        rect_color = [1.0 1.0 1.0];
        %}
        
    end

    function update_general_view(o)
        
        frame_data = o.data.data(:, :, o.viewed_frame_index);

        if o.get_subtract_background() == 1
            frame_data = frame_data - o.data.background;
            if o.min_value < 0
                frame_data = frame_data - o.min_value;
            end

        end

        if o.get_do_lowpass_filtering() == 1
            
            frame_data = o.lowpass_wavelet_filter(frame_data);
            
        end
        
        dt = o.get_display_threshold();        
        frame_data_u8 = frame_data / dt;
        frame_data_u8(frame_data_u8 > 1) = 1;
        frame_data_u8 = uint8(frame_data_u8 * 255);

        axes(o.general_view_axes);

        if o.general_view_image_initialized

            set(o.general_view_image, 'CData', frame_data_u8); 

        else

            delete(o.general_view_image);
            o.general_view_image = imshow(frame_data_u8); 
            set(o.general_view_image, 'ButtonDownFcn', @o.on_general_view_image_clicked); 
            colormap(o.general_view_axes, o.views_colormap);
            % caxis(o.general_view_axes, [0 1]);
            % 'CDataMapping', 'scaled'
            o.general_view_image_initialized = 1;

        end    
        
    end
    
    function analyze_intensity_levels(o)
        
    end
    
    function load(o, fn)

        o.general_view_image_initialized = 0;
        o.xenapse_view_image_initialized = 0;           

        o.selected_xenapse = 1;
        o.viewed_frame_index = 1;        
        
        o.loaded_file_name = fn;
        
        o.update_title();

        ta = get(o.checkbox_temporal_averaging, 'Value');
        
        o.data.load(fn, ta);
        
        o.update_general_view();        
        o.update_xenapse_view();
        o.update_selected_xenapse();
        
        % adjust ui parameters
       
        max_frames = size(o.data, 3);
        
        set(o.slider_frames{1}, 'Value', 1, 'Minimum', 1, 'Maximum', max_frames);   
                    
        o.update_duration_text();         
        
    end

    function [spots_history, intensity] = analyze_xenapse(o, xenapse_index, waitbar_object, current_progress, total_work)

        
        %tracker = PeakTracker();     
        %tracker.prominence_threshold = o.peak_tracker.prominence_threshold; 
        %sigma = o.peak_tracker.prominence_threshold;
        
        %{
        tracker = SpotTracker();     
        madwc = get(o.slider_madwc{1}, 'Value') / 10000.;
        tracker.madwc = madwc;
        %}
             
        subtract_background = o.get_subtract_background();
        rect = get_xenapse_rectangle(o, xenapse_index);
        rect = int32(rect);
                
        if subtract_background
            start_frame = o.get_stim_start_frame();
            bg = o.background(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)));
        else
            start_frame = 1;
        end
        
        intensity = [];
        
        lowpass_filtering = o.get_do_lowpass_filtering();
        
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
        
        subtract_background = o.get_subtract_background();
        lowpass_filtering = o.get_do_lowpass_filtering();

        xenapse_data = o.data(rect(2):(rect(2) + rect(4)), rect(1):(rect(1) + rect(3)), :);      
        
        event_tracker = EventTracker();
        
        stim_start_frame = o.get_stim_start_frame();
                    
        prominent_spots = {};
        spots_history = event_tracker.detect_events(xenapse_data, subtract_background, lowpass_filtering, stim_start_frame);
        
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
    
    function set_plot_annotation(o, data)
        
        disp(data);
        
        % Calculate the min, max, mean, median, and standard deviation
        dmin = min(data);
        dmax = max(data);
        mn = mean(data);
        md = median(data);
        stdv = std(data);
        % Create the labels
        n = sprintf('N: %d', numel(data));
        minlabel = sprintf('Min: %g', dmin);
        maxlabel = sprintf('Max: %g', dmax);
        mnlabel = sprintf('Mean: %g', mn);
        mdlabel = sprintf('Median: %g', md);
        stdlabel = sprintf('Std Deviation: %g', stdv);
        % Create the textbox
        h = annotation('textbox', [0.58 0.75 0.1 0.1]);
        set(h,'String', { n, minlabel, maxlabel, mnlabel, mdlabel, stdlabel });        
        
    end    
    
    function analyze_xenapses(o, indices)

        wait_bar = waitbar(0, 'Analyzing events...');

        subtract_background = o.get_subtract_background();
        
        [intensities, all_spots_history] = analyze_xenapses(o, indices, subtract_background, lowpass_filtering)
                
        %total_frames_to_analyze = size(o.data, 3) - start_frame + 1;
        %total_work = total_frames_to_analyze * numel(indices);
        %current_progress = 1;
        
        life_times = [];
        displacements = [];        
        intensities = [];
        latencies = [];

        all_spots_history = {};
        
        for k = 1:numel(all_spots_history)
            
            for i = 1:numel(all_spots_history{k})
                
                sph = all_spots_history{k}{i};

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

        % close(wait_bar);

        [~, fn, ~] = fileparts(o.loaded_file_name);

        if o.get_do_track()    

            save([fn '.mat'], 'all_spots_history');

            f = figure;
            set(f, 'name', ['Life time - ' fn], 'NumberTitle', 'off');
            life_times = single(life_times) / o.frame_rate;        
            h = histogram(life_times, 'FaceColor', 'g');
            o.set_plot_annotation(life_times);

            f = figure;
            set(f, 'name', ['Motility - ' fn], 'NumberTitle', 'off');
            h = histogram(displacements, 'FaceColor', 'r');
            o.set_plot_annotation(displacements);

            f = figure;
            set(f, 'name', ['Latency - ' fn], 'NumberTitle', 'off');
            latencies = single(latencies) / o.frame_rate;        
            h = histogram(latencies, 'FaceColor', 'c');
            o.set_plot_annotation(latencies);

        end
    
        f = figure;
        set(f, 'name', ['Intensity - ' fn], 'NumberTitle', 'off');        
        intensities = mean(intensities, 1);
        time_line = (start_frame - 1) / o.frame_rate + single([1:total_frames_to_analyze]) / o.frame_rate;
        plot(time_line, intensities);
        
    end
    
        
end % methods

end % class