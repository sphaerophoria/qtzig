#include <QtCore/QObject>
#include <mutex>

// First, define your QObject which provides the functionality.
class SingletonTypeExample : public QObject
{
  Q_OBJECT
    Q_PROPERTY(int someProperty READ someProperty WRITE setSomeProperty NOTIFY somePropertyChanged)

  public:
    explicit SingletonTypeExample(QObject* parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE int doSomething()
    {
      setSomeProperty(5);
      return m_someProperty;
    }

    int someProperty() const {
      std::lock_guard<std::mutex> guard(m_mutex);
      return m_someProperty;
    }

    void setSomeProperty(int val) {
      {
        std::lock_guard<std::mutex> guard(m_mutex);
        if (m_someProperty != val) {
          m_someProperty = val;
        }
      }
      emit somePropertyChanged(val);
    }


public slots:
signals:
    void somePropertyChanged(int newValue);

  private:
    int m_someProperty = 0;
    mutable std::mutex m_mutex;
};

