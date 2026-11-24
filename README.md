# PDF Press

I used PDF Press on Linux to shrink large PDFs. It runs Ghostscript locally and saves a smaller copy beside the original by default. Click the underlined save location below **Compress PDF** to choose another folder.

## Build and run on Linux

Install Ghostscript, Qt 6.5 or newer with Qt Quick and Qt Quick Controls, qmake6, make, and a C++ compiler. From the project directory, run:

```sh
mkdir -p build
cd build
qmake6 ../pdfpress.pro
make
./pdfpress
```

Choose a PDF, select an image quality, and click **Compress PDF**. Balanced is a good starting point for scans. If the result is larger or the same size, PDF Press discards it.
