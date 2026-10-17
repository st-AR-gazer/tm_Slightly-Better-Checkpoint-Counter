// oplint-disable *

enum LogLevel {
    Debug = 0,
    Info = 1,
    Notice = 2,
    Warning = 3,
    Warn = 3,
    Error = 4,
    Critical = 5,
    Custom = 6
}

namespace log {
    enum Level {
        Debug = 0,
        Info = 1,
        Notice = 2,
        Warning = 3,
        Error = 4,
        Critical = 5,
        Custom = 6
    }

    const uint kMaxEntryFields = 12;
    const uint kMaxFieldNameLength = 48;
    const uint kMaxFieldValueLength = 512;
    const uint kMaxFormattedFieldsLength = 2048;
    const string kDefaultTagColor = "\\$f80";
    const string kHandledExceptionTagColor = "\\$888";

    class Field {
        string name;
        string value;

        Field() { }
        Field(const string &in name, const string &in value) {
            this.name = name;
            this.value = value;
        }
    }

    class Entry {
        string message;
        Level severity = Level::Info;
        string context;
        int sourceLine = -1;
        string tag;
        string tagColor = kDefaultTagColor;
        array<Field> fields;

        Entry() { }
        Entry(const string &in message) {
            this.message = message;
        }
        Entry(const string &in message, Level severity) {
            this.message = message;
            this.severity = severity;
        }
        Entry(const string &in message, LogLevel severity) {
            this.message = message;
            this.severity = ToLevel(int(severity));
        }

        bool Add(const string &in name, const string &in value) {
            string normalizedName = name.Trim();
            if (normalizedName.Length == 0) return false;
            if (normalizedName.Length > kMaxFieldNameLength) {
                normalizedName = normalizedName.SubStr(0, kMaxFieldNameLength);
            }
            string normalizedValue = value;
            if (normalizedValue.Length > kMaxFieldValueLength) {
                normalizedValue = normalizedValue.SubStr(0, kMaxFieldValueLength);
            }
            for (uint i = 0; i < fields.Length; i++) {
                if (fields[i].name == normalizedName) {
                    fields[i].value = normalizedValue;
                    return true;
                }
            }
            if (fields.Length >= kMaxEntryFields) return false;
            fields.InsertLast(Field(normalizedName, normalizedValue));
            return true;
        }

        bool Add(const string &in name, const wstring &in value) {
            return Add(name, string(value));
        }
        bool Add(const string &in name, bool value) {
            return Add(name, value ? "true" : "false");
        }
        bool Add(const string &in name, int value) {
            return Add(name, tostring(value));
        }
        bool Add(const string &in name, uint value) {
            return Add(name, tostring(value));
        }
        bool Add(const string &in name, int64 value) {
            return Add(name, tostring(value));
        }
        bool Add(const string &in name, uint64 value) {
            return Add(name, tostring(value));
        }
        bool Add(const string &in name, float value) {
            return Add(name, tostring(value));
        }
        bool Add(const string &in name, double value) {
            return Add(name, tostring(value));
        }
    }

    [Setting category="Logging" name="Write daily diagnostic file" hidden]
    bool writeToFile = false;
    [Setting category="Logging" name="Write to the Openplanet log" hidden]
    bool writeToOpenplanet = true;
    [Setting category="Logging" name="Minimum Openplanet log level" min=0 max=5 hidden]
    int minimumLevel = 1;
    [Setting category="Logging" name="Show custom log entries" hidden]
    bool showCustom = false;
    [Setting category="Logging" name="Show log context" hidden]
    bool showContext = true;
    [Setting category="Logging" name="Show source line" hidden]
    bool showSourceLine = true;

    const string kLogsFolder = "Logs/";
    const string kLogPrefix = "diagnostics_";
    const uint kRetentionDays = 14;
    const int64 kSecondsPerDay = 86400;

    bool started = false;
    bool fileFailed = false;
    string fileDate;
    string filePath;
    string fileError;

    Level ToLevel(int level) {
        if (level < 0 || level > 6) return Level::Info;
        return Level(level);
    }

    int NormalizeLevel(int level) {
        return int(ToLevel(level));
    }

    string LevelName(Level level) {
        if (level == Level::Debug) return "DEBUG";
        if (level == Level::Info) return "INFO";
        if (level == Level::Notice) return "NOTICE";
        if (level == Level::Warning) return "WARNING";
        if (level == Level::Error) return "ERROR";
        if (level == Level::Critical) return "CRITICAL";
        return "CUSTOM";
    }

    string LevelName(int level) {
        return LevelName(ToLevel(level));
    }

    string LevelColor(Level level) {
        if (level == Level::Debug || level == Level::Notice) return "\\$0ff";
        if (level == Level::Info) return "\\$0f0";
        if (level == Level::Warning) return "\\$ff0";
        if (level == Level::Error || level == Level::Critical) return "\\$f00";
        return "\\$f80";
    }

    string LevelColor(int level) {
        return LevelColor(ToLevel(level));
    }

    string BodyColor(Level level) {
        if (level == Level::Debug || level == Level::Notice) return "\\$0cc";
        if (level == Level::Info) return "\\$0c0";
        if (level == Level::Warning) return "\\$cc0";
        if (level == Level::Error || level == Level::Critical) return "\\$c00";
        return "\\$f80";
    }

    string BodyColor(int level) {
        return BodyColor(ToLevel(level));
    }

    string EscapeFieldText(const string &in value) {
        return value.Replace(
            "\\",
            "\\\\"
        ).Replace("\"", "\\\"").Replace("\r", "\\r").Replace("\n", "\\n").Replace("\t", "\\t");
    }

    string FormatFields(const Entry@ entry) {
        if (entry is null) return "";
        string result = "{";
        uint written = 0;
        for (uint i = 0; i < entry.fields.Length && i < kMaxEntryFields; i++) {
            string name = entry.fields[i].name.Trim();
            if (name.Length == 0) continue;
            if (name.Length > kMaxFieldNameLength) {
                name = name.SubStr(0, kMaxFieldNameLength);
            }
            string value = entry.fields[i].value;
            if (value.Length > kMaxFieldValueLength) {
                value = value.SubStr(0, kMaxFieldValueLength);
            }
            string piece = (written > 0 ? ", " : "") +
                           "\"" +
                           EscapeFieldText(name) +
                           "\":\"" +
                           EscapeFieldText(value) +
                           "\"";
            if (result.Length + piece.Length + 1 > kMaxFormattedFieldsLength) break;
            result += piece;
            written++;
        }
        return written > 0 ? result + "}" : "";
    }

    string FormatEntryMessage(const Entry@ entry) {
        if (entry is null) return "";
        string fields = FormatFields(entry);
        if (fields.Length == 0) return entry.message;
        if (entry.message.Length == 0) return fields;
        return entry.message + " | " + fields;
    }

    string FixedLabel(const string &in value, int width = 8) {
        string label = value.ToUpper();
        if (label.Length > width) label = label.SubStr(0, width);
        while (label.Length < width) label += " ";
        return label;
    }

    string FormatLocation(const string &in context, int line, bool showContext, bool showSourceLine) {
        string location;
        if (showContext && context.Length > 0) location = context;
        if (showSourceLine && line >= 0) {
            if (location.Length > 0) location += ":";
            location += tostring(line);
        }
        return location.Length > 0 ? location + " " : "";
    }

    string Location(const string &in context, int line) {
        return FormatLocation(context, line, showContext, showSourceLine);
    }

    string FormatPlainLine(
        const string &in message,
        Level level,
        int line,
        const string &in context,
        const string &in tag,
        bool showContext,
        bool showSourceLine
    ) {
        string primary = level == Level::Custom && tag.Length > 0 ? tag.ToUpper() : LevelName(level);
        string result = "[" + primary + "] ";
        if (level != Level::Custom && tag.Length > 0) result += "[" + tag + "] ";
        return result + FormatLocation(context, line, showContext, showSourceLine) + message;
    }

    string PlainLine(const string &in message, int level, int line, const string &in context, const string &in tag) {
        return FormatPlainLine(message, ToLevel(level), line, context, tag, showContext, showSourceLine);
    }

    string FormatColoredLine(
        const string &in message,
        Level level,
        int line,
        const string &in context,
        const string &in tag,
        const string &in tagColor
    ) {
        string primary = level == Level::Custom && tag.Length > 0 ? tag : LevelName(level);
        string color = level == Level::Custom && tagColor.Length > 0 ? tagColor : LevelColor(level);
        return color +
               "[" +
               FixedLabel(primary) +
               "] \\$z\\$888" +
               FormatLocation(context, line, showContext, showSourceLine) +
               "\\$z" +
               BodyColor(level) +
               message;
    }

    string ColoredLine(
        const string &in message,
        int level,
        int line,
        const string &in context,
        const string &in tag,
        const string &in tagColor
    ) {
        return FormatColoredLine(message, ToLevel(level), line, context, tag, tagColor);
    }

    bool ShouldWriteToOpenplanet(Level level) {
        if (!writeToOpenplanet) return false;
        if (level == Level::Custom) return showCustom;
        return int(level) >= Math::Clamp(minimumLevel, 0, 5);
    }

    bool IsLevelEnabled(int level) {
        return ShouldWriteToOpenplanet(ToLevel(level));
    }
    bool IsLevelEnabled(LogLevel level) {
        return IsLevelEnabled(int(level));
    }

    void WriteToOpenplanet(const Entry@ entry, const string &in message) {
        if (entry is null) return;
        Level level = ToLevel(int(entry.severity));
        if (!ShouldWriteToOpenplanet(level)) return;

        if (level == Level::Custom) {
            print(FormatColoredLine(message, level, entry.sourceLine, entry.context, entry.tag, entry.tagColor));
            return;
        }

        string plain = FormatPlainLine(
            message,
            level,
            entry.sourceLine,
            entry.context,
            entry.tag,
            showContext,
            showSourceLine
        );
        if (level == Level::Warning) {
            warn(plain);
            return;
        }
        if (level == Level::Error || level == Level::Critical) {
            error(plain);
            return;
        }
        trace(plain);
    }

    bool IsOwnedLogName(const string &in name) {
        if (!name.StartsWith(kLogPrefix) || !name.EndsWith(".log")) return false;
        if (name.Length != kLogPrefix.Length + 14) return false;
        string date = name.SubStr(kLogPrefix.Length, 10);
        if (date.SubStr(4, 1) != "-" || date.SubStr(7, 1) != "-") return false;
        for (int i = 0; i < date.Length; i++) {
            if (i == 4 || i == 7) continue;
            if (!"0123456789".Contains(date.SubStr(i, 1))) return false;
        }
        return true;
    }

    bool RefreshFilePath() {
        string today = Time::FormatString("%Y-%m-%d");
        if (today == fileDate) return false;
        fileDate = today;
        filePath = IO::FromStorageFolder(kLogsFolder + kLogPrefix + today + ".log");
        fileFailed = false;
        fileError = "";
        return true;
    }

    void SetFilePath() {
        RefreshFilePath();
    }

    void PruneOldFiles() {
        string folder = IO::FromStorageFolder(kLogsFolder);
        if (!IO::FolderExists(folder)) return;
        int64 earliest = Time::Stamp - int64(kRetentionDays - 1) * kSecondsPerDay;
        string earliestDate = Time::FormatString("%Y-%m-%d", Math::Max(int64(0), earliest));
        array<string> @files = IO::IndexFolder(folder, false);
        for (uint i = 0; i < files.Length; i++) {
            string name = Path::GetFileName(files[i]);
            if (!IsOwnedLogName(name)) continue;
            if (name.SubStr(kLogPrefix.Length, 10) < earliestDate && IO::FileExists(files[i])) {
                IO::Delete(files[i]);
            }
        }
    }

    void FailFile(const string &in reason) {
        fileFailed = true;
        fileError = reason;
        warn("[logging] File output disabled: " + reason);
    }

    void AppendFile(const string &in line) {
        if (!writeToFile) return;
        bool dateChanged = RefreshFilePath();
        if (fileFailed) return;
        try {
            string folder = IO::FromStorageFolder(kLogsFolder);
            if (!IO::FolderExists(folder)) IO::CreateFolder(folder);
            if (dateChanged) PruneOldFiles();
            IO::File file;
            file.Open(filePath, IO::FileMode::Append);
            file.WriteLine(Time::FormatString("%Y-%m-%d %H:%M:%S") + " " + line);
            file.Close();
        } catch {
            FailFile(getExceptionInfo());
        }
    }

    void WriteToFile(const Entry@ entry, const string &in message) {
        if (entry is null) return;
        if (!writeToFile) return;
        AppendFile(FormatPlainLine(
            message,
            ToLevel(int(entry.severity)),
            entry.sourceLine,
            entry.context,
            entry.tag,
            true,
            true
        ));
    }

    void RetryFileOutput() {
        fileFailed = false;
        fileError = "";
        fileDate = "";
        RefreshFilePath();
        if (!writeToFile) return;
        try {
            string folder = IO::FromStorageFolder(kLogsFolder);
            if (!IO::FolderExists(folder)) IO::CreateFolder(folder);
            PruneOldFiles();
        } catch {
            FailFile(getExceptionInfo());
        }
    }

    void Dispatch(const Entry@ entry) {
        if (entry is null) return;
        string message = FormatEntryMessage(entry);
        WriteToFile(entry, message);
        WriteToOpenplanet(entry, message);
    }

    void Write(
        const string &in message,
        Level level = Level::Info,
        int line = -1,
        const string &in context = ""
    ) {
        Entry entry(message, ToLevel(int(level)));
        entry.sourceLine = line;
        entry.context = context;
        Dispatch(entry);
    }

    void Write(const Entry@ entry) {
        Dispatch(entry);
    }

    void Throw(Entry@ entry) {
        Entry@ actual = entry;
        if (actual is null) {
            @actual = Entry("Cannot throw a null logging entry", Level::Critical);
            actual.context = "log::Throw";
        }
        if (actual.message.Length == 0) actual.message = "Exception";
        if (actual.severity != Level::Error && actual.severity != Level::Critical) {
            actual.severity = Level::Error;
        }
        string exceptionMessage = FormatEntryMessage(actual);
        Write(actual);
        throw(exceptionMessage);
    }

    void Throw(
        const string &in message,
        const string &in context = "",
        int line = -1
    ) {
        Entry@ entry = Entry(message.Length > 0 ? message : "Exception", Level::Error);
        entry.context = context;
        entry.sourceLine = line;
        Throw(entry);
    }

    void Emit(
        const string &in message,
        int level = 1,
        int line = -1,
        const string &in context = ""
    ) {
        Write(message, ToLevel(level), line, context);
    }

    void Start() {
        if (started) return;
        started = true;
        if (writeToFile) {
            RetryFileOutput();
        } else {
            SetFilePath();
        }
    }

    void Shutdown() {
        started = false;
    }
    void Initialise() {
        Start();
    }

    void Debug(const string &in message, const string &in context = "") {
        Write(message, Level::Debug, -1, context);
    }
    void Info(const string &in message, const string &in context = "") {
        Write(message, Level::Info, -1, context);
    }
    void Notice(const string &in message, const string &in context = "") {
        Write(message, Level::Notice, -1, context);
    }
    void Warning(const string &in message, const string &in context = "") {
        Write(message, Level::Warning, -1, context);
    }
    void Error(const string &in message, const string &in context = "") {
        Write(message, Level::Error, -1, context);
    }
    void Critical(const string &in message, const string &in context = "") {
        Write(message, Level::Critical, -1, context);
    }
    void Custom(const string &in message, const string &in context = "") {
        Write(message, Level::Custom, -1, context);
    }

    void HandledException(
        const string &in context,
        const string &in detail,
        LogLevel level = LogLevel::Debug,
        int line = -1
    ) {
        string message = detail.Length > 0 ? "Handled exception: " + detail : "Handled exception";
        Entry entry(message, ToLevel(int(level)));
        entry.context = context;
        entry.sourceLine = line;
        entry.tag = "catch";
        entry.tagColor = kHandledExceptionTagColor;
        Write(entry);
    }

    void RenderSettingsUi(const string &in idPrefix = "logging") {
        bool writeFile = UI::Checkbox("Write daily diagnostic file##" + idPrefix, writeToFile);
        if (writeFile != writeToFile) {
            writeToFile = writeFile;
            if (writeFile) RetryFileOutput();
        }
        SetFilePath();
        UI::TextDisabled(filePath);
        if (UI::Button("Copy file path##" + idPrefix)) IO::SetClipboard(filePath);
        if (fileError.Length > 0) {
            UI::TextWrapped("File output: " + fileError);
            if (UI::Button("Retry file output##" + idPrefix)) RetryFileOutput();
        }
        UI::Separator();
        writeToOpenplanet = UI::Checkbox("Write to Openplanet log##" + idPrefix, writeToOpenplanet);
        UI::SetNextItemWidth(220.0f);
        minimumLevel = UI::SliderInt("Minimum standard level##" + idPrefix, Math::Clamp(minimumLevel, 0, 5), 0, 5);
        UI::TextDisabled("Current minimum: " + LevelName(minimumLevel));
        showCustom = UI::Checkbox("Show custom entries##" + idPrefix, showCustom);
        showContext = UI::Checkbox("Show context##" + idPrefix, showContext);
        showSourceLine = UI::Checkbox("Show source line##" + idPrefix, showSourceLine);
    }

    void RenderSettingsUI(const string &in idPrefix = "logging") {
        RenderSettingsUi(idPrefix);
    }

    vec4 NotificationColor(int level) {
        level = NormalizeLevel(level);
        if (level == 0) return vec4(.5, .5, .5, .3);
        if (level == 3) return vec4(1, .5, .1, .5);
        if (level == 4 || level == 5) return vec4(1, .2, .2, .3);
        return vec4(.2, .8, .5, .3);
    }

    void ShowNotification(int level, const string &in message, const string &in title = "", int durationMs = 6000) {
        string actualTitle = title.Length > 0 ? title : Meta::ExecutingPlugin().Name;
        UI::ShowNotification(actualTitle, message, NotificationColor(level), durationMs);
    }
}

void log(
    const string &in message,
    LogLevel level,
    int line = -1,
    const string &in functionName = ""
) {
    log::Write(message, log::ToLevel(int(level)), line, functionName);
}

void log(const string &in message, const string &in context = "", int level = 1) {
    log::Write(message, log::ToLevel(level), -1, context);
}

void log(const log::Entry@ entry) {
    log::Write(entry);
}

void NotifyDebug(const string &in message = "", const string &in title = "", int durationMs = 6000) {
    log::ShowNotification(0, message, title, durationMs);
}

void NotifyInfo(const string &in message = "", const string &in title = "", int durationMs = 6000) {
    log::ShowNotification(1, message, title, durationMs);
}

void NotifyNotice(const string &in message = "", const string &in title = "", int durationMs = 6000) {
    log::ShowNotification(2, message, title, durationMs);
}

void NotifyWarning(const string &in message = "", const string &in title = "", int durationMs = 6000) {
    log::ShowNotification(3, message, title, durationMs);
}

void NotifyError(const string &in message = "", const string &in title = "", int durationMs = 6000) {
    log::ShowNotification(4, message, title, durationMs);
}

void NotifyCritical(const string &in message = "", const string &in title = "", int durationMs = 6000) {
    log::ShowNotification(5, message, title, durationMs);
}
