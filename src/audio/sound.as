namespace SBCC {
    namespace Sound {
        class ProgressTracker {
            bool hasSample = false;
            uint previousProgress = 0;

            bool Observe(uint progress, bool sameRun) {
                bool newlyCollected = hasSample && sameRun && progress > previousProgress;
                previousProgress = progress;
                hasSample = true;
                return newlyCollected;
            }

            void Reset() {
                hasSample = false;
                previousProgress = 0;
            }
        }

        const int defaultChoice = 0;
        const int softChoice = 7;
        const int[] choices = {defaultChoice, softChoice};
        const string[] names = {"Checkpoint", "Soft"};
        Audio::Sample@ sample;
        ProgressTracker tracker;
        CGameCtnChallenge@ previousMap;
        CGameCtnGhost@ previousRecording;
        int previousStartTime = -1;
        string error;

        void Initialize() {
            @sample = null;
            error = "";
            if (choices.Find(App::checkpointSoundChoice) < 0) {
                App::checkpointSoundChoice = defaultChoice;
            }
            try {
                if (App::checkpointSoundChoice == softChoice) {
                    @sample = Audio::LoadSample("src/audio/soft.wav");
                } else {
                    auto checkpointFid = Fids::GetGame("GameData/Menu/Media/Audio/Sound/Wav/RaceCheckPoint.wav");
                    if (checkpointFid is null) throw("Native checkpoint sound was not found");
                    if (!Fids::Extract(checkpointFid)) throw("Could not extract the native checkpoint sound");
                    string samplePath = IO::FromDataFolder("Extract/" +
                                                           Fids::GetFullPath(checkpointFid) +
                                                           string(checkpointFid.FileName));
                    @sample = Audio::LoadSampleFromAbsolutePath(samplePath);
                }
                if (sample is null) throw("Could not load the selected checkpoint sound");
            } catch {
                @sample = null;
                error = "Checkpoint sound unavailable.";
                log(
                    error + " " + getExceptionInfo(),
                    LogLevel::Warning,
                    53,
                    "SBCC::Sound::Initialize"
                );
            }
        }

        void Play() {
            if (sample is null ||
                error.Length > 0 ||
                App::checkpointVolume <= 0
            ) return;
            try {
                Audio::Play(sample, Math::Clamp(App::checkpointVolume, 0, 100) / 100.0f);
            } catch {
                error = "Checkpoint sound could not be played.";
                log(
                    error + " " + getExceptionInfo(),
                    LogLevel::Warning,
                    68,
                    "SBCC::Sound::Play"
                );
            }
        }

        void Update() {
            if (!Counter::inRace || !Counter::ready) {
                tracker.Reset();
                @previousMap = null;
                @previousRecording = null;
                return;
            }
            bool sameRun = previousMap is Counter::currentMap &&
                           previousRecording is Counter::currentRecording &&
                           previousStartTime == Counter::startTime;
            @previousMap = Counter::currentMap;
            @previousRecording = Counter::currentRecording;
            previousStartTime = Counter::startTime;
            uint progress = (Counter::model.lap - 1) * Counter::model.total + Counter::model.collected;
            bool newlyCollected = tracker.Observe(progress, sameRun);
            if (newlyCollected && App::checkpointSound) Play();
        }
    }
}
