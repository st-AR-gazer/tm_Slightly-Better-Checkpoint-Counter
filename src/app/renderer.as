namespace SBCC {
    namespace App {
        bool ShouldRenderCounter() {
            if (!showCounter ||
                !Counter::inRace ||
                counterFont < 0
            ) return false;
            if (hideWithGame && !UI::IsGameUIVisible()) return false;
            if (hideWithOp && !UI::IsOverlayShown()) return false;
            return true;
        }

        bool CanDragCounter() {
            return ShouldRenderCounter() && !lockPosition && UI::IsOverlayShown();
        }

        vec2 ClampCounterPosition(const vec2 &in position, const vec2 &in size, const vec2 &in screenSize) {
            return vec2(
                Math::Clamp(position.x, 0.0f, Math::Max(0.0f, screenSize.x - size.x)),
                Math::Clamp(position.y, 0.0f, Math::Max(0.0f, screenSize.y - size.y))
            );
        }

        bool CounterContains(const vec2 &in position) {
            return position.x >= counterDrawPosition.x &&
                   position.y >= counterDrawPosition.y &&
                   position.x < counterDrawPosition.x + counterSize.x &&
                   position.y < counterDrawPosition.y + counterSize.y;
        }

        void RenderCounter() {
            if (!ShouldRenderCounter()) {
                draggingCounter = false;
                return;
            }
            vec2 screenSize = vec2(Display::GetWidth(), Display::GetHeight());
            if (screenSize.x <= 0 || screenSize.y <= 0) {
                draggingCounter = false;
                return;
            }
            if (!CanDragCounter() || !UI::IsMouseDown(UI::MouseButton::Left)) draggingCounter = false;

            nvg::Save();
            nvg::ResetTransform();
            nvg::FontFace(counterFont);
            nvg::FontSize(22);
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
            counterDrawPosition = ClampCounterPosition(counterPosition, counterSize, screenSize);
            nvg::FillColor(vec4(1, 1, 1, 1));
            nvg::Text(counterDrawPosition, counterText);
            nvg::Restore();
        }

        UI::InputBlocking HandleCounterMouseButton(bool down, int button, int x, int y) {
            if (button != 0) return UI::InputBlocking::DoNothing;
            bool wasDragging = draggingCounter;
            draggingCounter = false;
            if (down &&
                CanDragCounter() &&
                CounterContains(vec2(x, y))
            ) {
                draggingCounter = true;
                counterDragOffset = vec2(x, y) - counterDrawPosition;
            }
            return draggingCounter || wasDragging ? UI::InputBlocking::Block : UI::InputBlocking::DoNothing;
        }

        void HandleCounterMouseMove(int x, int y) {
            if (!draggingCounter || !CanDragCounter()) return;
            counterPosition = ClampCounterPosition(
                vec2(x, y) - counterDragOffset,
                counterSize,
                vec2(Display::GetWidth(), Display::GetHeight())
            );
        }
    }
}
