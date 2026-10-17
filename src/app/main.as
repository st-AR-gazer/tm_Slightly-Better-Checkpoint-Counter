namespace SBCC {
    namespace App {
        void Main() {
            if (!Offsets::Initialize()) return;
            log(pluginMeta.Name + ": core prototype loaded; counter display and controls are pending.", LogLevel::Info);
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
    }
}
