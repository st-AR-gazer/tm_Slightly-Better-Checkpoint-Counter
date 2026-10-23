namespace SBCC {
    namespace App {
        const float referenceHeight = 1080.0f;

        vec2 GetPositionPx(float screenHeight) {
            return vec2(counterPosition.x, counterPosition.y * (screenHeight / referenceHeight));
        }

        void SetPositionPx(const vec2 &in position, float screenHeight) {
            if (screenHeight <= 0) return;
            if (!centerHorizontally) counterPosition.x = position.x;
            counterPosition.y = position.y * (referenceHeight / screenHeight);
        }

        void NudgeCounter(const vec2 &in direction) {
            if (lockPosition) return;
            vec2 screenSize = vec2(Display::GetWidth(), Display::GetHeight());
            if (screenSize.x <= 0 || screenSize.y <= 0) return;
            float step = Math::Clamp(nudgeStep, 1, 100);
            vec2 position = ClampPosition(GetPositionPx(screenSize.y), counterSize, screenSize);
            position = ClampPosition(position + direction * step, counterSize, screenSize);
            SetPositionPx(position, screenSize.y);
            draggingCounter = false;
        }

        void RenderNudgeSettings() {
            UI::BeginDisabled(lockPosition);
            UI::BeginDisabled(centerHorizontally);
            if (UI::Button(Icons::ArrowLeft + " Left")) NudgeCounter(vec2(-1, 0));
            UI::SameLine();
            if (UI::Button(Icons::ArrowRight + " Right")) NudgeCounter(vec2(1, 0));
            UI::EndDisabled();
            UI::SameLine();
            if (UI::Button(Icons::ArrowUp + " Up")) NudgeCounter(vec2(0, -1));
            UI::SameLine();
            if (UI::Button(Icons::ArrowDown + " Down")) NudgeCounter(vec2(0, 1));

            UI::EndDisabled();
            UI::SameLine();
            UI::SetNextItemWidth(100);
            nudgeStep = Math::Clamp(UI::InputInt("Step (px)", nudgeStep), 1, 100);
        }
    }
}
