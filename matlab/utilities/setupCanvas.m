function setupCanvas()
if size(findall(0),1) > 1
    delete(findall(0))
end

scrSz = get(groot, 'ScreenSize');
screenCenter = scrSz(3:4)/2;
canvas_size = CanvasConstants.CANVAS_LIMITS;
fig_inset = .15;
panel_inset = .7;
fig_pos = [fig_inset*scrSz(3) fig_inset*scrSz(4) (1-2*fig_inset)*scrSz(3) (1-2*fig_inset)*scrSz(4)];
root_obj = groot;
if size(root_obj.MonitorPositions,1) == 2
    fig_pos(1) = fig_pos(1)-1800;
end
form_pos = [panel_inset 0 (1-panel_inset) 1];

% f = figure('DockControls', 'off',...
%     'MenuBar', 'none',...
%     'Name', 'Arena Setup',...
%     'NumberTitle', 'off', ...
%     'ToolBar', 'none', ...
%     'Position', [-canvas_size/2+screenCenter canvas_size(1) canvas_size(2)],...
%     'HandleVisibility', 'off');

f = figure('DockControls', 'off',...
           'MenuBar', 'none',...
           'Name', 'Canvas Setup',...
           'NumberTitle', 'off', ...
           'ToolBar', 'none', ...
           'Position', fig_pos,...
           'HandleVisibility', 'off');

    pl = uipanel('Parent',f,...
                 'Title','Canvas Area',...
                 'TitlePosition','centertop',...
                 'FontSize',12,...
                 'UserData','Canvas Axes Panel',...
                 'BackgroundColor',[.93 .93 .93],...
                 'Position',[0 0 .7 1]);

    pr = uipanel('Parent',f,...
                'Title','Component Data',...
                'TitlePosition','centertop',...
                'FontSize',12,...
                'UserData','Component Data Panel',...
                'BackgroundColor',[.93 .93 .93],...
                'Position', form_pos);


    tabgp = uitabgroup(pr,'Position',[.02 .01 .96 .99]);
            tab1 = uitab(tabgp,'Title','Neuron Settings',...
                'UserData','Neuron Info Tab');
            tab2 = uitab(tabgp,'Title','Link Settings',...
                'UserData','Link Info Tab');

model = CanvasModel();
view = CanvasView(model, 'Parent', pl);
CanvasController(model, view);