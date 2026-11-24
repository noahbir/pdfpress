#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QTemporaryDir>
#include <QProcess>
#include <QFileInfo>
#include <QDir>
#include <QLocale>
#include <unistd.h>
#include <cerrno>

class Compressor : public QObject {
    Q_OBJECT
    QProcess worker;
    std::unique_ptr<QTemporaryDir> temp;
    QString source, result;
    qint64 originalSize = 0;
public:
    Compressor() {
        connect(&worker, &QProcess::finished, this, [this](int code, QProcess::ExitStatus status) {
            const qint64 size = QFileInfo(result).size();
            if (code || status != QProcess::NormalExit || size <= 0)
                return finish(tr("Could not compress this PDF. Check that it opens without a password and that the folder has free space."));
            if (size >= originalSize)
                return finish(tr("This PDF is already as small as this setting can make it. Try stronger compression."));
            QFileInfo input(source);
            QString stem = input.dir().filePath(input.completeBaseName() + "-compressed");
            for (int n = 1; ; ++n) {
                QString path = stem + (n == 1 ? QString() : "-" + QString::number(n)) + ".pdf";
                if (::link(QFile::encodeName(result), QFile::encodeName(path)) == 0)
                    return finish(tr("%1 → %2 (%3% smaller)\nSaved to %4").arg(QLocale().formattedDataSize(originalSize), QLocale().formattedDataSize(size)).arg(qRound(100.0 * (originalSize-size)/originalSize)).arg(path));
                if (errno != EEXIST) return finish(tr("Could not save the compressed copy in the original folder."));
            }
        });
        connect(&worker, &QProcess::errorOccurred, this, [this](QProcess::ProcessError e) {
            if (e == QProcess::FailedToStart) finish(tr("Ghostscript could not start."));
        });
    }
    ~Compressor() { worker.kill(); worker.waitForFinished(); }
    void finish(const QString &message) { temp.reset(); emit done(message); }
    Q_INVOKABLE void compress(QUrl url, int level) {
        if (temp) return;
        source = url.toLocalFile();
        QFile file(source);
        if (!file.open(QIODevice::ReadOnly) || !file.peek(1024).contains("%PDF-"))
            return finish(tr("Choose a readable PDF file."));
        originalSize = file.size();
        temp = std::make_unique<QTemporaryDir>(QFileInfo(source).dir().filePath(".pdfpress-XXXXXX"));
        if (!temp->isValid()) return finish(tr("The original folder must be writable."));
        result = temp->filePath("output.pdf");
        QString dpi = QString::number(level == 0 ? 200 : level == 1 ? 144 : 85);
        worker.setWorkingDirectory(temp->path());
        worker.setStandardOutputFile(QProcess::nullDevice());
        worker.setStandardErrorFile(QProcess::nullDevice());
        worker.start("gs", {"-dSAFER","-dBATCH","-dNOPAUSE","-sDEVICE=pdfwrite","-dPDFSETTINGS=/ebook",
            "-dColorImageResolution="+dpi,"-dGrayImageResolution="+dpi,"-sOutputFile=output.pdf","-f",source});
    }
signals:
    void done(QString message);
};
int main(int argc, char **argv) {
    QGuiApplication app(argc, argv);
    app.setDesktopFileName("pdfpress");
    QQuickStyle::setStyle("Material");
    Compressor compressor;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("compressor", &compressor);
    engine.load(QUrl("qrc:/Main.qml"));
    return engine.rootObjects().isEmpty() ? 1 : app.exec();
}
#include "main.moc"
