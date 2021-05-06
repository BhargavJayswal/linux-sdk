#include <iostream>
#include <syslog.h>
using namespace std;

int main(int argc, char * argv[])
{
    cout << "Hello, World!" << endl;
    syslog(LOG_INFO, "example for C++ language");
}