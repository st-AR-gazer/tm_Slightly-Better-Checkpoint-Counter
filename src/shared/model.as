namespace SBCC {
    class CheckpointModel {
        dictionary markerGroups;
        dictionary linkedGroups;
        dictionary lapGates;
        array<bool> collectedGroups;
        uint total = 0;
        uint collected = 0;
        uint lap = 1;
        uint lapCount = 1;

        void Clear() {
            markerGroups.DeleteAll();
            linkedGroups.DeleteAll();
            lapGates.DeleteAll();
            collectedGroups.Resize(0);
            total = 0;
            collected = 0;
            lap = 1;
            lapCount = 1;
        }

        void AddCheckpoint(uint markerId, const string &in tag, uint order) {
            string key = tostring(markerId);
            if (markerGroups.Exists(key)) return;
            uint group;
            if (tag != "LinkedCheckpoint" || !linkedGroups.Get(tostring(order), group)) {
                group = total++;
                if (tag == "LinkedCheckpoint") linkedGroups.Set(tostring(order), group);
            }
            markerGroups.Set(key, group);
        }

        void BeginSample() {
            lap = 1;
            ResetCollected();
        }

        void ResetCollected() {
            collected = 0;
            collectedGroups.Resize(total);
            for (uint i = 0; i < total; i++) collectedGroups[i] = false;
        }

        void AddLapGate(uint markerId) {
            lapGates.Set(tostring(markerId), true);
        }

        void Visit(uint rawId) {
            string key = tostring(rawId | Offsets::landmarkIdMask);
            if (lapGates.Exists(key)) {
                if (collected == total && lap < lapCount) {
                    lap++;
                    ResetCollected();
                }
                return;
            }
            uint group;
            if (!markerGroups.Get(key, group)) return;
            if (!collectedGroups[group]) {
                collectedGroups[group] = true;
                collected++;
            }
        }

        uint get_remaining() const {
            return total - collected;
        }
    }
}
