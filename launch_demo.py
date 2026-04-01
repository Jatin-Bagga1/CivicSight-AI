import http.server
import socketserver
import subprocess
import os

PORT = 8080
PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))

# Path to the pre-built Windows executable
EXE_PATH = os.path.join(
    PROJECT_DIR, "build", "windows", "x64", "runner", "Release", "civicsight_ai.exe"
)
# Fallback: Debug build path
EXE_PATH_DEBUG = os.path.join(
    PROJECT_DIR, "build", "windows", "x64", "runner", "Debug", "civicsight_ai.exe"
)


class DemoHandler(http.server.SimpleHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200, "ok")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "X-Requested-With")
        self.end_headers()

    def do_POST(self):
        if self.path == "/launch-demo":
            print("\n>>> Received launch request from presentation!")
            self.send_response(200)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(b"Launching Flutter Demo...")

            # Try launching the pre-built exe first (instant launch)
            if os.path.exists(EXE_PATH):
                print(f">>> Launching Release build: {EXE_PATH}")
                subprocess.Popen([EXE_PATH], cwd=PROJECT_DIR)
            elif os.path.exists(EXE_PATH_DEBUG):
                print(f">>> Launching Debug build: {EXE_PATH_DEBUG}")
                subprocess.Popen([EXE_PATH_DEBUG], cwd=PROJECT_DIR)
            else:
                print(">>> No pre-built exe found. Falling back to 'flutter run'...")
                print(">>> TIP: Run 'flutter build windows' before your presentation!")
                subprocess.Popen("start cmd /c flutter run -d windows", shell=True, cwd=PROJECT_DIR)
        else:
            self.send_response(404)
            self.end_headers()


with socketserver.TCPServer(("", PORT), DemoHandler) as httpd:
    print(f"=== CivicSight AI Demo Launcher ===")
    print(f"Listening on port {PORT}...")
    print(f"Release exe: {'FOUND' if os.path.exists(EXE_PATH) else 'NOT FOUND'}")
    print(f"Debug exe:   {'FOUND' if os.path.exists(EXE_PATH_DEBUG) else 'NOT FOUND'}")
    if not os.path.exists(EXE_PATH) and not os.path.exists(EXE_PATH_DEBUG):
        print(f"\n!!! WARNING: No pre-built exe found.")
        print(f"!!! Run 'flutter build windows' first for instant launch.")
        print(f"!!! Without it, 'flutter run' will be used (slow).\n")
    print("Waiting for click from presentation...")
    httpd.serve_forever()
