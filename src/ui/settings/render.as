namespace SBCC {
    namespace App {
        void RenderSettings() {
            showCounter = UI::Checkbox("Show counter", showCounter);
            if (UI::CollapsingHeader("Visibility")) {
                hideWithGame = UI::Checkbox("Hide with game UI", hideWithGame);
                hideWithOp = UI::Checkbox("Hide with Openplanet UI", hideWithOp);
            }
            UI::Separator();
            UI::Text("Position");
            lockPosition = UI::Checkbox("Lock position", lockPosition);
            UI::SameLine();
            centerHorizontally = UI::Checkbox("Center horizontally", centerHorizontally);
            vec2 screenSize = vec2(Display::GetWidth(), Display::GetHeight());
            vec2 savedPosition = GetPositionPx(screenSize.y);
            vec2 position = savedPosition;
            UI::BeginDisabled(centerHorizontally);
            UI::SetNextItemWidth(180);
            position.x = UI::InputFloat("X (px)", position.x, 1, 10, "%.1f");
            UI::EndDisabled();
            UI::SameLine();
            UI::SetNextItemWidth(180);
            position.y = UI::InputFloat("Y (px)", position.y, 1, 10, "%.1f");
            if (position != savedPosition) {
                SetPositionPx(ClampPosition(position, counterSize, screenSize), screenSize.y);
                draggingCounter = false;
            }
            RenderNudgeSettings();
            if (UI::Button("Reset position")) {
                counterPosition = defaultPosition;
                centerHorizontally = true;
                draggingCounter = false;
            }
            UI::Separator();
            UI::SetNextItemWidth(240);
            counterColor = UI::InputColor4("Text color", counterColor);
            UI::SameLine();
            if (UI::Button("Reset##counterColor")) counterColor = defaultColor;

            UI::Separator();
            checkpointSound = UI::Checkbox("Checkpoint sound", checkpointSound);
            if (checkpointSound) {
                int soundChoice = 0;
                for (uint i = 0; i < Sound::choices.Length; i++) {
                    if (Sound::choices[i] == checkpointSoundChoice) soundChoice = int(i);
                }
                UI::SetNextItemWidth(240);
                if (UI::BeginCombo("Sound", Sound::names[soundChoice])) {
                    for (uint i = 0; i < Sound::names.Length; i++) {
                        if (UI::Selectable(Sound::names[i], soundChoice == int(i))) soundChoice = int(i);
                    }
                    UI::EndCombo();
                }
                if (Sound::choices[soundChoice] != checkpointSoundChoice) {
                    checkpointSoundChoice = Sound::choices[soundChoice];
                    Sound::Initialize();
                }
                UI::SameLine();
                UI::BeginDisabled(Sound::sample is null || Sound::error.Length > 0 || checkpointVolume <= 0);
                if (UI::Button("Test sound")) Sound::Play();
                UI::EndDisabled();
                UI::SetNextItemWidth(180);
                checkpointVolume = UI::SliderInt("Volume", checkpointVolume, 0, 100, "%d%%");
                if (Sound::error.Length > 0) UI::TextWrapped(Sound::error);
            }
        }
    }
}
