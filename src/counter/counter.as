namespace SBCC {
    namespace Counter {
        const uint maxCheckpointCount = 65536;
        const uint64 minBufferAddress = 0x10000;
        const uint64 maxBufferAddress = 0x00007FFFFFFFFFFF;
        const uint checkpointAlignment = 4;

        CheckpointModel model;
        CSmArena@ currentArena;
        CGameCtnChallenge@ currentMap;
        CGameCtnGhost@ currentRecording;
        int startTime = -1;
        bool waitingForNewRecording = false;
        uint landmarkCount = 0;
        bool inRace = false;
        bool ready = false;
        bool readFailed = false;
        string status = "Enter a race to show checkpoint progress.";

        void SetUnavailable(const string &in reason) {
            ready = false;
            status = reason;
            model.BeginSample();
        }

        void BuildMap(CSmArena@ arena, CGameCtnChallenge@ map) {
            model.Clear();
            @currentArena = arena;
            @currentMap = map;
            @currentRecording = null;
            startTime = -1;
            waitingForNewRecording = false;
            model.lapCount = map.TMObjective_IsLapRace ? Math::Max(uint(1), map.TMObjective_NbLaps) : 1;
            landmarkCount = arena.MapLandmarks.Length;
            for (uint i = 0; i < landmarkCount; i++) {
                auto landmark = arena.MapLandmarks[i];
                if (landmark is null || landmark.Waypoint is null) continue;
                if (landmark.Waypoint.IsMultiLap) {
                    model.AddLapGate(landmark.MarkerId.Value);
                    continue;
                }
                if (landmark.Waypoint.IsFinish) continue;
                model.AddCheckpoint(landmark.MarkerId.Value, landmark.Tag, landmark.Order);
            }
        }

        void Update() {
            inRace = false;
            auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
            if (playground is null ||
                playground.Arena is null ||
                playground.Map is null
            ) {
                @currentArena = null;
                @currentMap = null;
                @currentRecording = null;
                model.Clear();
                SetUnavailable("Enter a race to show checkpoint progress.");
                return;
            }
            if (playground.GameTerminals.Length == 0) return;
            auto terminal = playground.GameTerminals[0];
            if (terminal is null) return;
            auto player = cast<CSmPlayer>(terminal.ControlledPlayer);
            if (player is null || terminal.GUIPlayer !is player) {
                SetUnavailable("Waiting for the local player.");
                return;
            }
            auto script = cast<CSmScriptPlayer>(player.ScriptAPI);
            if (script is null) return;
            inRace = true;
            if (currentArena !is playground.Arena ||
                currentMap !is playground.Map ||
                landmarkCount != playground.Arena.MapLandmarks.Length
            ) {
                BuildMap(playground.Arena, playground.Map);
            }
            model.BeginSample();
            ready = false;
            status = "Waiting for checkpoint data...";

            if (script.StartTime < 0) {
                ready = true;
                status = "Counting the current lap.";
                return;
            }
            auto replay = cast<CGameCtnReplayRecord>(Dev::GetOffsetNod(playground.Arena, Offsets::arenaReplay));
            if (replay is null) return;
            CGameCtnGhost@ recording;
            for (int i = int(replay.Ghosts.Length) - 1; i >= 0; i--) {
                auto ghost = replay.Ghosts[i];
                if (ghost is null || ghost.GhostLogin != script.Login) continue;
                @recording = ghost;
                break;
            }
            if (recording is null) return;
            if (script.StartTime != startTime) {
                waitingForNewRecording = recording is currentRecording;
                startTime = script.StartTime;
            }
            uint count = Dev::GetOffsetUint32(recording, Offsets::ghostCheckpoints + Offsets::bufferLength);
            uint64 buffer = Dev::GetOffsetUint64(recording, Offsets::ghostCheckpoints);
            if (count > maxCheckpointCount ||
                (count > 0 &&
                 (buffer < minBufferAddress ||
                  buffer % checkpointAlignment != 0 ||
                  buffer > maxBufferAddress - uint64(count) * Offsets::checkpointStride))) {
                throw("Invalid checkpoint buffer");
            }
            if (waitingForNewRecording &&
                recording is currentRecording &&
                count > 0
            ) return;
            @currentRecording = recording;
            waitingForNewRecording = false;
            for (uint i = 0; i < count; i++) {
                nat2 checkpoint = Dev::ReadNat2(buffer + uint64(i) * Offsets::checkpointStride);
                model.Visit(checkpoint.x);
            }
            ready = true;
            readFailed = false;
            status = "Counting the current lap.";
        }
    }
}
