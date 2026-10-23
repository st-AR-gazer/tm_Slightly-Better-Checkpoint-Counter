namespace SBCC {
    Meta::Plugin@ pluginMeta = Meta::ExecutingPlugin();

    namespace App {
        void Main() {
            InitializeOverlay();
            Sound::Initialize();
            if (!Offsets::Initialize()) return;
            log(
                "Loaded " + pluginMeta.Name + " v" + pluginMeta.Version,
                LogLevel::Info,
                9,
                "SBCC::App::Main"
            );

            while (true) {
                try {
                    Counter::Update();
                } catch {
                    Counter::SetUnavailable("Checkpoint data unavailable");
                    if (!Counter::readFailed) {
                        log(
                            "Checkpoint read failed: " + getExceptionInfo(),
                            LogLevel::Warning,
                            17,
                            "SBCC::App::Main"
                        );
                        Counter::readFailed = true;
                    }
                }
                Sound::Update();
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
