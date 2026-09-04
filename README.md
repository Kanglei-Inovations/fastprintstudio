# FastPrint Studio

> **Smart printing & Xerox workflow software for fast, accurate, and professional print-shop operations.**

FastPrint Studio is a high-performance cross-platform Flutter application built desktop-first for **Windows PC printing, photo studios, and Xerox shops**.

The primary purpose of FastPrint Studio is to replace slow, repetitive, and error-prone Photoshop workflows with an instant, automated, and mathematically accurate printing suite.

Instead of manually launching Photoshop, rasterizing PDFs, cropping front and back card regions, rotating skewed camera captures, aligning on 4R photo paper, and manually calculating grid copies, FastPrint Studio automates the entire pipeline from file ingestion to physical print output.

---

## ✨ Vision

FastPrint Studio operates on one streamlined principle:

```text
Upload / Scan  ──▶  Adjust / Unskew  ──▶  Auto Layout (4R/A4)  ──▶  Live Preview  ──▶  Direct Print
```

A shop operator can complete common printing tasks in **under 5 seconds** with zero prior graphic design experience.

---

## 🖥️ Platform Support

| Platform | Tier | Status |
|---|---|---|
| 🪟 **Windows Desktop** | ⭐ **Primary Target** | Full Native Support (Direct Win32/GDI Spooler, Shortcuts, Drag & Drop) |
| 🌐 **Web** | Secondary | Supported |
| 🤖 **Android** | Secondary | Supported |
| 🍎 **iOS** | Secondary | Supported |
| 🐧 **Linux / macOS** | Secondary | Supported |

---

## 🧰 Core Workflows & Features

### 1. 🪪 Aadhaar & ID Card Printing
- **Automatic Document Detection**: Ingests e-Aadhaar PDFs, PAN card scans, Voter IDs (EPIC), and Driving Licenses. Automatically parses standard UIDAI 1-page/multi-page formats and segments front and back card regions.
- **4-Corner Quad Homography Warp**: Corrects angled or skewed smartphone photos of physical cards using 4-point projective perspective transformation and bilinear resampling into straight rectangular cards.
- **Physical Precision**: Standardizes cards to exact ISO ID-1 physical dimensions ($85.6 \times 54.0\text{ mm}$ or $86.0 \times 54.0\text{ mm}$) at 300 DPI.
- **Front + Back Alignment**: Arranges both sides on standard 4R ($101.6 \times 152.4\text{ mm}$) photo sheets in stacked or side-by-side configurations with adjustable cut/fold gaps.
- **One-Click Swap**: Instantly swap top/bottom order between Front and Back sides.
  Mode: rectangle
  Source Image Size: 2478 × 3507 px
  Source Pixel Crop: Rect.fromLTRB(162.5, 986.2, 1289.4, 1720.2)
  Quad Points: null
  Rotation: 0° | Fine: 0.0°
  ================================================
### 2. 👤 Passport & Mixed Photo Printing
- **`Passport` Mode (Default)**:
  - Automatically arranges **8 copies** of standard Indian Passport photos (**$30 \times 40\text{ mm}$**) on 4R landscape paper.
  - Zero spacing (`0.0 mm`) and zero margin (`0.0 mm`) for maximum edge-to-edge paper efficiency.
- **`Passport + Stamp` Mixed 4R Mode**:
  - Sets **6 Passport photos ($30 \times 40\text{ mm}$)** in a primary $3 \times 2$ grid.
  - Automatically calculates and auto-fills all remaining paper area with rotated **Stamp photos ($25 \times 30\text{ mm}$)** without sheet overflow.
- **Automated Face Framing**: Detects human faces and suggests optimal rule-of-thirds passport crops with headroom compensation.
- **Studio Border Pipeline**:
  $$\text{Photo (Center)} \longrightarrow \text{Outer White Margin (2.00 mm)} \longrightarrow \text{Cutting Stroke (0.15 mm)}$$
  Encloses photos in a crisp white border framed by an outer cutting hairline to guide physical scissors and rotary cutters.
- **Image Enhancements**: Real-time Brightness, Contrast, and Sharpness tuning with percentage feedback and instant reset.

### 3. 📄 Documents & Multi-Page Print
- Multi-page PDF queue with page range selection, scaling, and orientation correction.
- 1-up, 2-up, and 4-up imposition layouts on A4 paper for book and form duplication.

### 4. 🖨️ Direct Printing & Output
- **Native Direct Printing**: Sends print jobs directly to system default or selected printer spoolers (Epson L805, Canon G-series, HP DeskJet/LaserJet, Brother, etc.).
- **Vector / High-DPI PDF Export**: Generates exact 300 DPI CMYK/RGB print-ready PDF files for archiving or external print servers.
- **Persistent Print History**: Automatically records all completed print jobs with timestamp, service type, copy count, paper preset, and printer device info.
- **Live Printer Status**: Monitors connected printer status (Ready, Offline, Busy).

---

## 🔬 Mathematical & Architectural Highlights

### 4-Point Projective Homography (Perspective Unskewing)
To rectify an arbitrarily skewed 4-corner document quadrilateral $(x_0,y_0), (x_1,y_1), (x_2,y_2), (x_3,y_3)$ into a rectangular destination $[0, W-1] \times [0, H-1]$:
$$\begin{bmatrix} x' \\ y' \\ 1 \end{bmatrix} = \begin{bmatrix} a & b & c \\ d & e & f \\ g & h & 1 \end{bmatrix} \begin{bmatrix} u \\ v \\ 1 \end{bmatrix}$$
Every destination pixel $(u, v)$ is mapped to source coordinate $(\text{srcX}, \text{srcY})$ through the solved homography matrix coefficients and interpolated using **bilinear sub-pixel sampling**.

### Single Source of Truth Coordinate Pipeline
All cropping operations in `CropEditorModal` map viewport pixels back to **original image pixel coordinates** via `CoordinateConverter.screenToSourceRect` and `CoordinateConverter.sourceToScreenRect`, accounting for `BoxFit.contain` letterboxing, viewport scale factors, and orientation transformations.

---

## ⌨️ Desktop Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl + P` | Direct Print current layout |
| `Ctrl + S` | Export layout as PDF |
| `Ctrl + O` | Open image or PDF document |
| `Ctrl + Z` | Undo last edit / crop / setting change |
| `Ctrl + Shift + Z` / `Ctrl + Y` | Redo last undone action |
| `Ctrl + +` / `Ctrl + -` | Zoom In / Zoom Out on Print Preview Canvas |
| `Ctrl + 0` | Reset Canvas Zoom to 100% |
| `Esc` | Close Modal / Cancel Crop |

---

## 📁 Project Architecture

```text
fastprintstudio/
├── lib/
│   ├── core/
│   │   ├── constants/       # Standard Paper, Photo, and ID Card Presets
│   │   ├── models/          # QuadPoints, CropRectData, BorderConfig, PrintLayout, PhotoGroup
│   │   ├── theme/           # Desktop-first Typography, Color Palette, and Layout Tokens
│   │   └── utils/           # CoordinateConverter, UnitConverter (mm, in, px)
│   ├── features/
│   │   ├── history/         # Print History Log Screen
│   │   ├── id_card/         # Aadhaar / PAN / ID Card Processing Screen
│   │   ├── passport_photo/  # Passport, Stamp & Mixed 4R Photo Studio Screen
│   │   └── settings/        # Printer Configuration & Shop Preferences Screen
│   ├── providers/           # Riverpod State Notifiers (idCardProvider, passportPhotoProvider)
│   ├── services/
│   │   ├── detection/       # FaceDetector & DocumentDetector (Auto-Segmentation)
│   │   ├── image/           # ImageProcessor (Homography Warp, Rotate, Enhance, Border Pipeline)
│   │   ├── layout/          # LayoutEngine (2D Shelf, L-Shaped, and Multi-Region Packing)
│   │   ├── pdf/             # PdfRasterizer (300 DPI Multi-Page Render Engine)
│   │   └── printer/         # PrinterService (System Print Spooler & PDF Exporter)
│   ├── shared/
│   │   └── widgets/         # CropEditorModal, DropZoneWidget, PrintPreviewCanvas, DesktopScaffold
│   └── main.dart            # Application Entrypoint & Riverpod Scope
└── test/                    # Comprehensive Automated Unit, Widget & Pipeline Test Suite
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.7.0`)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.7.0`)
- Visual Studio 2022 (with "Desktop development with C++" workload installed for Windows builds)

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/fastprintstudio.git
   cd fastprintstudio
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on Windows Desktop (Debug Mode):**
   ```bash
   flutter run -d windows
   ```

4. **Build Windows Standalone Release Executable:**
   ```bash
   flutter build windows --release
   ```
   The compiled `.exe` bundle will be generated in `build/windows/x64/runner/Release/`.

---

## 🧪 Testing & Verification

Run the full automated test suite covering coordinate transformations, perspective warping, image processing, multi-photo packing, and widget integration:

```bash
flutter analyze
flutter test
```

---

## 📄 License

FastPrint Studio is proprietary software designed for printing, photo, and Xerox studio automation. All rights reserved.
