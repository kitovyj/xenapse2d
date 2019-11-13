function  vis3D(Img, method)
%   Author: Haoyi Liang <lianghaoyi91@gmail.com> 2017
if nargin == 0    
      Img = load('./data/Img.mat');
      Img = Img.Img;
      method = 'bicubic';
elseif nargin == 1
      method = 'bicubic';    
end
margin_ratio = 0.2;
global frame_size;
[Img, frame_size] = add_frame(Img, margin_ratio);
full_turn_degree = 360;
Jaw_degree = 0;
Pitch_degree = 0;
Roll_degree = 0;
global last_set; % JAW 0, PITCH 1, ROLL 2.
global InitialCoord;
FntSz = 10;
BtnSz = 10;
JPR_FntSz = 10;
figure();
axes('position',[0,0.2,1,0.8]), imshow(do_project(Img, Jaw_degree, Pitch_degree, Roll_degree))
FigPos = get(gcf,'Position');
Jaw_Pos = [0 0 0 0];
Pitch_Pos = [0 0 0 0];
Roll_Pos = [0 0 0 0];
Jawtxt_Pos = [0 0 0 0];
Pitchtxt_Pos = [0 0 0 0];
Rolltxt_Pos = [0 0 0 0];
Btn_Pos = [0 0 0 0];
Jawval_Pos = [0 0 0 0];
Pitchval_Pos = [0 0 0 0];
Rollval_Pos = [0 0 0 0];
Jawhand = uicontrol('Style', 'slider','Min',0,'Max',full_turn_degree,'Value',Jaw_degree,'SliderStep',[1/(full_turn_degree-1) 10/(full_turn_degree-1)],'Position', Jaw_Pos,'Callback', {@JawSliceSlider, Img});
Jawtxthand = uicontrol('Style', 'text','Position', Jawtxt_Pos,'String',sprintf('Jaw(%c)', char(176)), 'BackgroundColor', [0.8 0.8 0.8], 'FontSize', FntSz); 
Pitchhand = uicontrol('Style', 'slider','Min',0,'Max',full_turn_degree,'Value',Pitch_degree,'SliderStep',[1/(full_turn_degree-1) 10/(full_turn_degree-1)],'Position', Pitch_Pos,'Callback', {@PitchSliceSlider, Img});
Pitchtxthand = uicontrol('Style', 'text','Position', Pitchtxt_Pos,'String',sprintf('Pitch(%c)', char(176)), 'BackgroundColor', [0.8 0.8 0.8], 'FontSize', FntSz); 
Rollhand = uicontrol('Style', 'slider','Min',0,'Max',full_turn_degree,'Value',Roll_degree,'SliderStep',[1/(full_turn_degree-1) 10/(full_turn_degree-1)],'Position', Roll_Pos,'Callback', {@RollSliceSlider, Img});
Rolltxthand = uicontrol('Style', 'text','Position', Rolltxt_Pos,'String',sprintf('Roll(%c)', char(176)), 'BackgroundColor', [0.8 0.8 0.8], 'FontSize', FntSz); 
Btnhand = uicontrol('Style', 'pushbutton','Position', Btn_Pos,'String','Reset', 'FontSize', BtnSz, 'Callback' , @AutoAdjust);
Jawvalhand = uicontrol('Style', 'edit','Position', Jawval_Pos,'String',sprintf('%6.0f',Jaw_degree), 'BackgroundColor', [1 1 1], 'FontSize', JPR_FntSz,'Callback', @JawvalChanged);
Pitchvalhand = uicontrol('Style', 'edit','Position', Pitchval_Pos,'String',sprintf('%6.0f',Pitch_degree), 'BackgroundColor', [1 1 1], 'FontSize', JPR_FntSz,'Callback', @PitchvalChanged);
Rollvalhand = uicontrol('Style', 'edit','Position', Rollval_Pos,'String',sprintf('%6.0f',Roll_degree), 'BackgroundColor', [1 1 1], 'FontSize', JPR_FntSz,'Callback', @RollvalChanged);
set (gcf, 'WindowScrollWheelFcn', @mouseScroll);
set (gcf, 'ButtonDownFcn', @mouseClick);
set(get(gca,'Children'),'ButtonDownFcn', @mouseClick);
set(gcf,'WindowButtonUpFcn', @mouseRelease)
set(gcf,'ResizeFcn', @figureResized)
% -=< Figure resize callback function >=-
    function figureResized(object, eventdata)
        last_set = 0;
        FigPos = get(gcf,'Position');        
        Btn_Pos = [470 80 80 20];        
        set(Btnhand,'Position', Btn_Pos);
        
        Jawtxt_Pos = [30 45 50 20];
        Jaw_Pos = [160 45 uint16(FigPos(3)-190)+1 20];
        Jawval_Pos = [90 45 40 20];                            
        set(Jawhand,'Position', Jaw_Pos);        
        set(Jawtxthand,'Position', Jawtxt_Pos);
        set(Jawvalhand, 'Position', Jawval_Pos);
        
        Pitchtxt_Pos = [30 25 50 20];
        Pitch_Pos = [160 25 uint16(FigPos(3)-190)+1 20];
        Pitchval_Pos = [90 25 40 20];                            
        set(Pitchhand,'Position', Pitch_Pos);        
        set(Pitchtxthand,'Position', Pitchtxt_Pos);
        set(Pitchvalhand, 'Position', Pitchval_Pos);
        
        Rolltxt_Pos = [30 5 50 20];
        Roll_Pos = [160 5 uint16(FigPos(3)-190)+1 20];
        Rollval_Pos = [90 5 40 20];                            
        set(Rollhand,'Position', Roll_Pos);        
        set(Rolltxthand,'Position', Rolltxt_Pos);
        set(Rollvalhand, 'Position', Rollval_Pos);                     
    end
% -=< Slice slider callback function >=-
    function JawSliceSlider (hObj,event, Img)
        last_set = 0;
        Jaw_degree = round(get(hObj,'Value'));
        set(get(gca,'children'),'cdata',do_project(Img, Jaw_degree, Pitch_degree, Roll_degree))        
        set(Jawvalhand, 'String', sprintf('%d',Jaw_degree))
    end
    function PitchSliceSlider (hObj,event, Img)
        last_set = 1;
        Pitch_degree = round(get(hObj,'Value'));
        set(get(gca,'children'),'cdata',do_project(Img, Jaw_degree, Pitch_degree, Roll_degree))        
        set(Pitchvalhand, 'String', sprintf('%d',Pitch_degree))
    end
    function RollSliceSlider (hObj,event, Img)
        last_set = 2;
        Roll_degree = round(get(hObj,'Value'));
        set(get(gca,'children'),'cdata',do_project(Img, Jaw_degree, Pitch_degree, Roll_degree))        
        set(Rollvalhand, 'String', sprintf('%d',Roll_degree))
    end
% -=< Mouse scroll wheel callback function >=-
    function mouseScroll (object, eventdata)
        UPDN = eventdata.VerticalScrollCount;        
        switch last_set
            case 0
                Jaw_degree = Jaw_degree - UPDN*10;
                Jaw_degree  = check_range(Jaw_degree, [0 full_turn_degree]);
                set(Jawhand,'Value',Jaw_degree);
                set(Jawvalhand, 'String', sprintf('%d',Jaw_degree))
            case 1
                Pitch_degree = Pitch_degree - UPDN*10;
                Pitch_degree  = check_range(Pitch_degree, [0 full_turn_degree]);
                set(Pitchhand,'Value',Pitch_degree);
                set(Pitchvalhand, 'String', sprintf('%d',Pitch_degree))
            case 2
                Roll_degree = Roll_degree - UPDN*10;
                Roll_degree  = check_range(Roll_degree, [0 full_turn_degree]);
                set(Rollhand,'Value',Roll_degree);
                set(Rollvalhand, 'String', sprintf('%d',Roll_degree))
        end
        
        set(get(gca,'children'),'cdata',do_project(Img, Jaw_degree, Pitch_degree, Roll_degree))
        
    end
% -=< Mouse button released callback function >=-
    function mouseRelease (object,eventdata)
        set(gcf, 'WindowButtonMotionFcn', '')
    end
% -=< Mouse click callback function >=-
    function mouseClick (object, eventdata)
        MouseStat = get(gcbf, 'SelectionType');
        if (MouseStat(1) == 'a')        %   RIGHT CLICK
            InitialCoord = get(0,'PointerLocation');
            set(gcf, 'WindowButtonMotionFcn', @WinLevAdj);
        end
    end
% -=< Jaw text adjustment >=-
    function JawvalChanged(varargin)
        last_set = 0;
        Jawval = str2double(get(Jawvalhand, 'string'));
        Jaw_degree = Jawval;
        set(Jawhand, 'Value', Jaw_degree);        
        set(get(gca,'children'),'cdata',do_project(Img, Jaw_degree, Pitch_degree, Roll_degree))              
    end
% -=< Pitch text adjustment >=-
    function PitchvalChanged(varargin)
        last_set = 1;
        Pitchval = str2double(get(Pitchvalhand, 'string'));
        Pitch_degree = Pitchval;
        set(Pitchhand, 'Value', Pitch_degree);        
        set(get(gca,'children'),'cdata',do_project(Img, Jaw_degree, Pitch_degree, Roll_degree))              
    end
% -=< Roll text adjustment >=-
    function RollvalChanged(varargin)
        last_set = 2;
        Rollval = str2double(get(Rollvalhand, 'string'));
        Roll_degree = Rollval;
        set(Rollhand, 'Value', Roll_degree);        
        set(get(gca,'children'),'cdata',do_project(Img, Jaw_degree, Pitch_degree, Roll_degree))              
    end
% -=< Window and level auto adjustment callback function >=-
    function AutoAdjust(object,eventdata)
        last_set = 0;
        Jaw_degree = 0;
        Pitch_degree = 0;
        Roll_degree = 0;
        set(Jawhand, 'Value', Jaw_degree);        
        set(Pitchhand, 'Value', Pitch_degree);   
        set(Rollhand, 'Value', Roll_degree);   
        set(get(gca,'children'),'cdata',do_project(Img, Jaw_degree, Pitch_degree, Roll_degree))
        set(Jawvalhand, 'String', sprintf('%d',Jaw_degree))
        set(Pitchvalhand, 'String', sprintf('%d',Pitch_degree))
        set(Rollvalhand, 'String', sprintf('%d',Roll_degree))
    end
    function [frame_img] = do_project(stack, jaw, pitch, roll)        
        % yaw
        stack = imrotate(stack, jaw, method);
        % pitch
        stack = ipermute(imrotate(permute(stack,[1,3,2]),pitch, method), [1,3,2]);
        % roll
        stack = ipermute(imrotate(permute(stack,[2,3,1]), roll, method), [2,3,1]);
        pro_img = max(stack,[], 3);
        frame_img = zeros(frame_size);
        frame_center = floor(frame_size/2);
        pro_center = floor(size(pro_img)/2);
        common_area_size = floor(min(frame_size, size(pro_img))/2);
        frame_img(frame_center(1) - common_area_size(1) +1 :frame_center(1)+common_area_size(1)-1,...
            frame_center(2) - common_area_size(2) +1 :frame_center(2)+common_area_size(2)-1) = ...
            pro_img(pro_center(1) - common_area_size(1) +1 :pro_center(1)+common_area_size(1)-1,...
            pro_center(2) - common_area_size(2) +1 :pro_center(2)+common_area_size(2)-1);
    end
    function output  = check_range(input, range)        
        output = input;
        if (input < range(1))
            output = range(2);
        elseif (input > range(2))
            output = range(1);
        end
    end
end
function [new_stack, frame_size] = add_frame(stack, margin_ratio)
    org_size = size(stack);
    margin_size = round(org_size*margin_ratio);
    end_boundary = [org_size(1)+margin_size(1)-1, org_size(2)+margin_size(2)-1, org_size(3)+margin_size(3)-1];
    
    new_stack = zeros(org_size + 2*margin_size);
    new_stack(margin_size(1):end_boundary(1),...
        margin_size(2):end_boundary(2),...
        margin_size(3):end_boundary(3)) = stack;
    
    new_stack(margin_size(1), margin_size(2), margin_size(3):end_boundary(3)) = 1;
    new_stack(margin_size(1), margin_size(2):end_boundary(2), margin_size(3)) = 1;
    new_stack(margin_size(1):end_boundary(1), margin_size(2), margin_size(3)) = 1;
    
    new_stack(margin_size(1), end_boundary(1), margin_size(3):end_boundary(3)) = 0.5;
    new_stack(margin_size(1), margin_size(2):end_boundary(2), end_boundary(3)) = 0.5;
    new_stack(margin_size(1):end_boundary(1), margin_size(2), end_boundary(3)) = 0.5;
    
    new_stack(end_boundary(1), end_boundary(1), margin_size(3):end_boundary(3)) = 0.5;
    new_stack(end_boundary(1), margin_size(2):end_boundary(2), end_boundary(3)) = 0.5;
    new_stack(margin_size(1):end_boundary(1), end_boundary(2), end_boundary(3)) = 0.5;
    
    new_stack(end_boundary(1), margin_size(1), margin_size(3):end_boundary(3)) = 0.5;
    new_stack(end_boundary(1), margin_size(2):end_boundary(2), margin_size(3)) = 0.5;
    new_stack(margin_size(1):end_boundary(1), end_boundary(2), margin_size(3)) = 0.5;
    frame_size = [size(new_stack,1), size(new_stack,2)];
end
