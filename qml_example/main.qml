import QtQuick 2.12
import QtQuick.Controls 2.12
import Qt.example.qobjectSingleton 1.0

ApplicationWindow {
    width: 540
    height: 960
    visible: true

    Text {
        text: "Hello world " + MyApi.someProperty
    }
}
