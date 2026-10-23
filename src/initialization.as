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
    return SBCC::App::HandleMouseButton(down, button, x, y);
}

void OnMouseMove(int x, int y) {
    SBCC::App::HandleMouseMove(x, y);
}
