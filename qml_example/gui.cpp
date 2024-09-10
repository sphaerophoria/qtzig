
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include "app.h"
#include <chrono>
#include <thread>

SingletonTypeExample* example = nullptr;
extern "C" void incrementValue() {
   if (example) {
      example->setSomeProperty(example->someProperty() + 1);
   }
}

extern "C" int runGui()
{
    int argc = 1;
    char* argv[] = {"hello world"};

    QGuiApplication app(argc, argv);
    example = new SingletonTypeExample;

    QQmlApplicationEngine engine;
    qmlRegisterSingletonInstance("Qt.example.qobjectSingleton", 1, 0, "MyApi", example);
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    return app.exec();
}
