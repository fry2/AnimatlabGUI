% Copyright 2016 The MathWorks, Inc.
classdef CanvasView < matlab.mixin.SetGet
    
    properties (Access = public)
        
        model        
        graphic_objects = struct()
        listeners = struct()
        
    end
    
    properties
        
        BeingDeleted = 'off'
        
    end
    
    properties (Dependent)
        
        Parent
        Position
        OuterPosition
        Units
        Visible
        UIContextMenu
        CurrentPoint
        
    end
    
    events (NotifyAccess = private)
        viewDeleted
        graphicItemCreated
        canvasSizeChanged
    end
    
    methods
        
        function obj  = CanvasView(model, varargin)
            
            obj.model = model;            
            obj.graphic_objects.Neurons = ...
                matlab.graphics.primitive.Rectangle.empty;            
            obj.graphic_objects.Obstacles = ...
                matlab.graphics.primitive.Rectangle.empty;
            
            obj.setupAxesAndImage(varargin{:});
            
            obj.setupStimAxes();
            obj.setupStimForm();
            
            obj.setupAxisChanger();
            
            obj.setupForm();
            obj.disableForm({'n','l'});
            
            %obj.setupRobot();            
            obj.modelChanged();
            
            obj.listeners.itemAdded = event.listener(obj.model, 'itemAdded', ...
                @(~, eventData) obj.addItem(eventData.Type, eventData.Index));
            
            obj.listeners.itemDeleted = event.listener(obj.model, 'itemDeleted', ...
                @(~, eventData) obj.deleteItem(eventData.Type, eventData.Index));
            
            obj.listeners.itemMoved = event.listener(obj.model, 'itemMoved', ...
                @(~, eventData) obj.moveItem(eventData.Type, eventData.Index));
            
            obj.listeners.modelDeleted = event.listener(obj.model, 'modelDeleted', ...
                @(~, ~) obj.delete());
            
            obj.listeners.linkAdded = event.listener(obj.model,'linkAdded',...
                @(~,eventData) obj.addLink(eventData.Type, eventData.Index,eventData.Ends));
            
        end
        %% delete the view
        function delete(obj)
            
            obj.BeingDeleted = 'on';
            if isvalid(obj.graphic_objects.axes) || ...
                    strcmpi(obj.graphic_objects.axes.BeingDeleted, 'off')
                delete(obj.graphic_objects.axes);
            end
            notify(obj, 'viewDeleted');
            
        end
        %% formSelection: enable data for the selected item type
        function formSelection(obj,type,index)
            if contains(type,'link')
                type = 'l';
            end
            obj.enableForm({type});
            switch type
                case 'n'
                    neuron = obj.model.neuron_objects(index);
                    obj.graphic_objects.FormObjs{2}(1,2).String = neuron.name;
                    obj.graphic_objects.FormObjs{2}(2,2).String = neuron.restingpotential;
                    obj.graphic_objects.FormObjs{2}(3,2).String = neuron.timeconstant;
                    obj.graphic_objects.FormObjs{2}(4,2).String = neuron.initialthreshold;
                    for i=1:size(obj.graphic_objects.FormObjs{2},1)
                        obj.graphic_objects.FormObjs{2}(i,2).UserData = {type,index};
                    end
                    if ~isempty(neuron.stimulus)
                        stim = neuron.stimulus;
                        obj.graphic_objects.FormObjs{4}(1,2).String = stim.name;
                        obj.graphic_objects.FormObjs{4}(2,2).String = stim.amplitude;
                        obj.graphic_objects.FormObjs{4}(3,2).String = stim.starttime;
                        obj.graphic_objects.FormObjs{4}(4,2).String = stim.endtime;
                        obj.graphic_objects.FormObjs{4}(5,2).Value = stim.enabled;
                        for i=1:size(obj.graphic_objects.FormObjs{4},1)
                            obj.graphic_objects.FormObjs{4}(i,2).UserData = {'stim',index};
                        end
                        obj.enableForm('stimulus');
                    else
                        obj.disableForm('stimulus')
                    end
                    obj.updateStimPlot(neuron);
                case 'l'
                    link = obj.model.link_objects(index);
                    synapse = obj.model.synapse_types(contains({obj.model.synapse_types.name},link.synaptictype));
                    obj.graphic_objects.FormObjs{3}(1,2).String = synapse.equil_pot;
                    obj.graphic_objects.FormObjs{3}(2,2).String = synapse.max_syn_cond;
                    for i=1:2
                        obj.graphic_objects.FormObjs{3}(i,2).UserData = {type,index};
                    end
            end
        end
        %% disableForm: disable the data input form
        function disableForm(obj,type)
            if ~iscell(type)
                if ischar(type)
                    type = {type};
                else
                    error('disableForm in obj.view was passed a non-cell object type. Type changed to first valid type input.\n')
                end
            end
            for k = 1:length(type)
                switch type{k}
                    case 'entire'
                        formnumber = 1:length(obj.graphic_objects.FormObjs);
                    case 'n'
                        formnumber = 2;
                    case 'l'
                        formnumber = 3;
                    case 'stimulus'
                        formnumber = 4;
                        cla(obj.graphic_objects.axes_stim)
                        cla(obj.graphic_objects.axes_totmem)
                end
                for i = 1:length(formnumber)
                    numLines = size(obj.graphic_objects.FormObjs{formnumber(i)},1);
                    for j=1:numLines
                        [obj.graphic_objects.FormObjs{formnumber(i)}(j,:).Enable] = deal('off');
                    end
                end
            end
        end
        %% enableForm : enable the data entry form
        function enableForm(obj,type)
            if ~iscell(type)
                if ischar(type)
                    type = {type};
                else
                    error('enableForm in obj.view was passed a non-cell object type. Type changed to first valid type input.\n')
                end
            end
            childrenInfo = cell(length(obj.Parent.Children),1);
            for i=1:length(obj.Parent.Children)
                childrenInfo{i} = obj.Parent.Children(i).UserData;
            end
            component_panel = strcmp(childrenInfo,'Component Data Panel');
            for k = 1:length(type)
                switch type{k}
                    case 'n'
                        selected_tab = obj.Parent.Children(component_panel).Children.Children(1);
                        obj.Parent.Children(component_panel).Children.SelectedTab = selected_tab;
                        formnumber = 2;
                    case 'l'
                        selected_tab = obj.Parent.Children(component_panel).Children.Children(2);
                        obj.Parent.Children(component_panel).Children.SelectedTab = selected_tab;
                        formnumber = 3;
                    case 'stimulus'
                        formnumber = 4;
                end
                numFormObjs = size(obj.graphic_objects.FormObjs{formnumber},1);
                for i=1:numFormObjs
                    for j=1:2
                        obj.graphic_objects.FormObjs{formnumber}(i,j).Enable = 'on';
                    end
                end
            end
        end
    end
    methods % set
        function set.Parent(obj, p)
            if strcmp(obj.graphic_objects.axes.Parent.Type,'uipanel')
                obj.graphic_objects.axes.Parent.Parent = p;
            else
                obj.graphic_objects.axes.Parent = p;
            end
        end
        
        function set.Position(obj, p)
            obj.graphic_objects.axes.Position = p;
        end
        
        function set.OuterPosition(obj, p)
            obj.graphic_objects.axes.OuterPosition = p;
        end
        %%
        % |MONOSPACED TEXT|
        function set.Units(obj, p)
            obj.graphic_objects.axes.Units = p;
        end
        
        function set.Visible(obj, p)
            obj.graphic_objects.axes.Visible = p;
        end
        
        function set.UIContextMenu(obj, cm)
            
            obj.graphic_objects.image.UIContextMenu = cm;
            
        end
        
        function set.CurrentPoint(obj, cp)
            obj.graphic_objects.axes.CurrentPoint = cp;
        end
    end

    methods % get
        %%
        function val = get.Parent(obj)
            if strcmp(obj.graphic_objects.axes.Parent.Type,'uipanel')
                val = obj.graphic_objects.axes.Parent.Parent;
            else
                val = obj.graphic_objects.axes.Parent;
            end
        end
        
        function val = get.Position(obj)
            val = obj.graphic_objects.axes.Position;
        end
        
        function val = get.OuterPosition(obj)
            val = obj.graphic_objects.axes.OuterPosition;
        end
        
        function val = get.Units(obj)
            val = obj.graphic_objects.axes.Units;
        end
        
        function val = get.Visible(obj)
            val = obj.graphic_objects.axes.Visible;
        end
        
        function val = get.UIContextMenu(obj)
            
            val = obj.graphic_objects.image.UIContextMenu;
            
        end
        
        function val = get.CurrentPoint(obj)
            
            val = obj.graphic_objects.axes.CurrentPoint;
            
        end 
    end
    
    methods (Access=private) % constructor and destructor
        %% setupAxisChanger : the data entry form panel
        function setupAxisChanger(obj)
            formpanel = obj.Parent.Children(contains({obj.Parent.Children.Title},'Canvas Area'));
            changerpos = [.1 .95 .15 .03];
            
            changerlabel = uicontrol(formpanel,'Style','text',...
                'String','Axis Limits: ',...
                'HorizontalAlignment','right',...
                'FontSize',12,...
                'Enable','on',...
                'Units','normalized',...
                'Position',changerpos);
            
            changerfield = uicontrol(formpanel,'Style','edit',...
                'Enable','on',...
                'FontSize',12,...
                'Units','normalized',...
                'Position',changerpos+[.15 0 .46 0],...
                'Callback', {@obj.fieldCallback,'axislimits'});
            
            obj.graphic_objects.FormObjs{1}(1,1) = changerlabel;
            obj.graphic_objects.FormObjs{1}(1,2) = changerfield;
        end
        %% setupStimForm : setup Stimulus data entry section
        function setupStimForm(obj)
%             formpanel = obj.Parent.Children(1);
            formpanel = obj.Parent.Children(contains({obj.Parent.Children.Title},'Stimulus Panel'));
            stimtab = formpanel.Children.Children(1);
            memtab = formpanel.Children.Children(2);
            fields = {'Name','name',[];...
                    'Amplitude','amplitude',[0 15];...
                    'Start Time','starttime',[0 10];...
                    'End Time','endtime',[0 10];...
                    'Enabled','enabled',0;...
                    'Import','stimimport',0};
                
            fieldwidth = .15;
            labelbox = @(labelnum) [.76 .69-(labelnum-1)*.12 .05 .1];
            fieldbox = @(fieldnum) [.81 .7-(fieldnum-1)*.12 fieldwidth .1]; 
            
            for i=1:length(fields)
                label_stim = uicontrol(stimtab,'Style','text',...
                    'String',[fields{i},': '],...
                    'HorizontalAlignment','right',...
                    'FontSize',9,...
                    'Enable','off',...
                    'Units','normalized',...
                    'Position',labelbox(i));

                if size(fields{i,3},2) == 1
                    field_stim = uicontrol(stimtab,'Style','radiobutton',...
                        'Enable','off',...
                        'FontSize',9,...
                        'Units','normalized',...
                        'Position',fieldbox(i),...
                        'Callback', {@obj.fieldCallback,fields{i,2},fields{i,3}});
                else
                    field_stim = uicontrol(stimtab,'Style','edit',...
                        'Enable','off',...
                        'FontSize',9,...
                        'Units','normalized',...
                        'Position',fieldbox(i),...
                        'Callback', {@obj.fieldCallback,fields{i,2},fields{i,3}});
                end

                %%% Stimulus Fields
                obj.graphic_objects.FormObjs{4}(i,1) = label_stim;
                    obj.graphic_objects.FormObjs{4}(i,2) = field_stim;
            end
        end
        %% setupForm : the data entry form panel
        function setupForm(obj)
%             formpanel = obj.Parent.Children(1);
            formpanel = obj.Parent.Children(contains({obj.Parent.Children.Title},'Component Data'));
            formtab1 = formpanel.Children.Children(1);
            formtab2 = formpanel.Children.Children(2);
            namepos = [0 .9 .15 .03];
            restpos = namepos+[0 -.05 .17 0];
            
            fieldwidth = .56;
            labelbox = @(labelnum) [0 .9-(labelnum-1)*.05 .98-fieldwidth .03];
            fieldbox = @(fieldnum) [.98-fieldwidth .9-(fieldnum-1)*.05 fieldwidth .03];
            
            namelabel = uicontrol(formtab1,'Style','text',...
                'String','Name: ',...
                'HorizontalAlignment','right',...
                'FontSize',9,...
                'Enable','off',...
                'Units','normalized',...
                'Position',labelbox(1));
            
            namefield = uicontrol(formtab1,'Style','edit',...
                'Enable','off',...
                'FontSize',9,...
                'Units','normalized',...
                'Position',fieldbox(1),...
                'Callback', {@obj.fieldCallback,'name'});
            
            restlabel = uicontrol(formtab1,'Style','text',...
                'String','Resting Potential (mV): ',...
                'HorizontalAlignment','right',...
                'FontSize',9,...
                'Enable','off',...
                'Units','normalized',...
                'Position',labelbox(2));
            
            restfield = uicontrol(formtab1,'Style','edit',...
                'Enable','off',...
                'FontSize',9,...
                'Units','normalized',...
                'Position',fieldbox(2),...
                'Callback', {@obj.fieldCallback,'restingpotential',[-100 100]});
            
            tclabel = uicontrol(formtab1,'Style','text',...
                'String','Time Constant (ms): ',...
                'HorizontalAlignment','right',...
                'FontSize',9,...
                'Enable','off',...
                'Units','normalized',...
                'Position',labelbox(3));
            
            tcfield = uicontrol(formtab1,'Style','edit',...
                'Enable','off',...
                'FontSize',9,...
                'Units','normalized',...
                'Position',fieldbox(3),...
                'Callback', {@obj.fieldCallback,'timeconstant',[1 100]});
            
            initthresh_label = uicontrol(formtab1,'Style','text',...
                'String','Initial Threshold (mV): ',...
                'HorizontalAlignment','right',...
                'FontSize',9,...
                'Enable','off',...
                'Units','normalized',...
                'Position',labelbox(4));
            
            initthresh_field = uicontrol(formtab1,'Style','edit',...
                'Enable','off',...
                'FontSize',9,...
                'Units','normalized',...
                'Position',fieldbox(4),...
                'Callback', {@obj.fieldCallback,'initialthreshold',[-100 500]});
            %%%%%%%%%% Link Info
            eqpotlabel = uicontrol(formtab2,'Style','text',...
                'String','Equilibrium Potential (mV): ',...
                'HorizontalAlignment','right',...
                'FontSize',9,...
                'Enable','off',...
                'Units','normalized',...
                'Position',labelbox(1));
            
            eqpotfield = uicontrol(formtab2,'Style','edit',...
                'Enable','off',...
                'FontSize',9,...
                'Units','normalized',...
                'Position',fieldbox(1),...
                'Callback', {@obj.fieldCallback,'equil_pot',[-100 300]});
            
            maxcond_label = uicontrol(formtab2,'Style','text',...
                'String','Max Conductance (uS): ',...
                'HorizontalAlignment','right',...
                'FontSize',9,...
                'Enable','off',...
                'Units','normalized',...
                'Position',labelbox(2));
            
            maxcond_field = uicontrol(formtab2,'Style','edit',...
                'Enable','off',...
                'FontSize',9,...
                'Units','normalized',...
                'Position',fieldbox(2),...
                'Callback', {@obj.fieldCallback,'max_syn_cond',[0 100]});
            
            %%% Neuron Fields
            obj.graphic_objects.FormObjs{2}(1,1) = namelabel;
                obj.graphic_objects.FormObjs{2}(1,2) = namefield;
            obj.graphic_objects.FormObjs{2}(2,1) = restlabel;
                obj.graphic_objects.FormObjs{2}(2,2) = restfield;
            obj.graphic_objects.FormObjs{2}(3,1) = tclabel;
                obj.graphic_objects.FormObjs{2}(3,2) = tcfield;
            obj.graphic_objects.FormObjs{2}(4,1) = initthresh_label;
                obj.graphic_objects.FormObjs{2}(4,2) = initthresh_field;
            %%% Link Fields
            obj.graphic_objects.FormObjs{3}(1,1) = eqpotlabel;
                obj.graphic_objects.FormObjs{3}(1,2) = eqpotfield;
            obj.graphic_objects.FormObjs{3}(2,1) = maxcond_label;
                obj.graphic_objects.FormObjs{3}(2,2) = maxcond_field;
        end
        %% fieldCallback : activates when the user enters new data into the form
        function fieldCallback(obj, namefield, ~,field,bounds)
            if ~strcmp(field,'axislimits')
                type = namefield.UserData{1};
                index = namefield.UserData{2};
                
                %what's the model tag and what's the form number
                switch type
                    case'n'
                        node_type = 'neuron_objects';
                        formnum = 2;
                    case'l'
                        % for links, not changing link properties, changing synapse properties
                        node_type = 'synapse_types';
                        formnum = 3;
                        index = find(contains({obj.model.synapse_types.name},obj.model.link_objects(index).synaptictype));
                    case 'stim'
                        node_type = 'neuron_objects';
                        formnum = 4;
                end
                
                % to automate, need to know which field we're editing
                formchunks = size([obj.graphic_objects.FormObjs{formnum}.Position],2)/4;
                formpositions = reshape([obj.graphic_objects.FormObjs{formnum}.Position],[4 formchunks])';
                [~,formrow] = max(sum(ismember(formpositions,namefield.Position),2));
                formrow = formrow - formchunks/2;
                
                switch namefield.Style
                    case 'radiobutton'
                        obj.graphic_objects.FormObjs{1,4}(formrow,2).Value = namefield.Value;
                        obj.model.neuron_objects(index).stimulus.enabled = namefield.Value;
                    case 'edit'
                        % load the field content into the input variable. different method needed for character of numbers
                        if ~isnan(str2double(get(namefield,'String')))
                            input = str2double(get(namefield,'String'));
                        else
                            input = get(namefield,'String');
                        end
                        
                        if strcmp(type,'stim')
                            %STIMULUS FORM ENTRIES
                            %to follow the structure access rules, there needs to be a special case
                            %for stimuli that appends '.stimulus.(field)'
                            %All the same input checking rules apply as described below
                            if ~strcmp(class(input),class(obj.model.(node_type)(index).stimulus.(field)))
                                obj.graphic_objects.FormObjs{formnum}(formrow,2).String = obj.model.(node_type)(index).stimulus.(field);
                                warning('Dissimilar variable types. Value not saved.')
                                return
                            else
                                if ischar(input)
                                    obj.model.(node_type)(index).stimulus.(field) = input;
                                else
                                    switch field
                                        case 'starttime'
                                            t2 = obj.model.(node_type)(index).stimulus.endtime;
                                            bounds = [0 t2];
                                        case'endtime'
                                            t1 = obj.model.(node_type)(index).stimulus.starttime;
                                            bounds = [t1 10];
                                        case 'amplitude'
                                            bounds = [0 15];
                                    end
                                    if input < bounds(1) || input > bounds(2) 
                                        obj.graphic_objects.FormObjs{formnum}(formrow,2).String = obj.model.(node_type)(index).stimulus.(field);
                                        fprintf('Stimulus parameter %s (%.0f) is out of bounds [%.0f, %.0f]. Value not saved.\n',field,input,bounds(1),bounds(2))
                                    else
                                        obj.model.(node_type)(index).stimulus.(field) = input;
                                    end 
                                end
                            end
                            obj.model.updateStimModel(index)
                            obj.updateStimPlot(obj.model.(node_type)(index));
                        else
                            %NEURON OR LINK ENTRIES
                            % if the value that was entered is not the same type as that which is already in the document, don't accept it
                            % stops user from entering strings where numbers should be and vice versa
                            if ~strcmp(class(input),class(obj.model.(node_type)(index).(field)))
                                obj.graphic_objects.FormObjs{formnum}(formrow,2).String = obj.model.(node_type)(index).(field);
                                warning('Dissimilar variable types. Value not saved.')
                                return
                            else
                                if ischar(input)
                                    % if it gets to this point, then the user has entered a string where a string should be. just accept it.
                                    obj.model.(node_type)(index).(field) = input;
                                else
                                    % need to take an extra step and check bounds before deciding to accept values
                                    % if the entered value is out of bounds, let the user know and then reload the current value from the model
                                    if input < bounds(1) || input > bounds(2)
                                        obj.graphic_objects.FormObjs{formnum}(formrow,2).String = obj.model.(node_type)(index).(field);
                                        fprintf('%s out of bounds (%.0f, %.0f). Value not saved.\n',field,bounds(1),bounds(2))
                                    else
                                        obj.model.(node_type)(index).(field) = input;
                                    end 
                                end
                            end
                            obj.model.updateStimModel(index)
                            obj.updateStimPlot(obj.model.(node_type)(index));
                        end
                end
            else
                input = get(namefield,'String');
                if isempty(input)
                    xlimit = CanvasConstants.CANVAS_LIMITS(1);
                    ylimit = CanvasConstants.CANVAS_LIMITS(2);
                else
                    if contains(input,',')
                        if sum(input==',') > 1
                            xlimit = CanvasConstants.CANVAS_LIMITS(1);
                            ylimit = CanvasConstants.CANVAS_LIMITS(2);
                        else
                            firstinput = input(1:find(input==',')-1);
                            secondinput = input(find(input==',')+1:end);
                            if isnan(str2double(firstinput)) || isnan(str2double(secondinput))
                                xlimit = CanvasConstants.CANVAS_LIMITS(1);
                                ylimit = CanvasConstants.CANVAS_LIMITS(2);
                            else
                                xlimit = str2double(strtrim(firstinput));
                                ylimit = str2double(strtrim(secondinput));
                            end
                        end
                    elseif isnan(str2double(input))
                        xlimit = CanvasConstants.CANVAS_LIMITS(1);
                        ylimit = CanvasConstants.CANVAS_LIMITS(2);
                    else
                        input = str2double(strtrim(input));
    
                        if input > 10
                            input = 10;
                        elseif input <= 0
                            input = 1;
                        end

                        xlimit = CanvasConstants.CANVAS_LIMITS(1)*input;
                        ylimit = CanvasConstants.CANVAS_LIMITS(2)*input;
                    end
                end

                obj.graphic_objects.axes.XLim = [0,xlimit];
                obj.graphic_objects.axes.YLim = [0,ylimit];
                
                % It is important to resize the underlying image because it is associated with the figure's context menu (right click menu)
                % If you don't resize the image, the right-clickable area will remain the original dimensions.
                imagedim = size(obj.graphic_objects.image.CData);
                obj.graphic_objects.image.XData = linspace(0,xlimit, imagedim(1));
                obj.graphic_objects.image.YData = linspace(0,ylimit, imagedim(2));
                
                obj.notify('canvasSizeChanged');
            end
            
        end
        %% setupStimAxes
        function setupStimAxes(obj)
            stimpanel = obj.Parent.Children(contains({obj.Parent.Children.Title},'Stimulus Panel'));
            stimtab = stimpanel.Children.Children(1);
            memtab = stimpanel.Children.Children(2);
            % setup axes limits
            dt = obj.model.dtsim;
            stimendtime = obj.model.tmax;
            maxtime = obj.model.tmax;
            for i=1:2
                switch i
                    case 1
                        tabb = stimtab;
                        struct_inf = 'axes_stim';
                        im_inf = 'image_stim';
                    case 2
                        tabb = memtab;
                        struct_inf = 'axes_totmem';
                        im_inf = 'image_totmem';
                end
                
                ax = axes(...
                    'Box','on',...
                    'SelectionHighlight', 'off',...
                    'DeleteFcn', @(~,~) delete(obj),...
                    'HandleVisibility', 'off', ...
                    'Parent',tabb,...
                    'Position',[.03 .1 .7 .8],...
                    'XLim',[0 stimendtime/dt+1],...
                    'XTickLabel',cellstr(string(linspace(0,maxtime,maxtime+1))'),...
                    'YLim',[-.1 15]);
                %'XTick',linspace(0,maxtime,1/dt),...
                ax.Layer = 'top';
                grid(ax);
                obj.graphic_objects.(struct_inf) = ax;
                hold(obj.graphic_objects.(struct_inf),'on');

                % setup background image
                if exist(CanvasConstants.BACKGROUND_IMAGE,'file') % check if exists
                    im=imread(CanvasConstants.BACKGROUND_IMAGE); % read image
                    obj.graphic_objects.(im_inf) = image(...
                        'XData',...
                        linspace(0,ax.XLim(2), size(im,1)),...
                        'YData',...
                        linspace(0,ax.YLim(2), size(im,2)),...
                        'CData',im,'Parent',obj.graphic_objects.(struct_inf));
                end
            end
   
        end
        %% setupAxesandImage : setup the axes and the background
        function setupAxesAndImage(obj, varargin)
            if ~isempty(varargin{2}.Children)
                varargin{2} = varargin{2}.Children(2);
            end
            
            % setup axes limits
            obj.graphic_objects.axes = axes(...
                'Box','on',...
                'SelectionHighlight', 'off',...
                'YDir', 'reverse',...
                'DeleteFcn', @(~,~) delete(obj),...
                'HandleVisibility', 'off', ...
                varargin{:});
            
            % setup background images
            if exist(CanvasConstants.BACKGROUND_IMAGE,'file') % check if exists
                im=imread(CanvasConstants.BACKGROUND_IMAGE); % read image
                obj.graphic_objects.image = image(...
                    'XData',...
                    linspace(0,CanvasConstants.CANVAS_LIMITS(1), size(im,1)),...
                    'YData',...
                    linspace(0,CanvasConstants.CANVAS_LIMITS(2), size(im,2)),...
                    'CData',im,'Parent',obj.graphic_objects.axes);
                % initialize Image property and displays it
            end
%             obj.graphic_objects.axes.Layer = 'bottom';
            obj.graphic_objects.axes.Layer = 'top';
            axis(obj.graphic_objects.axes,...
            [0 CanvasConstants.CANVAS_LIMITS(1) 0 ...
            CanvasConstants.CANVAS_LIMITS(2)]);
%             obj.graphic_objects.axes.XTickLabel = [];
%             obj.graphic_objects.axes.YTickLabel = [];
            % zoom on arena
            xlen = get(obj.graphic_objects.axes,'XLim');
            ylen = get(obj.graphic_objects.axes,'YLim');
            lens = [max(xlen) max(ylen)];
            lens = lens/norm(lens);
            pbaspect(obj.graphic_objects.axes,[lens,1])
            %axis(obj.graphic_objects.axes,'square'); % square axis
            grid(obj.graphic_objects.axes); % grid
        end
        %% addItem
        function addItem(obj, type, index)
            
            if type == 'n'
                col = [0 0 0.8];
                curvature = 1;
                sz = CanvasConstants.NEURON_size;
                position = obj.model.neurons_positions(index,:) - sz/2;

                h = rectangle('Position', [position sz],...
                'Curvature', curvature,...
                'FaceColor', col,...
                'Tag', 'n',...
                'Parent', obj.graphic_objects.axes);
                uistack(h, 'top');

                obj.graphic_objects.Neurons(index) = h;
            end

            if strcmp(type,'stimulus')
                neuron = obj.model.neuron_objects(index);
                obj.updateStimPlot(neuron);
            end
            
            if ~strcmp(type,'stimulus')
                obj.notify('graphicItemCreated', CanvasModelEventData(type,index));
            else
                obj.formSelection('n',index)
                %obj.enableForm('stim');
            end
            
        end
        %% addLink
        function addLink(obj,linktype,indexvect,pos)
            if ~isnumeric(pos)
                keyboard
            end
            coords = reshape(pos,[2 2])';
            h = line(coords(:,1),coords(:,2),...
                'LineWidth',2,...
                'Parent',obj.graphic_objects.axes,...
                'Tag',['link',num2str(indexvect(2)),'-ID']);

            drawArrow = @(x,y) quiver(obj.graphic_objects.axes, x(1),y(1),x(2)-x(1),y(2)-y(1),0,'MaxHeadSize',3,'LineWidth',2) ; 
            arrowcoords = [coords(1,:);(sum(coords)./2)];
            hold(obj.graphic_objects.axes,'on')
            h2 = drawArrow(arrowcoords(:,1),arrowcoords(:,2));
            
            transnames = {'transmission','trans','hyperpolarizing'};
            modnames = {'modulation','mod','depolarizing'};
            
            if contains(lower(linktype),modnames)
                h.Color = [1 0 0];
                h2.Color = [1 0 0];
            elseif contains(lower(linktype),transnames)
                h.Color = [0 1 0];
                h2.Color = [0 1 0];
            else
                h.Color = [1 1 1];
                h2.Color = [1 1 1];
            end
            obj.graphic_objects.Links(indexvect(1)) = h;
            obj.graphic_objects.LinkArrows(indexvect(1)) = h2;
            obj.graphic_objects.LinkArrows(indexvect(1)).UserData = h.Tag;
            obj.graphic_objects.LinkArrows(indexvect(1)).Tag = h.Tag;
            
            uistack([h h2], 'down',2);
            
            if ~isgraphics(obj.graphic_objects.Links(indexvect(1)))
                keyboard
            end      
        end
        %% moveItem
        function moveItem(obj, type, index)
            
            if type == 'n'
                neur_center = obj.model.neurons_positions(index,:);
                position = neur_center - ...
                    CanvasConstants.NEURON_size/2;
                obj.graphic_objects.Neurons(index).Position(1:2) = position;
                if ~isempty(obj.model.neuron_objects(index).inlinks) || ~isempty(obj.model.neuron_objects(index).outlinks)
%                     numInlinks = size(obj.model.neuron_objects(index).inlinks,1);
%                     numOutlinks = size(obj.model.neuron_objects(index).outlinks,1);
                    linkTags = {};
                    for i = 1:length(obj.graphic_objects.Links)
                        try obj.graphic_objects.Links(i).Tag;
                            tag = obj.graphic_objects.Links(i).Tag;
                        catch
                            tag = 'xx';
                        end
                        linkTags = [linkTags,tag];
                    end
                    
                    if isempty(obj.model.neuron_objects(index).inlinks)
                        numInlinks = 0;
                    else
                        numInlinks = size(obj.model.neuron_objects(index).inlink_IDs,1);
                    end
                    
                    if isempty(obj.model.neuron_objects(index).outlinks)
                        numOutlinks = 0;
                    else
                        numOutlinks = size(obj.model.neuron_objects(index).outlink_IDs,1);
                    end
                    for i = 1:numInlinks
                        if size(obj.model.neuron_objects(index).inlink_IDs,1) == 1
                            linkID = obj.model.neuron_objects(index).inlink_IDs;
                        else
                            linkID = obj.model.neuron_objects(index).inlink_IDs{i};
                        end
                        linkInd = find(strcmp(linkTags, linkID)==1);
                        obj.graphic_objects.Links(linkInd).XData(2) = neur_center(1);
                        obj.graphic_objects.Links(linkInd).YData(2) = neur_center(2);
                        arrowroot = [obj.graphic_objects.LinkArrows(linkInd).XData obj.graphic_objects.LinkArrows(linkInd).YData]; 
                        newmid = (neur_center+arrowroot)./2;
                        delta = newmid-arrowroot;
                        obj.graphic_objects.LinkArrows(linkInd).UData = delta(1);
                        obj.graphic_objects.LinkArrows(linkInd).VData = delta(2);
                    end
                    for j = 1:numOutlinks
                        if size(obj.model.neuron_objects(index).outlink_IDs,1) == 1
                            linkID = obj.model.neuron_objects(index).outlink_IDs;
                        else
                            linkID = obj.model.neuron_objects(index).outlink_IDs{j};
                        end
                        linkInd = find(strcmp(linkTags, linkID)==1);
                        obj.graphic_objects.Links(linkInd).XData(1) = neur_center(1);
                        obj.graphic_objects.Links(linkInd).YData(1) = neur_center(2);
                        arrowdest = [obj.graphic_objects.Links(linkInd).XData(2) obj.graphic_objects.Links(linkInd).YData(2)]; 
                        newmid = (neur_center+arrowdest)./2;
                        delta = arrowdest-newmid;
                        obj.graphic_objects.LinkArrows(linkInd).UData = delta(1);
                        obj.graphic_objects.LinkArrows(linkInd).VData = delta(2);
                        obj.graphic_objects.LinkArrows(linkInd).XData = neur_center(1);
                        obj.graphic_objects.LinkArrows(linkInd).YData = neur_center(2);
                    end
                end
            end
            
        end
        %% deleteItem
        function deleteItem(obj, type, index)
            objectname = [];
     
            switch type
                case 'n'
                    objectname = 'Neurons';
                    objLoc = obj.model.neuron_objects(index).location;
                    currentobjs = {obj.graphic_objects.(objectname).Position};
                    numNeurs = size(currentobjs,2);
                    viewNeurPos = reshape(cell2mat(currentobjs),[4 numNeurs])';
                    viewNeurPos = viewNeurPos(:,1:2);
%                     currentInd = find(~all(viewNeurPos - objLoc + CanvasConstants.NEURON_size/2,2));
                    [~,currentInd] = min(sum(abs(viewNeurPos - objLoc + CanvasConstants.NEURON_size/2),2));
                        if ~isempty(obj.model.neuron_objects(index).stimulus)
                            obj.updateStimPlot('clear');
                        end
                case 'l'
                    objectname = 'Links';
                    objID = obj.model.link_objects(index).ID;
                    excluder = true(1,size(obj.graphic_objects.(objectname),2));
                    try {obj.graphic_objects.(objectname)(excluder).Tag};
                    catch
                        for i = 1:size(obj.graphic_objects.(objectname),2)
                            if ~isgraphics(obj.graphic_objects.Links(i))
                                excluder(i) = 0;
                            end
                        end
                    end
                    currentobjs = {obj.graphic_objects.(objectname)(excluder).Tag};
                    currentInd = find(strcmp(objID, currentobjs)==1);
            end
            
            if index ~= currentInd
                fprintf('The view neuron index is not equal to the model neuron index\n')
                keyboard
            end
            
            if strcmp(objectname,'Links')
                delete(obj.graphic_objects.LinkArrows(currentInd));
                if isempty(obj.graphic_objects.LinkArrows)
                    obj.graphic_objects.LinkArrows = [];
                else
                    obj.graphic_objects.LinkArrows(currentInd) = [];
                end
            end
            
            delete(obj.graphic_objects.(objectname)(currentInd));
            if isempty(obj.graphic_objects.(objectname))
                obj.graphic_objects.(objectname) = [];
            else
                obj.graphic_objects.(objectname)(currentInd) = [];
            end
            
        end
        %% modelChanged
        function modelChanged(obj)
            
            for k=1:length(obj.graphic_objects.Neurons)
                obj.deleteItem('n', k);
            end
            
%             for k=1:length(obj.graphic_objects.Links)
%                 obj.deleteItem('l', k);
%             end
%             
            for k=1:obj.model.num_neurons
                obj.addItem('n', k);
            end
            
            for k=1:obj.model.num_obstacles
                obj.addItem('o', k);
            end
            
        end       
        %% updateStimPlot
        function updateStimPlot(obj,neuron)
            if ischar(neuron) && strcmp(neuron,'clear')
                cla(obj.graphic_objects.axes_stim)
                cla(obj.graphic_objects.axes_totmem)
            else
                if ~isempty(neuron.stimulus)
                    stim = neuron.stimulus;
                    stim_wave = stim.waveform;
                    totmem_wave = neuron.totmem;
                    %Update stimulus plot axes
                    cla(obj.graphic_objects.axes_stim)
                    plot(obj.graphic_objects.axes_stim,stim_wave,'LineWidth',2)

                    %Update total membrane response plot axes
                    cla(obj.graphic_objects.axes_totmem)
                    plot(obj.graphic_objects.axes_totmem,totmem_wave,'LineWidth',2)
                else
                    if ~isempty(neuron.totmem)
                        totmem_wave = neuron.totmem;
                        %Update total membrane response plot axes
                        cla(obj.graphic_objects.axes_totmem)
                        plot(obj.graphic_objects.axes_totmem,totmem_wave,'LineWidth',2)
                    else
                        cla(obj.graphic_objects.axes_stim)
                        cla(obj.graphic_objects.axes_totmem)
                    end
                end
            end
%             if strcmp(neuron,'clear')
%                 cla(obj.graphic_objects.axes_stim)
% %             elseif strcmp(stim,'onlytotmem')
% %                 totmem_wave = obj.model.neuron_objects(contains({obj.model.neuron_objects.name},stim.name(1:end-5))).totmem;
% %                 cla(obj.graphic_objects.axes_totmem)
% %                 plot(obj.graphic_objects.axes_totmem,totmem_wave,'LineWidth',2)
%             else
%                 stim_wave = obj.model.neuron_objects(contains({obj.model.neuron_objects.name},stim.name(1:end-5))).stimulus.waveform;
%                 %Update stimulus plot axes
%                 cla(obj.graphic_objects.axes_stim)
%                 plot(obj.graphic_objects.axes_stim,stim_wave,'LineWidth',2)
%                 
%                 oNeur = obj.model.neuron_objects(contains({obj.model.neuron_objects.name},stim.name(1:end-5)));
%                 totmem_wave = oNeur.totmem;
%                 
%                 %Update total membrane response plot axes
%                 cla(obj.graphic_objects.axes_totmem)
%                 plot(obj.graphic_objects.axes_totmem,totmem_wave,'LineWidth',2)
% 
%             end
        end
    end
    
end