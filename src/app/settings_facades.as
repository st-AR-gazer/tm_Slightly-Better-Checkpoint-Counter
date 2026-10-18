namespace SBCC {
    namespace App {
        void RenderGeneralSettingsUI() {
            showCounter = UI::Checkbox("Show counter", showCounter);
            lockPosition = UI::Checkbox("Lock position", lockPosition);
            hideWithGame = UI::Checkbox("Hide with game UI", hideWithGame);
            hideWithOp = UI::Checkbox("Hide with Openplanet UI", hideWithOp);
            if (UI::Button("Reset counter position")) {
                counterPosition = vec2(30, 350);
                draggingCounter = false;
            }
            UI::TextWrapped("Counts collected and remaining checkpoints for the current lap. Linked alternatives count once. Starts and finishes are excluded.");
            UI::TextWrapped("Unlock the position and open the Openplanet overlay to drag the counter.");
            UI::Separator();
            UI::TextWrapped(Counter::status);
        }

        void RenderLoggingSettingsUI() {
            log::RenderSettingsUI("sbcc-logging");
        }
    }
}
