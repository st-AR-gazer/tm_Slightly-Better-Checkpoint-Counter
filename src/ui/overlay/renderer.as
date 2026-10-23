namespace SBCC {
    namespace App {
        int counterFont = -1;
        vec2 counterDrawPosition;
        vec2 counterSize;
        bool draggingCounter = false;
        vec2 counterDragOffset;

        void InitializeOverlay() {
            counterFont = nvg::LoadFont("DroidSans.ttf");
        }

        string MenuTitle() {
            return Icons::FlagCheckered + " " + pluginMeta.Name;
        }

        void RenderMenu() {
            if (UI::MenuItem(MenuTitle(), "", showCounter)) {
                showCounter = !showCounter;
            }
        }

        bool ShouldRender() {
            if (!showCounter ||
                !Counter::inRace ||
                counterFont < 0
            ) return false;
            if (hideWithGame && !UI::IsGameUIVisible()) return false;
            if (hideWithOp && !UI::IsOverlayShown()) return false;
            return true;
        }

        bool CanDrag() {
            return ShouldRender() && !lockPosition && UI::IsOverlayShown();
        }

        vec2 ClampPosition(const vec2 &in position, const vec2 &in size, const vec2 &in screenSize) {
            return vec2(
                Math::Clamp(position.x, 0.0f, Math::Max(0.0f, screenSize.x - size.x)),
                Math::Clamp(position.y, 0.0f, Math::Max(0.0f, screenSize.y - size.y))
            );
        }

        bool ContainsPoint(const vec2 &in position) {
            return position.x >= counterDrawPosition.x &&
                   position.y >= counterDrawPosition.y &&
                   position.x < counterDrawPosition.x + counterSize.x &&
                   position.y < counterDrawPosition.y + counterSize.y;
        }

        void RenderCounter() {
            if (!ShouldRender()) {
                draggingCounter = false;
                return;
            }
            vec2 screenSize = vec2(Display::GetWidth(), Display::GetHeight());
            if (screenSize.x <= 0 || screenSize.y <= 0) {
                draggingCounter = false;
                return;
            }
            if (!CanDrag() || !UI::IsMouseDown(UI::MouseButton::Left)) draggingCounter = false;

            nvg::Save();
            nvg::ResetTransform();
            nvg::FontFace(counterFont);
            float scale = screenSize.y / referenceHeight;
            nvg::FontSize(22 * scale);
            nvg::FontBlur(0);
            nvg::TextAlign(nvg::Align::Left | nvg::Align::Top);
            string counterText = "-- / -- (--)";
            if (Counter::ready) {
                counterText = Counter::model.collected +
                              " / " +
                              Counter::model.total +
                              " (" +
                              Counter::model.remaining +
                              ")";
                if (Counter::model.lapCount > 1) {
                    counterText += " | " + Counter::model.lap + " / " + Counter::model.lapCount;
                }
            }
            counterSize = nvg::TextBounds(counterText);
            vec2 position = GetPositionPx(screenSize.y);
            if (centerHorizontally) position.x = (screenSize.x - counterSize.x) * 0.5f;
            counterDrawPosition = ClampPosition(position, counterSize, screenSize);
            nvg::FillColor(vec4(0, 0, 0, counterColor.w));
            nvg::Text(counterDrawPosition + vec2(2, 2) * scale, counterText);
            nvg::FillColor(counterColor);
            nvg::Text(counterDrawPosition, counterText);
            nvg::Restore();
        }

        UI::InputBlocking HandleMouseButton(bool down, int button, int x, int y) {
            if (button != 0) return UI::InputBlocking::DoNothing;
            bool wasDragging = draggingCounter;
            draggingCounter = false;
            if (down &&
                CanDrag() &&
                ContainsPoint(vec2(x, y))
            ) {
                draggingCounter = true;
                counterDragOffset = vec2(x, y) - counterDrawPosition;
            }
            return draggingCounter || wasDragging ? UI::InputBlocking::Block : UI::InputBlocking::DoNothing;
        }

        void HandleMouseMove(int x, int y) {
            if (!draggingCounter || !CanDrag()) return;
            vec2 screenSize = vec2(Display::GetWidth(), Display::GetHeight());
            if (screenSize.x <= 0 || screenSize.y <= 0) return;
            vec2 position = ClampPosition(vec2(x, y) - counterDragOffset, counterSize, screenSize);
            SetPositionPx(position, screenSize.y);
        }
    }
}
