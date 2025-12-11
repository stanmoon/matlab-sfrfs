classdef SFRFsLogger < handle
% SFRFsLogger - Singleton logger supporting parallel workers
%
% Provides a per-process singleton logger instance writing to unique files
% named by worker ID (0 for main MATLAB, >0 for parallel workers).
% Supports all standard java.util.logging levels.
%
% Usage:
%   logger = SFRFsLogger.getLogger();
%   logger.info('A relevant bit of information');
%   logger.warning('A warning message');
%   logger.severe('A message signaling a severe condition');
%   logger.finer('An informative message for debugging');
%   logger.finest('A very detailed message');
%   logger.config('A relevant remark on configuration');
%
% Log files:
%   Files named 'SFRFsLogger_worker<ID>.log' saved in the configured log 
%   folder.


    properties
        logFolder    % Log files directory
        pattern      % Log filename pattern with placeholders
        limit        % Max file size in bytes before rotation
        count        % Number of rotated log files kept
        append       % Whether to append to existing log files
        level        % Log level filter (e.g., 'ALL', 'INFO')
        formatter    % Java class for log message formatting
    end


    properties (Constant)
        % Base prefix for all properties
        LOGGER_BASE_NAME = 'SFRFsLogger';

        % FileHandler related properties
        FILE_HANDLER_PATTERN   = 'SFRFsLogger.FileHandler.pattern';
        FILE_HANDLER_LIMIT     = 'SFRFsLogger.FileHandler.limit';
        FILE_HANDLER_COUNT     = 'SFRFsLogger.FileHandler.count';
        FILE_HANDLER_APPEND    = 'SFRFsLogger.FileHandler.append';
        FILE_HANDLER_LEVEL     = 'SFRFsLogger.FileHandler.level';
        FILE_HANDLER_FORMATTER = 'SFRFsLogger.FileHandler.formatter';

        % Optional log folder path property
        LOG_FOLDER            = 'SFRFsLogger.logFolder';
    end

    properties (Constant, Access = private)
        DEFAULT_PATTERN = SFRFsLogger.getDefaultPattern();
        DEFAULT_LIMIT = '1000000';   
        DEFAULT_COUNT = '3';        
        DEFAULT_APPEND = 'true';      
        DEFAULT_LEVEL = 'ALL';
        DEFAULT_FORMATTER = 'java.util.logging.SimpleFormatter';

        % Define level name strings
        LEVEL_ALL     = 'ALL';
        LEVEL_SEVERE  = 'SEVERE';
        LEVEL_WARNING = 'WARNING';
        LEVEL_INFO    = 'INFO';
        LEVEL_CONFIG  = 'CONFIG';
        LEVEL_FINE    = 'FINE';
        LEVEL_FINER   = 'FINER';
        LEVEL_FINEST  = 'FINEST';
        LEVEL_OFF     = 'OFF';

        LEVEL_MAP = SFRFsLogger.initLevelMap();
    end

    properties (Access = private)
        Logger
        debugEnabled = false; % default disabled
    end

    methods (Access = private, Static)
        function map = initLevelMap()
            import java.util.logging.Level
                
            map = containers.Map( ...
            { ...
                SFRFsLogger.LEVEL_ALL, ...
                SFRFsLogger.LEVEL_SEVERE, ...
                SFRFsLogger.LEVEL_WARNING, ...
                SFRFsLogger.LEVEL_INFO, ...
                SFRFsLogger.LEVEL_CONFIG, ...
                SFRFsLogger.LEVEL_FINE, ...
                SFRFsLogger.LEVEL_FINER, ...
                SFRFsLogger.LEVEL_FINEST, ...
                SFRFsLogger.LEVEL_OFF}, ...
            { ...
                Level.ALL, ...
                Level.SEVERE, ...
                Level.WARNING, ...
                Level.INFO, ...
                Level.CONFIG, ...
                Level.FINE, ...
                Level.FINER, ...
                Level.FINEST, ...
                Level.OFF}); 
        end

        function singleObj = getInstanceInternal()
            % Get or create the singleton logger instance for this process
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = SFRFsLogger();
            end
            singleObj = localObj;
        end
    end

    methods (Static)
        function obj = getLogger()
            % Return the singleton logger instance for the current MATLAB 
            % process/worker
            obj = SFRFsLogger.getInstanceInternal();
        end
    end

    methods (Access = private)

        function obj = SFRFsLogger()
            import java.util.logging.FileHandler
            import java.util.logging.Logger
            import java.util.logging.Level
            import java.util.logging.LogManager
            import java.util.logging.SimpleFormatter
            import java.io.FileInputStream

        
            % Load logging properties file
            propertiesFile = SFRFsLogger.getPropertiesFilePath();
            fis = FileInputStream(propertiesFile);
            cleanupObj = onCleanup(@() fis.close());
            try
                LogManager.getLogManager().readConfiguration(fis);
            catch ME
                warning(ME.identifier, '%s', ME.message);
            end

        
            % Read log folder from properties or default to prefdir location
            logFolder = SFRFsLogger.getPropertyOrDefault( ...
                SFRFsLogger.LOG_FOLDER, ...
                fullfile(prefdir, 'sfrfs', 'logs'));

            % Ensure log folder exists
            if ~exist(logFolder, 'dir')
                mkdir(logFolder);
            end
            obj.logFolder = logFolder;
        
            % Get worker ID and build logger name
            wid = SFRFsLogger.getWorkerID();
            loggerName = ...
                sprintf('%s_worker%d', SFRFsLogger.LOGGER_BASE_NAME, wid);
            obj.Logger = Logger.getLogger(loggerName);
            obj.Logger.setUseParentHandlers(false);
        
            % Clear existing handlers to avoid duplicates
            handlers = obj.Logger.getHandlers();
            for k = 1:length(handlers)
                obj.Logger.removeHandler(handlers(k));
            end
        
            % Add FileHandler if none exist
            handlers = obj.Logger.getHandlers();
            if isempty(handlers)
                % Read FileHandler properties dynamically
                pattern = SFRFsLogger.getPropertyOrDefault( ...
                    SFRFsLogger.FILE_HANDLER_PATTERN, ...
                    SFRFsLogger.DEFAULT_PATTERN);
                obj.pattern = pattern;
                limitStr = SFRFsLogger.getPropertyOrDefault( ...
                    SFRFsLogger.FILE_HANDLER_LIMIT, ...
                    SFRFsLogger.DEFAULT_LIMIT);
                obj.limit = limitStr;
                countStr = SFRFsLogger.getPropertyOrDefault( ...
                    SFRFsLogger.FILE_HANDLER_COUNT, ...
                    SFRFsLogger.DEFAULT_COUNT);
                obj.count = countStr;
                appendStr = SFRFsLogger.getPropertyOrDefault( ...
                    SFRFsLogger.FILE_HANDLER_APPEND,...
                    SFRFsLogger.DEFAULT_APPEND);
                obj.append = appendStr;
                levelStr = SFRFsLogger.getPropertyOrDefault( ...
                    SFRFsLogger.FILE_HANDLER_LEVEL, ...
                    SFRFsLogger.FILE_HANDLER_LEVEL);
                obj.level = levelStr;
                formatterClass = SFRFsLogger.getPropertyOrDefault( ...
                    SFRFsLogger.FILE_HANDLER_FORMATTER, ...
                    SFRFsLogger.FILE_HANDLER_FORMATTER);
                obj.formatter = formatterClass;
        
                % Expand ~ if present in logFolder
                if startsWith(logFolder, '~')
                    homeDir = getenv('HOME');
                    if isempty(homeDir)
                        % maybe works in Win systems?
                        homeDir = getenv('USERPROFILE');
                    end
                    logFolder = fullfile(homeDir, logFolder(2:end));
                end
        
                % Create full log filename with worker id replacing %u
                logFileName = fullfile(logFolder, sprintf(pattern, wid));
        
                % Parse numeric and boolean parameters
                limit = str2double(limitStr);
                count = str2double(countStr);
                append = strcmpi(appendStr, 'true');
        
                % Create FileHandler with rotation settings
                fileHandler = ...
                    FileHandler( logFileName, limit, count, append); %#ok<UNRCH>
        
                % Take care of format, this does not work,
                % property must be set before starting MATLAB
                java.lang.System.setProperty(...
                    'java.util.logging.SimpleFormatter.format', ...
                    '%1$tF %1$tT %4$s %3$s [%2$s] %5$s%6$s%n');
                
                % Instantiate formatter
                fileHandler.setFormatter(...
                    SFRFsLogger.createFormatter(formatterClass));

        
                % Set log levels
                levelVal = SFRFsLogger.getJavaLogLevel(levelStr);
                fileHandler.setLevel(levelVal);
                obj.Logger.setLevel(levelVal);
        
                % Add FileHandler to logger
                obj.Logger.addHandler(fileHandler)
            end
        end

        function fullMsg = formatLogMessage(obj, varargin)
            msgParts = cellfun(@(x) SFRFsLogger.convertToString(x), ...
                varargin, 'UniformOutput', false);
            msgParts = cellfun(@char, msgParts, 'UniformOutput', false);
            msg = strjoin(msgParts, ' ');

            if obj.isDebugEnabled()
                metaInfo = SFRFsLogger.getMetaInfo();
            else
                metaInfo = '';
            end

            fullMsg = [metaInfo msg];
        end

        function log(obj, levelStr, msg)
            % Log a message with a specified level string
            % Supported levels: ALL, SEVERE, WARNING, INFO, CONFIG, FINE,
            %                   FINER, FINEST, OFF
            upperLevel = upper(levelStr);
            if ~isKey(SFRFsLogger.LEVEL_MAP, upperLevel)
                error('sfrfs:SFRFsLogger:UnknownLogLevel', ...
                    'Unknown log level: %s', levelStr);
            end
            obj.Logger.log(obj.LEVEL_MAP(upperLevel), msg);
        end
    end

    methods (Static, Access = private)

        function value = getPropertyOrDefault(propKey, defaultVal)
            value = SFRFsLogger.getPropertyFromLogManager(propKey);
            if isempty(value)
                value = defaultVal;
            end
        end

        function pattern = getDefaultPattern()
                pattern = [SFRFsLogger.LOGGER_BASE_NAME '_worker%u.log'];
        end

        function formatterObj = createFormatter(formatterClassName)
            
            % Allow only known safe formatter classes
            validFormatters = containers.Map( ...
                {'java.util.logging.SimpleFormatter', ...
                 'java.util.logging.XMLFormatter'}, ...
                {@java.util.logging.SimpleFormatter, ...
                @java.util.logging.XMLFormatter});

            if isKey(validFormatters, formatterClassName)
                % Instantiate using function handle stored in the map
                formatterConstructor = validFormatters(formatterClassName);
                formatterObj = formatterConstructor();
            else
                warning(['Unknown formatter class %s, '...
                    'defaulting to SimpleFormatter.'], formatterClassName);
                formatterObj = java.util.logging.SimpleFormatter();
            end
        end

        function wid = getWorkerID()
            % Get a unique worker ID or zero for the main MATLAB process
            wid = 0;
            try
                t = getCurrentTask();
                if ~isempty(t)
                    wid = t.ID;
                end
            catch
                % Not in parallel, wid stays 0
            end
        end

        function propertiesFile = getPropertiesFilePath()
            % Locate logging.properties file in toolbox resources folder
            classFilePath = mfilename('fullpath');
            toolboxRoot = fileparts(classFilePath);
            propertiesFile = fullfile(...
                toolboxRoot, 'resources', 'logging.properties');
            if ~exist(propertiesFile, 'file')
                error('Properties file not found: %s', propertiesFile);
            end
        end

        function propValue = getPropertyFromLogManager(propName)
            import java.util.logging.LogManager;
            lm = LogManager.getLogManager();
            rawValue = lm.getProperty(propName);
        
            if isempty(rawValue)
                propValue = '';
            else
                propValue = char(rawValue);
            end
        end
    end

    
    methods
        function enableDebug(obj)
            obj.debugEnabled = true;
        end

        function disableDebug(obj)
            obj.debugEnabled = false; 
        end

        function tf = isDebugEnabled(obj)
            tf = obj.debugEnabled;
        end

        function info(obj, varargin)
            fullMsg = obj.formatLogMessage(varargin{:});
            obj.Logger.info(fullMsg);
        end

        function warning(obj, varargin)
            fullMsg = obj.formatLogMessage(varargin{:});
            obj.Logger.warning(fullMsg);
        end

        function severe(obj, varargin)
            fullMsg = obj.formatLogMessage(varargin{:});
            obj.Logger.severe(fullMsg);
        end

        function fine(obj, varargin)
            fullMsg = obj.formatLogMessage(varargin{:});
            obj.Logger.fine(fullMsg);
        end

        function finest(obj, varargin)
            fullMsg = obj.formatLogMessage(varargin{:});
            obj.Logger.finest(fullMsg);
        end

        function finer(obj, varargin)
            fullMsg = obj.formatLogMessage(varargin{:});
            obj.Logger.finer(fullMsg);
        end

        function all(obj, varargin)
            import java.util.logging.Level;
            fullMsg = obj.formatLogMessage(varargin{:});
            obj.Logger.log(Level.ALL, fullMsg);
        end

        function config(obj, varargin)
            fullMsg = obj.formatLogMessage(varargin{:});
            obj.Logger.config(fullMsg);
        end

        function tf = isAllEnabled(obj)
            tf = obj.Logger.isLoggable( ...
                SFRFsLogger.LEVEL_MAP(SFRFsLogger.LEVEL_ALL));
        end
        function tf = isSevereEnabled(obj)
            tf = obj.Logger.isLoggable( ...
                SFRFsLogger.LEVEL_MAP(SFRFsLogger.LEVEL_SEVERE));
        end
        function tf = isWarningEnabled(obj)
            tf = obj.Logger.isLoggable( ...
                SFRFsLogger.LEVEL_MAP(SFRFsLogger.LEVEL_WARNING));
        end
        function tf = isInfoEnabled(obj)
            tf = obj.Logger.isLoggable( ...
                SFRFsLogger.LEVEL_MAP(SFRFsLogger.LEVEL_INFO));
        end
        function tf = isConfigEnabled(obj)
            tf = obj.Logger.isLoggable( ...
                SFRFsLogger.LEVEL_MAP(SFRFsLogger.LEVEL_CONFIG));
        end
        function tf = isFineEnabled(obj)
            tf = obj.Logger.isLoggable( ...
                SFRFsLogger.LEVEL_MAP(SFRFsLogger.LEVEL_FINE));
        end
        function tf = isFinerEnabled(obj)
            tf = obj.Logger.isLoggable( ...
                SFRFsLogger.LEVEL_MAP(SFRFsLogger.LEVEL_FINER));
        end
        function tf = isFinestEnabled(obj)
            tf = obj.Logger.isLoggable( ...
                SFRFsLogger.LEVEL_MAP(SFRFsLogger.LEVEL_FINEST));
        end
        function tf = isLoggingOff(obj)
            tf = obj.Logger.isLoggable( ...
                SFRFsLogger.LEVEL_MAP(SFRFsLogger.LEVEL_OFF));
        end
    end

    methods (Static, Access = private)
        function str = convertToString(x)
            % Convert input of any type to a string suitable for logging
   
            if ischar(x)
                str = string(x);
            elseif isstring(x)
                str = x;
            elseif isnumeric(x) || islogical(x)
                % Convert arrays to string matrix representation
                str = mat2str(x);
            elseif iscell(x)
                % For cell arrays, convert element-wise recursively
                cellStrs = cellfun(...
                    @(c) SFRFsLogger.convertToStr(c), x, ...
                    'UniformOutput', false);
                str = ['{' strjoin(cellStrs, ', ') '}'];
            elseif isobject(x) && ismethod(x, 'toString')
                % Custom object with toString method
                str = x.toString();
            else
                str = ['<' class(x) '>'];
            end
        end

        function levelVal = getJavaLogLevel(levelStr)
        % Convert a level string to corresponding java.util.logging.Level 
        
            upperLevel = upper(levelStr);
            
            if isKey(SFRFsLogger.LEVEL_MAP, upperLevel)
                levelVal = SFRFsLogger.LEVEL_MAP(upperLevel);
            else
                warning('sfrfs:SFRFsLogger:UnknownLogLevel', ...
                    'Unknown log level: %s. Defaulting to ALL.', levelStr);
                levelVal = SFRFsLogger.LEVEL_MAP(SFRFsLogger.LEVEL_ALL);
            end
        end

        function metaStr = getMetaInfo()
            % Get stack for line/file info (skip 2 frames)
            stackFileLine = dbstack(2, '-completenames');
            % Get stack for caller method name (skip 3 frames)
            stackMethod = dbstack(3, '-completenames');
        
            if isempty(stackFileLine)
                metaStr = '';
                return;
            end
        
            callerFile = stackFileLine(1);
            [~, fileName, ext] = fileparts(callerFile.file);
            fullName = [fileName, ext];
            lineNumber = callerFile.line;
        
            if isempty(stackMethod)
                methodName = ''; 
            else
                methodName = stackMethod(1).name;
            end
        
            metaStr = ...
                sprintf('[%s@%s:%d] ', methodName, fullName, lineNumber);
        end
    end
end
