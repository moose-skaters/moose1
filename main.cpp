#include <QWidget>
#include <QPushButton>
#include <QApplication>
#include <QLineEdit>
#include <QCompleter>
int main(int argc,char* argv[]){
    QApplication app(argc,argv);
    QWidget w;
    QLineEdit edit;
    edit.show();
    edit.setParent(&w);
    edit.setEchoMode(QLineEdit::PasswordEchoOnEdit);
    edit.setPlaceholderText("Please input textL");
    QCompleter completer;
    completer.
    edit.setCompleter();
    w.show();
    //QObject::connect(&button,SIGNAL(clicked()),&w,SLOT(close()));
    w.setWindowTitle("Hello World");
    return app.exec();
}
