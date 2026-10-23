[SettingsTab name="General" icon="Cog" order=1]
void RenderGeneralSettingsTab() {
    SBCC::App::RenderSettings();
}

[SettingsTab name="Logging" icon="ListAlt" order=99]
void RenderLoggingSettingsTab() {
    log::RenderSettingsUI("sbcc-logging");
}
