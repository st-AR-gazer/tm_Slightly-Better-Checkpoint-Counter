namespace SBCC {
    namespace App {
        void Main() {
            counterFont = nvg::LoadFont("DroidSans.ttf");
            if (!Offsets::Initialize()) return;
            log("Loaded " + pluginMeta.Name + " v" + pluginMeta.Version, LogLevel::Info);
            while (true) {
                try {
                    Counter::Update();
                } catch {
                    Counter::Unavailable("Checkpoint data unavailable");
                    if (!Counter::readFailed) {
                        log("Checkpoint read failed: " + getExceptionInfo(), LogLevel::Warning);
                        Counter::readFailed = true;
                    }
                }
                sleep(100);
            }
        }

        void RenderMenu() {
            if (UI::MenuItem(MenuTitle(), "", showCounter)) {
                showCounter = !showCounter;
            }
        }
    }
}
