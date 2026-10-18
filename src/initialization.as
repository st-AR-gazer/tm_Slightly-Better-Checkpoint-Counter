void Main() {
    SBCC::App::Main();
}

void Render() {
    SBCC::App::RenderCounter();
}

void RenderMenu() {
    SBCC::App::RenderMenu();
}

UI::InputBlocking OnMouseButton(bool down, int button, int x, int y) {
    return SBCC::App::HandleCounterMouseButton(down, button, x, y);
}

void OnMouseMove(int x, int y) {
    SBCC::App::HandleCounterMouseMove(x, y);
}
