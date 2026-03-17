# 🦥 SlothPix: AI-Powered Background Remover

SlothPix is a lightning-fast, offline, and completely free AI background remover for Windows. Built with **Rust**, it integrates deeply into the Windows operating system, allowing you to remove backgrounds from images directly via the right-click Context Menu.

## ✨ Features

- **🚀 Blazing Fast (GPU Acceleration):** Powered by **ONNX Runtime** and **DirectML**, SlothPix automatically utilizes your GPU (NVIDIA, AMD, or Intel) for instant inference. Falls back to CPU seamlessly if no compatible GPU is found.
- **🧵 Multi-threading:** Employs `rayon` to process bulk images simultaneously. Select 10 images, right-click, and watch them all process in parallel!
- **💻 Native Windows Experience:** 
  - **Context Menu Integration:** Right-click any `.jpg`, `.jpeg`, `.png`, or `.webp` file and select `SlothPix: Remove Background`.
  - **Native UI:** Beautiful native progress window during processing (using `native-windows-gui`).
  - **Toast Notifications:** Get notified via standard Windows 10/11 Toast notifications when the batch is done.
- **🧠 Advanced AI:** Uses the powerful RMBG-1.4 model (quantized for smaller size and faster inference).
- **📦 Clean Installer:** Packaged securely using **NSIS** for easy installation and uninstallation.

## 📥 Installation

1. Go to the [Releases](../../releases) page.
2. Download `SlothPix_Setup.exe`.
3. Run the installer (Administrator privileges required to register the Context Menu).
4. Right-click any image, select **"Show more options"** (on Windows 11) -> **SlothPix: Remove Background**.
5. The result will be saved in a new folder named `SlothPix_Result` right next to the original image!

## 🛠️ Build from Source

### Prerequisites
1. **Rust Toolchain:** Install from [rustup.rs](https://rustup.rs/).
2. **NSIS:** Required if you want to build the setup installer. Download from [nsis.sourceforge.io](https://nsis.sourceforge.io/).
3. **AI Model:** Download the ONNX model (e.g., RMBG-1.4) and place it in the `assets/` directory named exactly `model.onnx`.

### Build Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/SlothPix.git
   cd SlothPix
   ```

2. Build the Rust executable (Release mode is heavily recommended for AI inference speed):
   ```bash
   cargo build --release
   ```

3. Build the NSIS Installer (Optional):
   ```bash
   makensis slothpix.nsi
   ```
   *The installer will be generated as `SlothPix_Setup.exe` in the root directory.*

## 🏗️ Tech Stack

- **[Rust](https://www.rust-lang.org/):** Core logic and memory safety.
- **[ort](https://github.com/pykeio/ort):** Rust bindings for ONNX Runtime (DirectML support).
- **[image](https://github.com/image-rs/image):** Image processing and pixel manipulation.
- **[rayon](https://github.com/rayon-rs/rayon):** Data parallelism.
- **[native-windows-gui](https://github.com/gabdube/native-windows-gui):** Native Windows UI elements.
- **[NSIS](https://nsis.sourceforge.io/):** Windows installer creation.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

*Note: The AI models used with this software might have their own licenses (e.g., Bria AI RMBG-1.4 non-commercial license).*
